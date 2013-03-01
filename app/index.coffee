dampexpert2 = require './lib/mvz' 3001, (ready) ->

  @use logging:require ('winston')
      'defultRouting',
      'eventSourcing'
  
  ready()
  
module.exports = dampexpert2
