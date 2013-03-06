fs = require('fs')
path = require('path')
zappa = require('zappajs')

mvz = (ready) ->

  @version = '0.1.2'
  
  root = path.dirname(module.parent.filename)
  base = this
  base.app.set("views",path.join(root,"views"))
  basename = (name) -> path.basename(path.basename(name || __filename,'.coffee'),'.js')

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
    
  Function::property = (prop, desc) ->
    Object.defineProperty this.prototype, prop, desc
   
  extensions['model'] = (_base) ->
    ctx = this
    bindings=_base?.bindings || {}
    @bind = (p) ->
      if typeof p isnt 'object' then p ={p:null}
      for k,v of p
        @[k]=bindings[k]=v

    Object.defineProperty _base, 'data',
      configurable: true
      enumerable: true
      get:->
        data={}
        for k,v of bindings
          if typeof v is 'function' then v=v()
          data[k]=v
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
  ready.apply this

  return this

module.exports = (port,app) -> 
  # wire-up mvz and the app into zappa context and start app when ready
  zappa.app -> 
    zapp = this
    mvz.call zapp, ready = ->
      app.call zapp, ready = ->
        zapp.server.listen port || 3000
        zapp.log = zapp.log || ->
        zapp.log 'Express server listening on port %d in %s mode',
          zapp.server.address()?.port, zapp.app.settings.env
