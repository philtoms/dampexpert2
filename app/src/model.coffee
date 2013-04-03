uuid = require('node-uuid')

_publish=null
models = null

@include = model: (base,_super) ->

  handlers={automap:(event) -> mapViewData(event,this)}
  mappings={}
  init={}
  cache = {}
  modelId = uuid.v4()
  eventsourcing=false
  
  loadState = (models,id,cb) ->
    if cache[id] 
      cache[id].ref++
      cb null,cache[id].state
    else
      models.load id, (err,state) ->
        state = state||{}
        cache[id]={ref:1,state}
        cb err,state
        
  unloadState = (id) ->
    cache[id].ref--
    if cache[id].ref<1 then delete cache[id]
      
  @['on'] = (obj) ->
  
    if not eventsourcing and base.enabled 'eventsourcing'
      # bind eventsource wrapper to this model
      models = require(base.app.get 'eventsource').apply this, [mapViewData(init),handlers]
      eventsourcing = true
    else
      models = models || require(base.app.get 'model-store')

    for k,h of obj
      handlers[k]=h
      obj[k]= (cmd) =>
        _publish = @publish
        id = cmd?.id || modelId
        loadState models, id, (err,state) ->
          if (err or Object.keys(state).length==0)
            mapViewData(init,state)
            if cmd?.id? # ie - we have a command but not a model
              unloadState id
              return base.log.error "Model aggregate not found for id #{cmd.id}"
            
          model = state
          model.id=id
          model.log = base.log
          model.publish=(obj,ack) ->
            for msg,data of obj
              if not data then obj[msg] = {}
              obj[msg].id=id # no nonsense
              _publish.call model, obj,ack
              if base.enabled('automap events') and not handlers[msg]
                model = mapViewData(data,model)
            models.store id,mapViewData(model)
            if _super.viewmodel then _super.viewmodel = mapViewData(model)
          # switch to model context in handlers
          handlers[k].call model,cmd
        unloadState id
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
      
  # all models have an id
  @map "id"
  
  mapViewData = (src, dest)->
    dest = dest || {}
    for k,m of mappings
      if src[k] isnt undefined
        if typeof m isnt 'function'
          dest[k] = src[k] 
        else
          dest[k] = m(src[k])
    
    return dest
    