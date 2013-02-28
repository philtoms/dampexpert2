uuid = require('node-uuid')
exchange = {}

module.exports = 
  publish: (msg,data,ack) -> 
    ack?() # message received
    pump = ->
      for subscriber in exchange[msg] 
        console.log "publishing #{msg} to handler #{subscriber.id}" 
        subscriber.handle,data
        process.nextTick(pump)
    
  subscribe: (msg,handler) -> 
    subscriber = {id:uuid.v4(),handle:handler}
    if not exchange[msg] then exchange[msg] = [subscriber] else exchange[msg].push subscriber
    console.log "handler #{subscriber.id} subscribing to #{msg}" 