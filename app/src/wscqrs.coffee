@include = ->

  bus = @bus || require('./direct-bus')
  #idempotent = (opts.idempotent? opts.idempotent) || true
  
  _on = @on
  @on = (obj) ->
    router = (obj) ->
      console.log "routing #{obj.message}"
         
      ctx = (data) => 
        @data = data
        obj.handler.apply this
        
      bus.subscribe obj.message, ctx

      return ->

        ack = =>
          @ack? {message:obj.message,time:new Date}
        
        @publish = (obj,ack) =>
          for k, v of obj
            console.log "publishing message #{k}"
            bus.publish k, v, ack # event
            
          @emit obj # only if client is 'still' connected
          
        bus.publish obj.message, @data, ack # command
                          
    ws_handler = {}
    for k, v of obj
      ws_handler[k] = router {message:k,handler:v}
      _on ws_handler
      
    return
