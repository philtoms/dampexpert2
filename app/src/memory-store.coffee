uuid = require('node-uuid')
models={}
mid = uuid.v4()

mstore = 
  load: (id,cb) -> 
    process.nextTick ->
      cb null,models[id]

  store: (model,cb) -> 
    models[model.id]=model
    process.nextTick ->
      cb? null,model.id

module.exports = mstore
