cqrs = (bus) ->
  _on = @on
  @on = (obj) ->
    ctx = this
    router = (obj) ->
      console.log "routing #{obj.message}"
      
      bus.subscribe obj.message, (data) => 
        @data = data
        obj.handler.apply ctx
        
      return ->

        ack = @ack? =>
          @ack {message:obj.message,time:new Date}

        _publish = ctx.publish
        ctx.publish = (obj,ack) =>
          for k, v of obj
            console.log "publishing message #{k}"
            _publish v
            bus.publish k, v, ack # event
            
          @emit? obj # only if client is 'still' connected
          
        bus.publish obj.message, @data, ack # command
                          
    ws_handler = {}
    for k, v of obj
      ws_handler[k] = router {message:k,handler:v}
      _on ws_handler
      
 module.exports = cqrs
