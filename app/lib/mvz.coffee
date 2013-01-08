fs = require "fs"
path = require "path"
zappa = require ('zappajs')

mvz = ->

  @version = '0.1.1'
  
  base = this
  root = path.dirname(module.parent.filename)
  controllers = {}
  extensions = app:base
  
  @registerRoutes = (r) ->
    for route in r
      countrollers[route] = @include r
  
  @controller = extensions['controller'] = (filepath,route) ->
    name = if filepath? then path.basename(filepath,'.coffee') else ''
    
    # all controllers are registered 
    if name? then ctrlr = controllers[name] = this
    
    if route? && name then name='/'+name
    @route = @includepath = if route? then route+name else name
    
    # zappa verbs are default route enabled
    for verb in ['get', 'post', 'put', 'del']
      do(verb) ->
        ctrlr[verb] = ->
          if arguments.length == 1
            base[verb] @route, arguments[0]
          else
            base[verb] arguments[0], arguments[1]
    return this
    
  @include = extensions['include'] = (p) ->
    sub = require path.join(root, p)
    if sub.extend
      return @extend sub.extend, p
    sub.include.apply(base, [base])

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
      
  # go
  mvz.app.call(this)

  return this

module.exports = (port,app) -> 
  mvz.app = app
  zappa.run port, mvz
