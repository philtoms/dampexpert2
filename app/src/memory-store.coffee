uuid = require('node-uuid')
models={}
mid = uuid.v4()

mstore = 
  load: (id,cb) -> 
    cb null,models[id]

  query: (id,cb) ->
    qr=[]
    for k,v of models
      if k.indexOf(id)==0
        r={};r[k]=v
        qr.push r 
    cb null, qr
    
  store: (id,model,cb) -> 
    models[id]=model
    cb? null,id

module.exports = mstore
