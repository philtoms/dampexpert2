require('zappajs') ->

  @get '/': ->
    @render index: {layout: no}

  # controller
  _on = @on
  @on = (obj) ->
  
    router = (obj) ->
      console.log obj.message + " routed!"
      return (data,ack) ->
        msg = "#{obj.message} #{@data.text} received!"
        console.log msg
        ack? msg
        # push
        # pop      
        # model
        _emit = @emit
        _broadcast = @broadcast
        @broadcast = (obj) ->
          for k, v of obj
            msg = "event #{v.text} dispatched!"
            console.log msg
          _emit obj
          _broadcast obj
        obj.handler.apply this, [@socket]
        
    for k, v of obj
      ws_handler = {}
      ws_handler[k] = router {message:k,handler:v}
      _on ws_handler
    return
      
  # model
  @on command: (socket) ->
    msg = "command #{@data.text} handled!"
    console.log msg
    @broadcast event: @data
    
  @on event : ->
    msg = "event #{@data.text} handled!"
    console.log msg
    
  @client '/index.js': ->
    @connect()

    $ =>

      @on event: ->
        $('#panel').append "<p>event: #{@data.text} received</p>"

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
