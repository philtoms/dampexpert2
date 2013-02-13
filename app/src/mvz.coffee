fs = require('fs')
path = require('path')
zappa = require('zappajs')

mvz = (ready) ->

  @version = '0.1.1'
  
  root = path.dirname(module.parent.filename)
  base = this
  base.app.set("views",path.join(root,"views"))
  routes = {}
  extensions = app:base
  
  base.all "*?*":->
    # auto register the route
    name = @params[0].split('/')[1]
    route = '/'+ name
    if not routes[route] then m = base.include route
    # model found but no controller so build one
    if typeof m is 'function'
      do (name) ->
        ctrlr = base.extend {controller:->return this}, route
        view = {}
        ctrlr.get ->
          view[name]=ctrlr.model()
          @render view
      
    @next()
   
  @registerRoutes = (r) ->
    for route in r
      @include r

  extensions['controller'] = (filepath,route) ->
    name = if filepath? then path.basename(filepath,'.coffee') else ''
    
    if route? && name then name='/'+name
    @route = @includepath = if route? then route+name else name

    # zappa verbs are default route enabled
    ctrlr = this
    for verb in ['get', 'post', 'put', 'del']
      do(verb) ->
        ctrlr[verb] = (args...) ->
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
    @model = base.include @includepath, ["models"]
    return this
    
  extensions['model'] = (filepath,route) ->
    name = if filepath? then path.basename(filepath,'.coffee') else ''
    
    if route? && name then name='/'+name
    @route = @includepath = if route? then route+name else name
    
    

  @include = extensions['include'] = (p,folders) ->
    for folder in folders || ['','controllers','models']
      try
        sub = require path.join(root, folder, p)
        if sub.extend
          return @extend sub.extend, p
        if sub.include
          sub.include.apply(base, [base])
        return sub
      catch ex
        base.log ex

  @extend = extensions['extend'] = (obj,include) ->
    if typeof obj is 'function' then obj = constructor:obj
    for k,v of obj 
      _super = @[k] || routes[k]?.controller || extensions[k]
      if _super
        extension = v.call new _super(include,@includepath)
        if typeof extension isnt 'object'
          throw "extension of #{k} must return object"
          
        # load all of the extension methods into the new extension
        for e,m of extensions
          extension[e] = m
        return extension

      # register new extension
      extensions[k] = v
      
      # special case?
      if k=='log' then @[k]=v
      
  # go
  ready.call this

  return this

module.exports = (port,app) -> 
  # wire-up mvz and the app into zappa context and start app when ready
  zappa.app -> 
    zapp = this
    mvz.call zapp,->
      app.call zapp, ->
        zapp.server.listen port || 3000
        zapp.log = zapp.log || console.log
        zapp.log 'Express server listening on port %d in %s mode',
          zapp.server.address()?.port, zapp.app.settings.env
