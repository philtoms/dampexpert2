uuid = require('node-uuid')
mstore = ->
  cache = {}
  models = {}
  
  id: uuid.v4()
  
  load: (id,cb) -> 
    cb null,models[id]

  query: (id,cb) ->
    qr=[]
    for k,v of models
      if k.indexOf(id)==0
        qr.push v
    cb null, qr
    
  store: (id,model,cb) -> 
    models[id]=model
    cb? null,id


module.exports = new mstore
