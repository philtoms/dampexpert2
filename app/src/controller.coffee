path = require('path')

@include = controller: (base,_super) ->
  @viewmodel = {}
  @route = [_super.route,@name].join('/')
  # zappa verbs are default route enabled
  for verb in ['get', 'post', 'put', 'del']
    do(verb) =>
      @[verb] = (args...) ->
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

