path = require "path"
injectr = require "injectr"

emit = {}
setValues = {}
errors = []
models = {}
bus={}
mvz = injectr.call this, "./src/mvz.coffee",  
  'zappajs': app: (fn) ->
      fn.call
        enabled:(k) -> if setValues[k] then setValues[k] else false
        enable:(k) -> setValues[k]=true
        disable:(k) -> if setValues[k] then setValues[k]=false
        all:->
        get:->
        on:(obj)->emit[k]=v for k,v of obj
        server:
          listen:->
          address:->
        app:
          set:(o)-> setValues[k]=v for k,v of o
          get:(k)-> setValues[k]
          settings:env:'test'
  './ws-cqrs': require('../src/ws-cqrs')  
  './memory-bus': bus=require('../src/memory-bus')  
  './eventsource': require('../src/eventsource')  
  './memory-store': require('../src/memory-store')
  ,{
    #console:log: ->
    console: console
    module:parent:filename:path.join(__dirname,"/inject.spec.coffee")
    __filename:__filename
    __dirname:__dirname
  }

sut = null
mvz 3001, (ready) ->
  sut = this
  ready()

describe "ioc container", ->
 
  it "should accept inject extensions", ->
