require './lib/mvz' 3001, (ready) ->

  @use logging:require ('winston'),
      'defultRouting',
      'memory-bus',
      'eventSourcing',
      'bodyParser',
      'static'
  
  ready()
