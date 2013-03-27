uuid = require('node-uuid')
models=null

module.exports = (init,handlers) ->

  models = models || require(@app.get 'model-store')

  eventStore = {
    load:(id,cb)-> models.query id, (err,events) ->
      aggregate = {}
      for k,v of init
        aggregate[k]=v
      for e in events
        name = e.id.split('/')[2]
        if handlers[name]
          e.id=e.id.split('/')[0]
          handlers[name].call aggregate,e
      cb null,aggregate
      
    store:(model,cb)-> 
      # cache the model?
      models.store model,cb
  }
  
  _on = @on
  @on = (obj) ->
    ctx = this
    _publish = null
    es_publish = (obj, cb) ->
      _publish.apply ctx,[obj,cb]
      for k, v of obj
        eventid = "#{v.id}/#{uuid.v1()}/#{k}"
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