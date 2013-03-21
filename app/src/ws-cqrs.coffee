module.exports = (bus) ->
  _on = @on
  @on = (obj) ->
    ctx = this
    router = (obj) ->
      ctx.log.debug "routing #{obj.message}"
      
      bus.subscribe obj.message, (data, err) -> 
        obj.handler.call ctx, data,err
        
      return (data) ->

        ack = @ack? =>
          @ack {message:obj.message,time:new Date}

        ctx.publish = (obj, ack) =>
          for k, v of obj
            ctx.log.debug "publishing message #{k}"
            bus.publishEvent.call ctx, k, v, ack
            
          @emit? obj # only if client is still connected

        bus.publishCommand.call ctx, obj.message, data, ack
                          
    ws_handler = {}
    for k, v of obj
      ws_handler[k] = router {message:k,handler:v}
      _on.call ctx, ws_handler
  
  @reset = ->
    bus.reset()