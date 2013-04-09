uuid = require('node-uuid')
MStore = ->
  models = {}
  
  id: uuid.v4()
  
  load: (id,cb) -> 
    cb null,models[id]

  loadAll: (id,cb) ->
    qr=[]
    for k,v of models
      if k.indexOf(id)==0
        qr.push v
    cb null, qr
    
  store: (id,model,cb) -> 
    models[id]=model
    cb? null,id


module.exports = new MStore
