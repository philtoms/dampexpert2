@include = ->

  bus = @bus || require('./memory.bus')
  #idempotent = (opts.idempotent? opts.idempotent) || true
  
  _on = @on
  @on = (obj) ->
    router = (obj) ->
      console.log "routing #{obj.message}"
        
      bus.subscribe obj.message, obj.handler

      return ->

        ack = =>
          @ack? {message:obj.message,time:new Date}
          
        ctx = (handler,data) => 
          @data = data
          handler.apply this
        
        @publish = (obj,ack) =>
          for k, v of obj
            console.log "publishing message #{k}"
            bus.publish k, v, ctx, ack
            
          @emit obj # only if client is 'still' connected
          
        bus.publish obj.message, @data, ctx, ack
                          
    ws_handler = {}
    for k, v of obj
      ws_handler[k] = router {message:k,handler:v}
      _on ws_handler
      
    return