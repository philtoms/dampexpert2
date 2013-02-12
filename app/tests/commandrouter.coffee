require('zappajs') ->

  @get '/': ->
    @render index: {layout: no}

  _on = @on
  @on = (obj) ->
    for k, v of obj
      ws_handler = {}
      ws_handler[k] = router {command:k,handler:v}
      _on ws_handler
    return

  router = (obj) ->
    console.log obj.command + " routed!"
    return (data,ack) ->
      msg = "#{obj.command} #{@data.text} received!"
      console.log msg
      ack? msg
      obj.handler.apply this, [@socket,@io]
      
  # model
  @on command: (socket,io) ->
    msg = "command #{@data.text} handled!"
    emitEvent.apply this, [socket]
    console.log msg
    
  # model event handler
  emitEvent = (socket) ->
    msg = "event #{@data.text} dispatched!"
    socket.emit "event", {text: msg}
    @emit event: {text: msg}
    #@io.emit event: {text: msg}
    console.log msg
    
  @client '/index.js': ->
    @connect()

    $ =>

      @on event: ->
        $('#panel').append "<p>event: #{@data.text}</p>"

      @emit "command", {text: 'value'}, (r) ->
        $('#panel').append "<p>result: #{r}</p>"

  @view index: ->
    doctype 5
    html ->
      head ->
        title 'Command Router!'
        script src: '/zappa/Zappa-simple.js'
        script src: '/index.js'
      body ->
        div id: 'panel'
