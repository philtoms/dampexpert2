uuid = require('node-uuid')
exchange = {}
queue = []

pump = -> 
  if queue.length
    msg = queue.shift()
    for subscriber in exchange[msg.name] 
      console.log "publishing #{msg.name} to handler #{subscriber.id}" 
      subscriber.handle,msg.data
      process.nextTick(pump)

module.exports = 
  publish: (msg,data,ack) -> 
    queue.push {name:msg,data:data}
    ack?() # message received
    pump()
    
  subscribe: (msg,handler) -> 
    subscriber = {id:uuid.v4(),handle:handler}
    if not exchange[msg] then exchange[msg] = [subscriber] else exchange[msg].push subscriber
    console.log "handler #{subscriber.id} subscribing to #{msg}" 