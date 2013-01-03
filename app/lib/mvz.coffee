fs = require "fs"
path = require "path"
zappa = require ('zappa')

mvz = ->

  @version = '0.1.1'
  
  base=this
  controllers = {}
  extensions = app:zappa
  
  @registerRoutes = (r) ->
    for route in r
      countrollers[route] = @include r
  
  @controller = (filepath,route) ->
    name = if filepath? then path.basename(filepath,'.coffee') else ''
    
    # all controllers are registered 
    if name? then controllers[name] = this
    
    if route? && name then name='/'+name
    @route = @includepath = if route? then route+name else name
    
    # zappa verbs are default route enabled
    ctrlr= this
    for verb in ['get', 'post', 'put', 'del']
      do(verb) ->
        ctrlr[verb] = ->
          if arguments.length == 1
            zappa[verb] @route, arguments[0]
          else
            zappa[verb] arguments[0], arguments[1]
    return this
    
  @include = extensions['include'] = (p) ->
    sub = require path.join(zappa.root, p)
    if sub.extend
      return @extend sub.extend, p
    sub.include.apply(zappa, [zappa])

  @extend = extensions['extend'] = (obj,include) ->
    if typeof obj is 'function' then obj = constructor:obj
    for k,v of obj 
      _super = @[k] || controllers[k] || extensions[k]
      if _super
        extension = v.call new _super(include,@includepath)
        # load all of the extension methods into the new extension
        for e,m of extensions
          extension[e] = m
        return extension

      # register new extension
      extensions[k] = v
      
  # new mvz instance
  return this

module.exports = -> 

  host = null
  port = 3000
  root_function = null
  for a in arguments
    switch typeof a
      when 'string'
        if isNaN( (Number) a ) then host = a
        else port = (Number) a
      when 'number' then port = a
      when 'function' then root_function = a

  zappa = zappa.app()
  app = zappa.app
  
  if host then app.listen port, host
  else app.listen port

  log = @logger || zappa.log || ->

  log 'Express server listening on port %d in %s mode',
    app.address()?.port, app.settings.env

  # go
  root_function.call new mvz
