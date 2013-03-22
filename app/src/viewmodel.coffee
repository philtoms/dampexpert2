@include = viewmodel: (base) ->
  for verb in ['on']
    do(verb) =>
      @[verb] = (args...) ->
        base[verb].call @, args[0]
