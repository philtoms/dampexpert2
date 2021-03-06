uuid = require('node-uuid')
MBus = ->
  exchange = {}
  queue = []

  pump = -> 
    if queue.length
      msg = queue.shift()
      if exchange[msg.name]?
        for subscriber in exchange[msg.name] 
          bus.log.debug "publishing #{msg.name} to handler #{subscriber.id}" 
          subscriber.handle msg.data,msg.err
      process.nextTick(pump)

  bus =
    publishCommand: (msg,data,ack,err) -> 
      queue.push {name:msg,data,err}
      ack?() # message received
      pump()
      
    publishEvent: (msg,data,ack,err) -> 
      queue.push {name:msg,data,err}
      ack?() # message received
      process.nextTick(pump)
      
    subscribe: (msg,handler) -> 
      subscriber = {id:uuid.v4(),handle:handler}
      if not exchange[msg] then exchange[msg] = [subscriber] else exchange[msg].push subscriber
      bus.log.debug "handler #{subscriber.id} subscribing to #{msg}" 
      
    reset: -> 
      queue = []
      exchange = {}
      
module.exports = new MBus
