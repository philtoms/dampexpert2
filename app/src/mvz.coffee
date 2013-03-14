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

  bus=null
  routes = {}
  extensions = {} 
  
  base.all "*?*":->
    # auto register the route
    name = @params[0].split('/')[1]
    route = '/'+ name
    if not routes[route] then m = base.include route
    # model found but no controller so build one
    if typeof m is 'function'
      do (name) ->
        base.extend {controller:->
          @get ->
            view[name]=@model()
            @render view
        }, route
        view = {}
      
    @next()
   
  extensions['controller'] = ->
    ctx = this
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

    # all controllers are registered as route handlers
    routes[@route] = true

    # bring in the model
    mpath = path.join('models', @route)
    #@model = base.include mpath

  models = {}
  extensions['model'] = (_base) ->

    handlers={}
    mappings={}
    viewdata = {}
    init={}
    modelId = uuid.v4()
    
    @['on'] = (obj) ->      
      # switch to model context in handlers and reload state
      for k,h of obj
        handlers[k]=h
        obj[k]= (cdata) ->
          _publish=@publish
          id = cdata?.id || modelId
          model=models[id]
          if (not model)
            if cdata?.id? 
              throw "Model aggregate not found for id #{cdata.id}"
            model={id}
            mapViewData(init,model)
            models[id]=model
          model.publish=(obj,ack) ->
            for msg,data of obj
              data.id=model.id
              _publish.call model, obj,ack
              if base.enabled('automap events') and not handlers[msg]
                mapViewData(data,model)
            mapViewData(model,viewdata)
          mapViewData(viewdata,model)
          handlers[k].call model,cdata
          
      base['on'].call this, obj

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
        
    Object.defineProperty _base, 'viewmodel',
      configurable: true
      enumerable: true
      get:->
        if not Object.keys(viewdata).length then viewdata = init
        return viewdata
        
  extensions['viewmodel'] = (_base) ->
    ctx = this
    for verb in ['on']
      do(verb) ->
        ctx[verb] = (args...) ->
          base[verb].call ctx, args[0]
          
  @include = (name) ->
    if typeof name is 'object'
      for k,v of name
        ctx = @include v
        @extensions?[k]=ctx
        return
        
    sub = require path.join(root, name)
    if sub.extend
      @extend sub.extend, name
    if sub.include
      sub.include.apply(this, [this])
    return
    
  @extend = (obj,name) ->
    @extensions=@extensions||{}
    for k,v of obj 
      if (typeof v is 'object')
        return @extend v,k
      
      _super = @extensions[k] || extensions[k]
      if _super
        name = basename(name)
        ctx = constructor: (base) ->
          @route=''
          @name=name
          @app = base
          @[verb] = base[verb] for verb in ['include', 'extend']
          _super.apply this,[base]
          @route = [@route,name].join('/')
          v.call this
          return this

        @extensions[name]=ctx.constructor 
        new ctx.constructor this
      
  loadCQRS = ->
    if not bus and base.enabled 'cqrs'
      base.enable 'automap events'
      bus = require(base.app.get 'bus')
      require(base.app.get 'cqrs').call base, bus
      require(base.app.get 'eventsource').call base if base.enabled 'eventsource'
      
  # go
  startApp.call this,loadCQRS
    
module.exports = (port,app) -> 
  # wire-up mvz and the app into zappa context and start app when ready
  zappa.app -> 
    zapp = this
    mvz.call zapp, startApp = (loadCQRS) ->
      app.call zapp, startServer = ->
        loadCQRS()
        zapp.server.listen port || 3000
        zapp.log = zapp.log || ->
        zapp.log 'Express server listening on port %d in %s mode',
          zapp.server.address()?.port, zapp.app.settings.env
