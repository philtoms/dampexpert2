fs = require('fs')
path = require('path')
zappa = require('zappajs')

mvz = (ready) ->

  @version = '0.1.1'
  
  root = path.dirname(module.parent.filename)
  base = this
  base.app.set("views",path.join(root,"views"))
  
  routes = {}
  extensions = {} # app:base
  
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
          @ render view
        }, route
        view = {}
      
    @next()
   
  @registerRoutes = (r) ->
    for route in r
      @include r

  extensions['controller'] = (filepath,route) ->
    name = if filepath? then path.basename(filepath,'.coffee') else ''
    
    if route? && name then name='/'+name
    @route = @includepath = if route? then route+name else name

    # zappa verbs are default route enabled
    ctx = this
    ctx[verb] = base[verb] for verb in ['io', 'on', 'include', 'extend']
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
    if @route.indexOf('/')!=0 then @route='/'+@route
    routes[@route] = {controller:this.constructor,filepath:filepath}

    # bring in the model
    mpath = path.join('models', @includepath, name)
    #@model = base.include mpath
    return this
    
  extensions['model'] = (filepath,route) ->
    name = if filepath? then path.basename(filepath,'.coffee') else ''
    
    if route? && name then name='/'+name
    @route = @includepath = if route? then route+name else name

  @include = (name) ->
    if typeof name is 'object'
      for k,v of name
        @[k] = @include v
      return @[k]
      
    sub = require path.join(root, name)
    if sub.include
      if typeof sub.include is 'object'
        return @extend sub.include, name
      else
        return sub.include.apply(this, [this])

  @extend = (obj,includeName) ->
    if typeof obj is 'function' then obj = constructor:obj
    for k,v of obj 
      _super = @[k] || routes[k]?.controller || extensions[k]
      if _super
        ctx = new _super(includeName,@includepath)
      else
        # register new extension
        extensions[k] = v
        ctx = this
        
      _extension = v.call ctx
      return _extension
      
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
