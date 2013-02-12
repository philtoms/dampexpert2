exchange = {}
module.exports = 
  publish: (msg,data,ack,ctx) -> 
    ack()
    for handle in exchange[msg] 
      console.log "publishing #{msg} to handler" 
      ctx handle,data
    
  subscribe: (msg,handle) -> 
    if not exchange[msg] then exchange[msg] = [handle] else exchange[msg].push handle
    console.log "subscribing to #{msg}" 