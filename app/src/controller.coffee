path = require('path')
fs = require('fs')

@include = controller: (base,container) ->

  @viewmodel = {}  
  @route = [container.route,@name].join('/')

  # zappa verbs are default route enabled
  for verb in ['get', 'post', 'put', 'del']
    do(verb) =>
      @[verb] = (args...) ->
        base.log.debug "registering route" + @route
        if args.length == 1
          r = args[0]
          if typeof r isnt 'object' then r = {'':args[0]}
          for subroute,handler of r
            base[verb] @route + subroute, handler
        else
          base[verb] @route+args[0], args[1]

  # load extensions by convention - including override order
  for ext in ['models','viewmodels']
    extHandler = {};
    extPath = path.join("../#{ext}", @route)
    extHandler[@route]=extPath
    if fs.existsSync extPath
      @include extHandler