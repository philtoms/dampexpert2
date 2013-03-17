fs = require('fs')
path = require('path')
uuid = require('node-uuid')
zappa = require('zappajs')

mvz = (startApp) ->

  @version = '0.1.2'

  base = this
  
  # default all logs to console
  @log = logger = (m) -> console.log m
  loglevel=2
  loglevels = {'debug':0,'info':1,'warn':2,'error':3}
  for k,v of loglevels 
    do (k,v) ->
      logger[k] = (m) -> logger m if v>=loglevel
    
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
  iocContainer = []
  loadQ = []
  
  extensions['controller'] = (_super) ->
    ctx = this
    @route = [_super.route,@name].join('/')
    # zappa verbs are default route enabled
    for verb in ['get', 'post', 'put', 'del']
      do(verb) ->
        ctx[verb] = (args...) ->
          base.log.debug "registering " + @route
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
      onload ->
        for k,h of obj
          handlers[k]=h
          obj[k]= (cdata, errh) ->
            _publish=_publish || ctx.publish
            id = cdata?.id || modelId
            models.load id, (err,model) ->
              if (err or not model)
                if cdata?.id?
                  base.log.error "Model aggregate not found for id #{cdata.id}"
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
   
  @include = (name) ->
    obj = name
    if typeof obj isnt 'object'
      obj = {}
      obj[basename(name)]=name
    for k,v of obj
      sub = require path.join(root, v)
      if sub.extend
        obj[k]=sub.extend
        @extend obj
      if sub.include
        sub.include.apply this
    return

  @extend = (obj) ->
    extend = (obj, ctx) ->
      for name,ctor of obj
        if name is 'inject'
          iocContainer.push ctor
          return ctx
          
        extension = extensions[name]
        if ctx
          if extension
            extension.call ctx, this
          else
            ctx.name = name
          if typeof ctor is 'object'
            return extend.call this, ctor, ctx
          ctor.call ctx
          return ctx
            
        ctx = constructor: (_super) ->
          @log = base.log
          @name=name
          @app = base
          @[verb] = base[verb] for verb in ['include', 'extend']
          if extension
            extension.call this,_super,ctor
          if typeof ctor is 'object'
            return extend.call _super, ctor, this
          ioc.call this for ioc in iocContainer
          ctor.call this
          return this
          
        extensions[name]=ctx.constructor if not extensions[name]
        return new ctx.constructor this
        
    extend.call this, obj
    return

  ready = (port) ->
    loglevel = loglevels[@get 'loglevel'] || loglevel
    if not bus and base.enabled 'cqrs' 
      base.enable 'automap events'
      bus = require(@get 'bus')
      models = require(@get 'model-store')
      require(@get 'cqrs').call base, bus
      require(@get 'eventsource').call base if base.enabled 'eventsource'
      bus.log = models.log = base.log
    fn() for fn in loadQ
    @server.listen port || 3000
    logger.info 'Express server listening on port %d in %s mode',
      @server.address()?.port, @settings.env
      
  onload = (fn) ->
    if bus or not base.enabled 'cqrs' then fn()
    loadQ.push fn
    
  startApp.call this,ready
    
module.exports = (port,app) -> 
  # wire-up mvz and the app into zappa context and start app when ready
  zappa.app -> 
    zapp = this
    mvz.call zapp, startApp = (ready) ->
      app.call zapp, startServer = ->
        ready.call zapp.app, port
