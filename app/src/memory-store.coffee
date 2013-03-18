uuid = require('node-uuid')
models={}
mid = uuid.v4()

mstore = 
  load: (id,cb) -> 
    cb null,models[id]

  store: (model,cb) -> 
    models[model.id]=model
    cb? null,model.id

module.exports = mstore
