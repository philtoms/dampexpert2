path = require "path"
injectr = require "injectr"
logSpy = createSpy("log")
listenSpy = createSpy("listen")
mvz = injectr "./lib/mvz.coffee", 
  {'zappajs':
    app: (fn) ->
      fn.call {
        all:->
        get:->
        server:
          listen:listenSpy
          address:->
        app:
          set:->
          settings:env:'test'
      }
  },
  {
    console:console
    module:parent:filename:path.join(__dirname,"/include.spec.coffee")
  }

sut = mvz 3001, (ready) ->
  @extend log:logSpy
  @extend extension:createSpy("extension")
  ready()

describe "application intitialization", ->

  it "should listen on expected port", ->
    expect(listenSpy).toHaveBeenCalledWith(3001)
  
  it "should have added logging extension to base", ->
    expect(sut.log).toHaveBeenCalled()
  
describe "extensions registered at base", ->
  result = null
  beforeEach ->
    result = sut.extend -> return this

  it "should be included in the extended object", ->
    expect(result.extension).toBeDefined()
  
  it "should not have been called through extension", ->
    expect(result.extension).not.toHaveBeenCalled()
  
describe "including an extension module", ->
  result = null
  beforeEach ->
    result = sut.include "includeextension"
  
  it "should have called extend on the extension in extension context", ->
    expect(result.extended).toBeDefined()
    expect(sut.extended).not.toBeDefined()
  
  it "should have added base extension methods to the extension", ->
    expect(result.extend).toBeDefined()
    
describe "including a zappa module", ->
  result = null
  beforeEach ->
    spyOn(sut,"extend")
    sut.include "includezappa"
  
  it "should not have called extend", ->
    expect(sut.extend).not.toHaveBeenCalled()   
  
  it "should have called include on the module in sut context", ->
    expect(sut.included).toBeDefined()
