path = require "path"
injectr = require "injectr"

mvz = injectr "./src/mvz.coffee",  
  'zappajs':app: (fn) ->
      fn.call
        enabled:->
        app:
          set:->
  ,{
    console: console
    module:parent:filename:path.join(__dirname,"../src/x")
  }

sut = null
mvz 3001, (ready) ->
  sut = this

describe "ioc container", ->
 
  it "should inject ioc extensions", ->
    sut.extend inject:->@x=->
    sut.extend viewmodel:->
      expect(@x).toBeDefined()
      
  it "should inject included ioc extensions", ->
    sut.include '../tests/includes/includeinject'
    sut.extend viewmodel:->
      expect(@x).toBeDefined()
      
  it "should inject extensions that override default behaviour", ->
    sut.extend log:inject:->
      @log = (m) -> @x()
    sut.extend viewmodel:->
      @x=createSpy()
      @log 'xyz'
      expect(@x).toHaveBeenCalled()