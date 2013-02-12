@include = ->

  bus = @bus || require('./memory.bus')
  
  _on = @on
  @on = (obj) ->
    router = (obj) ->
      console.log obj.message + " routed!"
        
      bus.subscribe obj.message, obj.handler

      return ->

        ack = =>
          @ack? {message:obj.message,time:new Date}
          
        ctx = (handle,data) => 
          @data = data
          handle.apply this
        
        @publish = (obj) =>
          for k, v of obj
            console.log "message #{k} dispatched!"
            bus.publish k, v, ack, ctx

          @emit obj # only if client is 'still' connected
          
        bus.publish obj.message, @data, ack, ctx
                          
    ws_handler = {}
    for k, v of obj
      ws_handler[k] = router {message:k,handler:v}
      _on ws_handler
    return
