module.exports = (init,handlers) ->

  buffer = []
  models = models || require(@app.get 'model-store')
  log = @log
  automap = @app.enabled 'automap events'
  
  nextsequence = 0
  
  eventStore = {
    load:(id,cb)-> models.loadAll id, (err,events) ->
      aggregate = {id:id}
      for k,v of init
        aggregate[k]=v
        
      sequence=0
      for e in (events.sort (a,b) -> a.id.split('/')[1] - b.id.split('/')[1])
        name = e.id.split('/')[2]
        if automap and not handlers[name]
          name='automap'

        if handlers[name]
          sequence++
          aggregate.hydrating=true
          handlers[name].call aggregate,e.payload
          delete aggregate.hydrating
        nextsequence = sequence if sequence>nextsequence
      cb null,aggregate
      
    store:(model,cb)->
      for e in buffer
        sequence=++nextsequence
        for k, v of e
          eventid = "#{v.id}/#{sequence}/#{k}"
          log.debug "storing #{eventid}"
          models.store eventid, {id:eventid,payload:v}

      buffer=[]
  }
  
  _on = @on
  _publish = null
  @on = (obj) ->
    ctx = this
    es_publish = (obj) ->
      # switched off during hydration
      if @hydrating then return
      buffer.push obj
      _publish.apply ctx,[obj]

    wrap = (obj) ->
      log.debug "es wrapping #{obj.message}"      
      return (data) ->
        _publish = _publish || @publish
        @publish = es_publish
        obj.handler.call @, data
                    
    es_handler = {}
    for k, v of obj
      es_handler[k] = wrap {message:k,handler:v}
      _on.call ctx, es_handler
  
  return eventStore