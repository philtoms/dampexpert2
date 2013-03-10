require './lib/mvz' 3001, (ready) ->

  @include logging:'winston'
  
  @set bus:'./memory-bus',
       cqrs:'./ws-cqrs',
       eventstore:'./nstore-events'
       readstore:'./nstore-query'
       
  @enable 'eventSourcing'
  
  ready()
