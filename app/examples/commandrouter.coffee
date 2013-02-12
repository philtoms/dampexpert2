require('zappajs') ->

  @include '../lib/wscqrs'

  @get '/': ->
    @render index: {layout: no}
     
  # model
  @on command: ->
    msg = "command #{@data.text} handled!"
    console.log msg
    @publish event: @data
    
  @on event : ->
    msg = "event #{@data.text} handled!"
    console.log msg
    
  @client '/index.js': ->
    @connect()

    $ =>

      @on event: ->
        $('#panel').append "<p>event: #{@data.text} received</p>"

      @emit "command", {text: 'buy ultrovent'}, (r) ->
        $('#panel').append "<p>#{r.message} submitted at #{r.time}</p>"

  @view index: ->
    doctype 5
    html ->
      head ->
        title 'Command Router!'
        script src: '/zappa/Zappa-simple.js'
        script src: '/index.js'
      body ->
        div "Hello Susie!!"
        div id: 'panel'
