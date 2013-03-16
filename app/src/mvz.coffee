fs = require('fs')
path = require('path')
uuid = require('node-uuid')
zappa = require('zappajs')

mvz = (startApp) ->

  @version = '0.1.2'

  base = this
  
  root = path.dirname(module.parent.filename)
  #base.app.set("views",path.join(root,"views"))
  basename = (name) -> path.basename(path.basename(name || __filename,'.coffee'),'.js')

  @app.set bus:'./memory-bus'
  @app.set cqrs:'./ws-cqrs'
  @app.set eventsource:'./eventsource'
  @app.set 'model-store':'./memory-store'

  bus=null
  models=null
  extensions = {} 
  
  extensions['controller'] = (_super) ->
    ctx = this
    @route = [_super.route,@name].join('/')
    # zappa verbs are default route enabled
    for verb in ['get', 'post', 'put', 'del']
      do(verb) ->
        ctx[verb] = (args...) ->
          base.log "registering " + @route
          if args.length == 1
            r = args[0]
            if typeof r isnt 'object' then r = {'':args[0]}
            for subroute,handler of r
              base[verb] @route + subroute, handler
          else
            base[verb] @route+args[0], args[1]

    # bring in the model
    mpath = path.join('models', @route)
    #@model = base.include mpath

  _publish=null
  extensions['model'] = (_super) ->

    handlers={}
    mappings={}
    viewdata = {}
    init={}
    modelId = uuid.v4()
    
    @['on'] = (obj) ->
      ctx=this
      onCQRSload ->
        for k,h of obj
          handlers[k]=h
          obj[k]= (cdata, errh) ->
            _publish=_publish || ctx.publish
            id = cdata?.id || modelId
            models.load id, (err,model) ->
              if (not model)
                if cdata?.id?
                  errh? "Model aggregate not found for id #{cdata.id}"
                  return
                model={id}
                mapViewData(init,model)
                
              model.publish=(obj,ack) ->
                for msg,data of obj
                  data.id=model.id # no nonsense
                  _publish.call model, obj,ack
                  if base.enabled('automap events') and not handlers[msg]
                    mapViewData(data,model)
                models.store model
                mapViewData(model,viewdata)
                
              # switch to model context in handlers
              mapViewData(viewdata,model)
              handlers[k].call model,cdata
            
        base['on'].call ctx, obj

    # build a mapper
    @map = (p) ->
      if typeof p isnt 'object' 
        mappings[p]=true
        init[p]=null
      else for k,v of p
        if typeof v is 'function' 
          mappings[k]=v
          v=v(null,false)
        else
          mappings[k]=true
        init[k]=v

    mapViewData = (src,dest)->
      if src.load is 'function'
        src = src.load(id)
      for k,m of mappings
        if src[k] isnt undefined
          if typeof m isnt 'function'
            dest[k] = src[k] 
          else
            dest[k] = m(src[k],dest==viewdata)
      # decouple
      if dest==viewdata 
        viewdata = JSON.parse(JSON.stringify(viewdata))
        
    Object.defineProperty _super, 'viewmodel',
      configurable: true
      enumerable: true
      get:->
        if not Object.keys(viewdata).length then viewdata = init
        return viewdata
        
  extensions['viewmodel'] = (_super) ->
    ctx = this
    for verb in ['on']
      do(verb) ->
        ctx[verb] = (args...) ->
          base[verb].call ctx, args[0]
          
  extensions['inject'] = (_super) ->
  
  @include = (name, regname) ->
    if typeof name is 'object'
      for k,v of name
        return @include v,k
        
    sub = require path.join(root, name)
    if sub.extend
      @extend sub.extend, regname || name
    if sub.include
      sub.include.apply(this, [this])
    return

  @extend = (obj,name) ->
    for k,v of obj 
      if (typeof v is 'object')
        return @extend v,k

      extend = extensions[k]
      if extend
        name = basename(name)
        ctx = constructor: (_super) ->
          @log = base.log
          @name=name
          @app = base
          @[verb] = base[verb] for verb in ['include', 'extend']
          extend.apply this,[_super]
          v.call this

        extensions[name]=ctx.constructor 
        new ctx.constructor this
        return
        
  onLoad = []
  loadCQRS = ->
    if not bus and base.enabled 'cqrs' 
      base.enable 'automap events'
      bus = require(base.app.get 'bus')
      models = require(base.app.get 'model-store')
      require(base.app.get 'cqrs').call base, bus
      require(base.app.get 'eventsource').call base if base.enabled 'eventsource'
      bus.log = models.log = base.log
    go() for go in onLoad
      
  onCQRSload = (go) ->
      if bus or not base.enabled 'cqrs' then go()
      onLoad.push go
    
  # go
  startApp.call this,loadCQRS
    
module.exports = (port,app) -> 
  # wire-up mvz and the app into zappa context and start app when ready
  zappa.app -> 
    zapp = this
    zapp.log = ->
    mvz.call zapp, startApp = (loadCQRS) ->
      app.call zapp, startServer = ->
        zapp.server.listen port || 3000
        zapp.log = zapp.log || ->
        loadCQRS()
        zapp.log 'Express server listening on port %d in %s mode',
          zapp.server.address()?.port, zapp.app.settings.env
