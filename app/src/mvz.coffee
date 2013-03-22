fs = require('fs')
path = require('path')
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
  extensions = {} 
  iocContainer = {}
  loadQ = []
  
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
        if typeof sub.include is 'object'
          for k,v of sub.include
            extensions[k]=v
          return
        sub.include.apply this
    return

  @extend = (obj) ->
    extend = (obj, ctx) ->
      for name,ctor of obj
        if name is 'inject'
          iocContainer[ctx?.name || 'ioc'+iocContainer.length] = ctor
          return ctx
          
        extension = extensions[name]
        if ctx
          if extension
            extension.apply ctx, [base,this]
          else
            ctx.name = name
          if typeof ctor is 'object'
            return extend.call this, ctor, ctx
          ctor.apply ctx
          return ctx
            
        ctx = constructor: (_super) ->
          @name = name
          @app = base
          @[verb] = base[verb] for verb in ['include', 'extend']
          ioc.call this,base for k,ioc of iocContainer
          if extension
            extension.apply this, [base,_super]
          if typeof ctor is 'object'
            return extend.call _super, ctor, this
          ctor.apply this
          return this
          
        extensions[name]=ctx.constructor if not extensions[name]
        return new ctx.constructor this

    onload =>
      extend.call this, obj
      
    return

  if base.enabled 'cqrs' 
    base.enable 'automap events'

  ready = (port) ->

    base.include './controller'
    base.include './viewmodel'
    base.include './model'

    base.include './log'
    loadQ.pop()()
    iocContainer.log.apply base, [base]
    
    if base.enabled 'cqrs' 
      bus = require(@get 'bus')
      require(@get 'cqrs').call base, bus
      require(@get 'eventsource').call base if base.enabled 'eventsource'
      bus.log = base.log
    fn() for fn in loadQ
    @server.listen port || 3000
    base.log.info 'Express server listening on port %d in %s mode',
      @server.address()?.port, @settings.env
      
  onload = (fn) ->
    if bus or not base.enabled 'cqrs' then fn()
    loadQ.push fn
    
  startApp.apply this, [ready]
    
module.exports = (port,app) -> 
  # wire-up mvz and the app into zappa context and start app when ready
  zappa.app -> 
    zapp = this
    mvz.call zapp, startApp = (ready) ->
      app.call zapp, startServer = ->
        ready.call zapp.app, port
