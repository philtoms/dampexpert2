uuid = require('node-uuid')

@include = ->

  #repo = @repo || require('nstore')

  _on = @on
  @on = (obj) ->
    router = (obj) ->
      console.log "es wrapping #{obj.message}"
      return ->
        _publish = @publish
        @publish = (obj, cb) ->
          _publish.apply this,[obj,cb]
          for k, v of obj
            if not k.id?
              evntKey = {event:k,id:uuid.v4()}
              if not v.id then v.id=uuid.v4()
              console.log "storing #{k},#{evntKey.id} : #{v}"
              #repo.store(evntKey,v, -> cb? v.id)        
            else
              console.log "already stored #{k},#{evntKey.id} : #{v}"
                
        obj.handler.apply this
                    
    es_handler = {}
    for k, v of obj
      es_handler[k] = router {message:k,handler:v}
      _on es_handler
