@include = viewmodel: (base, container) ->
  data=null
  Object.defineProperty this, 'viewmodel',
    configurable: true
    enumerable: true
    get:->
      return data || container.viewmodel || {}
    set:(value)->
      data = value

  for verb in ['on']
    do(verb) =>
      @[verb] = (args...) ->
        base[verb].call @, args[0]
