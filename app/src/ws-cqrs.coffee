module.exports = (bus) ->
  _on = @on
  @on = (obj) ->
    ctx = this
    router = (obj) ->
      ctx.log "routing #{obj.message}"
      
      bus.subscribe obj.message, (data, err) -> 
        obj.handler.call ctx, data,err
        
      return (data) ->

        ack = @ack? =>
          @ack {message:obj.message,time:new Date}

        ctx.publish = (obj, ack) =>
          for k, v of obj
            ctx.log "publishing message #{k}"
            bus.publishEvent.call ctx, k, v, ack, (err) ->
              console.log err
            
          @emit? obj # only if client is still connected
          
        bus.publishCommand.call ctx, obj.message, data, ack, (err) ->
          console.log err
                          
    ws_handler = {}
    for k, v of obj
      ws_handler[k] = router {message:k,handler:v}
      _on ws_handler