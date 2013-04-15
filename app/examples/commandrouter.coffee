app = require('../') 
app (ready) ->

  @get '/': ->
    @render index: {layout: no}
     
  @extend model:->
    @on command: ->
      msg = "command #{@data.text} handled!"
      console.log msg
      @publish event: "bought!"
    
    @on event : ->
      msg = "event #{@data} handled!"
      console.log msg
    
    @on event : ->
      msg = "event #{@data} handled again!"
      console.log msg
    
  @client '/index.js': ->
    @connect()

    $ =>

      @on event: ->
        $('#panel').append "<p>event: #{@data} received</p>"

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
        
  ready()