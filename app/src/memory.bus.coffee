uuid = require('node-uuid')
exchange = {}

module.exports = 
  publish: (msg,data,ctx,ack) -> 
    ack?()
    for wrapper in exchange[msg] 
      console.log "publishing #{msg} to handler #{wrapper.id}" 
      ctx wrapper.handler,data
    
  subscribe: (msg,handler) -> 
    wrapper = {id:uuid.v4(),handler:handler}
    if not exchange[msg] then exchange[msg] = [wrapper] else exchange[msg].push wrapper
    console.log "handler #{wrapper.id} subscribing to #{msg}" 