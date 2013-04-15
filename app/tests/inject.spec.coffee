path = require "path"
injectr = require "injectr"

mvz = injectr path.join(__dirname,"../lib/mvz.js"),  
  'zappajs':app: (fn) ->
      fn.call
        app:
          enabled:->
          enable:->
          set:->
  ,{
    console: console
    module:parent:filename:path.join(__dirname,"../x")
  }
  
sut = null
mvz (ready) ->
  sut = this

describe "ioc container", ->
 
  it "should inject ioc extensions", ->
    sut.extend inject:->@x=->
    sut.extend viewmodel:->
      expect(@x).toBeDefined()
      
  it "should inject included ioc extensions", ->
    sut.include '../app/tests/includes/includeinject'
    sut.extend viewmodel:->
      expect(@x).toBeDefined()
      
  it "should inject extensions that override default behaviour", ->
    sut.extend log:inject:->
      @log = (m) -> @x()
    sut.extend viewmodel:->
      @x=createSpy()
      @log 'xyz'
      expect(@x).toHaveBeenCalled()