fs = require('fs')
path = require('path')
zappa = require('zappajs')

mvz = (startApp) ->

  @version = '0.1.2'

  base = this
  
  root = path.dirname(module.parent.filename)
  #base.app.set("views",path.join(root,"views"))
  basename = (name) -> path.basename(path.basename(name || __filename,'.coffee'),'.js')

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
    extend = (obj, ctx, nestName) ->
      for name,ctor of obj

        if name == nestName
          return extend.call this, ctor, ctx, name
          
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
            return extend.call this, ctor, ctx, name
          ctor.apply ctx
          return ctx
            
        ctx = constructor: (container) ->
          @name = name
          @app = base.app
          @[verb] = base[verb] for verb in ['include', 'extend']
          ioc.call this,base for k,ioc of iocContainer
          if extension
            extension.apply this, [base,container]
          if typeof ctor is 'object'
            return extend.call container, ctor, this, name
          ctor.apply this
          return this
          
        extensions[name]=ctx.constructor if not extensions[name]
        return new ctx.constructor this

    onload =>
      extend.call this, obj
      
    return

  onload = (fn) ->
    loadQ.push fn
    
  base.include './controller'
  base.include './viewmodel'
  base.include './model'
  base.include './eventsource'
  base.include './log'
  
  @app.enable 'automap events'
  
  @app.set cqrs:'./ws-cqrs'
  @app.set bus:'./memory-bus'
  @app.set 'model-store':'./memory-store'

  ready = (port) ->
  
    loadQ.shift()()
    iocContainer.log.apply base, [base]
    
    if @enabled 'cqrs' 
      bus = require(@get 'bus')
      require(@get 'cqrs').call base, bus
      bus.log = base.log
      
    while fn = loadQ.shift()
      fn()
    onload = (fn) -> fn()

    @server.listen port || 3000
    base.log.info 'Express server listening on port %d in %s mode',
      @server.address()?.port, @settings.env
      
  startApp.apply this, [ready]
    
module.exports = (port,app) -> 
  # wire-up mvz and the app into zappa context and start app when ready
  zappa.app -> 
    zapp = this
    mvz.call zapp, startApp = (ready) ->
      app.call zapp, startServer = ->
        ready.call zapp.app, port
