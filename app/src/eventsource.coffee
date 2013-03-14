uuid = require('node-uuid')

module.exports = ->

  #repo = @repo || require('nstore.events')

  _on = @on
  @on = (obj) ->
    ctx = this
    router = (obj) ->
      ctx.log "es wrapping #{obj.message}"
      return (data,err) ->
        _publish = @publish
        @publish = (obj, cb) ->
          _publish.apply ctx,[obj,cb]
          for k, v of obj
            if not k.id?
              evntKey = {event:k,id:uuid.v4()}
              ctx.log "storing #{k},#{evntKey.id} : #{v}"
              #repo.store(evntKey,v, -> cb? v.id)        
            else
              ctx.log "already stored #{k},#{evntKey.id} : #{v}"
                
        obj.handler.call ctx, data, err
                    
    es_handler = {}
    for k, v of obj
      es_handler[k] = router {message:k,handler:v}
      _on.call ctx, es_handler
