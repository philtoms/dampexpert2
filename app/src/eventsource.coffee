models=null
nextsequence=0
module.exports = (init,handlers) ->

  models = models || require(@app.get 'model-store')

  eventStore = {
    load:(id,cb)-> models.query id, (err,events) ->
      aggregate = {}
      for k,v of init
        aggregate[k]=v
      for e in (events.sort (a,b) -> a.id.split('/')[1] - b.id.split('/')[1])
        name = e.id.split('/')[2]
        if handlers[name]
          aggregate.hydrating=true
          handlers[name].call aggregate,e.payload
          delete aggregate.hydrating
      cb null,aggregate
      
    store:(model,cb)-> 
      # cache the model?
      models.store model,cb
  }
  #nextsequence = models.query?
  
  _on = @on
  _publish = null
  @on = (obj) ->
    ctx = this
    es_publish = (obj, cb) ->
      # effectively switched off during hydration
      if @hydrating then return
      for k, v of obj
        sequence=++nextsequence
        _publish.apply ctx,[obj,cb]
        eventid = "#{v.id}/#{sequence}/#{k}"
        ctx.log.debug "storing #{eventid}"
        models.store(eventid,{id:eventid,payload:v}, -> cb? v.id)

    router = (obj) ->
      ctx.log.debug "es wrapping #{obj.message}"
      
      return (data) ->
        _publish = _publish || @publish
        @publish = es_publish
        obj.handler.call @, data
                    
    es_handler = {}
    for k, v of obj
      es_handler[k] = router {message:k,handler:v}
      _on.call ctx, es_handler
  
  return eventStore