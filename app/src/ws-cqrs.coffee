module.exports = (bus) ->
  _on = @on
  @on = (obj) ->
    ctx = this
    router = (obj) ->
      console.log "routing #{obj.message}"
      
      bus.subscribe obj.message, (data) -> 
        ctx.data = data
        obj.handler.apply ctx
        
      return ->

        ack = @ack? =>
          @ack {message:obj.message,time:new Date}

        ctx.publish = (obj, ack) =>
          for k, v of obj
            console.log "publishing message #{k}"
            bus.publishEvent.call ctx, k, v, ack
            
          @emit? obj # only if client is still connected
          
        bus.publishCommand.call ctx, obj.message, @data, ack
                          
    ws_handler = {}
    for k, v of obj
      ws_handler[k] = router {message:k,handler:v}
      _on ws_handler
