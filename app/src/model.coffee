uuid = require('node-uuid')

_publish=null
models = null

@include = model: (base,_super) ->

  handlers={}
  mappings={}
  init={}
  modelId = uuid.v4()
  
  if base.enabled 'eventsourcing'
    # bind eventsource wrapper to this model
    models = require(base.app.get 'eventsourcing').apply base, [mapViewData(init),handlers]
  else
    models = models || require(base.app.get 'model-store')

  @['on'] = (obj) ->
    for k,h of obj
      handlers[k]=h
      obj[k]= (cmd) =>
        _publish=_publish || @publish
        id = cmd?.id || modelId
        models.load id, (err,state) ->
          if (err or not state)
            state = init
            if cmd?.id? # ie - we have a command but not a model
              return base.log.error "Model aggregate not found for id #{cmd.id}"
            
          model = mapViewData(state, model)
          model.id=id
          model.log = base.log
          model.publish=(obj,ack) ->
            for msg,data of obj
              data.id=model.id # no nonsense
              _publish.call model, obj,ack
              if base.enabled('automap events') and not handlers[msg]
                model = mapViewData(data,model)
            models.store mapViewData(model)
            if _super.viewmodel then _super.viewmodel = mapViewData(model)
          # switch to model context in handlers
          handlers[k].call model,cmd
        
    base['on'].call @, obj

  # build a mapper
  @map = (p) ->
    if typeof p isnt 'object' 
      mappings[p]=true
      init[p]=null
    else for k,v of p
      if typeof v is 'function' 
        mappings[k]=v
        v=v(null,false)
      else
        mappings[k]=true
      init[k]=v

  mapViewData = (src, dest)->
    dest = dest || {}
    for k,m of mappings
      if src[k] isnt undefined
        if typeof m isnt 'function'
          dest[k] = src[k] 
        else
          dest[k] = m(src[k])
    
    return dest
    