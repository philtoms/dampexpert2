path = require "path"
injectr = require "injectr"

mvz = injectr "./src/mvz.coffee",  
  'zappajs':app: (fn) ->
      fn.call
        enabled:->
        server:
          listen:->
          address:->
        app:
          set:->
          settings:env:'test'
          include:->
  ,{
    console: console
    module:parent:filename:path.join(__dirname,"/mvz.spec.coffee")
    __filename:__filename
    __dirname:__dirname
  }

sut = null
mvz 3001, (ready) ->
  sut = this
  ready()

describe "ioc container", ->
 
  it "should inject ioc extensions", ->
    sut.extend inject:->@x=->
    sut.extend viewmodel:->
      expect(@x).toBeDefined()
      
  it "should inject included ioc extensions", ->
    sut.include './includes/includeinject'
    debugger
    sut.extend viewmodel:->
      expect(@x).toBeDefined()