fs = require('fs')
path = require('path')
zappa = require('zappajs')

mvz = (start) ->

  @version = '0.1.2'
  
  root = path.dirname(module.parent.filename)
  base = this
  base.app.set("views",path.join(root,"views"))
  basename = (name) -> path.basename(path.basename(name || __filename,'.coffee'),'.js')

  bus = './memory-bus'
  cqrs = './ws-cqrs'
  eventsource = './eventsource'
  #automap = true
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

  _publish=null
  extensions['model'] = (_base) ->
    ctx = this
    for verb in ['on']
      do(verb) ->
        ctx[verb] = (args...) ->
          if not _publish
            _publish = bus.publishEvent
            bus.publishEvent=(msg,data,ack) ->
              for k,v of data
                if mappings[k]?.model
                  ctx[k]=mappings[k].model v
                else if automap?
                  ctx[k]=v
              _publish msg,data,ack
          base[verb].call ctx, args[0]
          
    bindings={}
    mappings={}
    @map = {model:(v)->v}
    @bind = (p,map) ->
      if typeof p isnt 'object' then p ={p:null}
      for k,v of p
        @[k]=bindings[k]=v
        mappings[k]=
          data:map?.data || (v)->v
          model:map?.model

    Object.defineProperty _base, 'data',
      configurable: true
      enumerable: true
      get:->
        data={}
        for k,v of bindings
          if typeof v is 'function' then v=v()
          data[k] = mappings[k].data(v)
        return data

  @include = (name) ->
    if typeof name is 'object'
      for k,v of name
        ctx = @include v
        @extensions?[k]=ctx
        return
        
    sub = require path.join(root, name)
    if sub.include
      if typeof sub.include is 'object'
        @extend sub.include, name
      else
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
      
  # go
  start.apply this

  return ->
    bus = require(bus)
    require(cqrs).call this, bus
    require(eventsource).call this if eventsource
    
module.exports = (port,app) -> 
  # wire-up mvz and the app into zappa context and start app when ready
  zappa.app -> 
    zapp = this
    (mvz.call zapp, start = ->
      app.call zapp, start = ->
        zapp.server.listen port || 3000
        zapp.log = zapp.log || ->
        zapp.log 'Express server listening on port %d in %s mode',
          zapp.server.address()?.port, zapp.app.settings.env).call zapp
