uuid = require('node-uuid')
models=null
sequence=0
module.exports = (init,handlers) ->

  models = models || require(@app.get 'model-store')

  eventStore = {
    load:(id,cb)-> models.query id, (err,events) ->
      aggregate = {}
      for k,v of init
        aggregate[k]=v
      for e in events
        for k,v of e
          name = k.split('/')[2]
          if handlers[name]
            handlers[name].call aggregate,v
      cb null,aggregate
      
    store:(model,cb)-> 
      # cache the model?
      models.store model,cb
  }
  _on = @on
  _publish = null
  @on = (obj) ->
    ctx = this
    es_publish = (obj, cb) ->
      for k, v of obj
        v.sequence = ++sequence
        _publish.apply ctx,[obj,cb]
        eventid = "#{v.id}/#{sequence}/#{k}"
        ctx.log.debug "storing #{eventid}"
        models.store(eventid,v, -> cb? v.id)

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