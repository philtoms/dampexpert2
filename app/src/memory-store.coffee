uuid = require('node-uuid')
models={}
mid = uuid.v4()

mstore = 
  load: (id,cb) -> 
    cb null,models[id]

  query: (id,cb) ->
    q = for k,v of models
      m v if v.id.indexOf(id)==0
    cb null, q
    
  store: (id,model,cb) -> 
    models[id]=model
    cb? null,id

module.exports = mstore
