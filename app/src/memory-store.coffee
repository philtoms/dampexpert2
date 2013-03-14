uuid = require('node-uuid')
models={}

store = 
  load: (id,cb) -> 
    process.nextTick ->
      cb null,models[id]

  store: (model,cb) -> 
    models[model.id]=model
    process.nextTick ->
      cb? null,model.id

module.exports = store
