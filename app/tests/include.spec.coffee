path = require "path"
injectr = require "injectr"
logSpy = createSpy("log")
getSpy = createSpy("get")
listenSpy = createSpy("listen")
mvz = injectr "./lib/mvz.coffee", 
  {'zappajs':
    app: (fn) ->
      fn.call {
        get:getSpy
        server:
          listen:listenSpy
          address:->
        app:settings:env:'test'
      }
  },
  {
    console:console
    module:parent:filename:path.join(__dirname,"/include.spec.coffee")
  }

sut = mvz 3001, (ready) ->
  @extend log:logSpy
  ready()

describe "application intitailization", ->

  it "should listen on expected port", ->
    expect(listenSpy).toHaveBeenCalledWith(3001)
  
  it "should have included application extensions", ->
    expect(logSpy).toHaveBeenCalled()
  
describe "extensions registered at base", ->
  result = null
  beforeEach ->
    tsut = mvz 1,->
    tsut.extend extension: createSpy("extension")
    result = tsut.extend -> return this

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
  
describe "extending the controller", ->
  result = null
  beforeEach ->
    getSpy.reset()
    result = sut.include "extendcontroller"
  
  it "should have established a default route", ->
    expect(result.route).toEqual("extendcontroller")
    
  it "should have added base extension methods to the extension", ->
    expect(result.extend).toBeDefined()
    
  it "should have added controller extension methods to the extension", ->
    expect(result.get).toBeDefined()
    
  it "should have registered a default route handler", ->
    expect(typeof getSpy.argsForCall[0][1]).toEqual('function')

  it "should have added zappa to new controller", ->
    expect(result.app).toBeDefined()

describe "further extension of extended controller", ->
  result = null
  beforeEach ->
    base = sut.include "extendcontroller"
    result = base.include "extendcontroller"
  
  it "should have established a default subroute", ->
    expect(result.route).toEqual("extendcontroller/extendcontroller")
    
describe "further extension of extended controller on same route", ->
  result = null
  beforeEach ->
    base = sut.include "extendcontroller"
    result = base.extend -> return this
  
  it "should not have established a new default route", ->
    expect(result.route).toEqual("extendcontroller")
    
describe "extending an object member", ->
  result = null
  beforeEach ->
    base = sut.include "extendcontroller"
    result = base.extend "member":-> return this
  
  it "should have inherited base methods", ->
    expect(result.include).toBeDefined()

  it "should have inherited base member members", ->
    expect(result.members).toBeDefined()

describe "overriding an object member", ->
  result = null
  beforeEach ->
    base = sut.include "extendcontroller"
    result = base.extend "member":-> 
      @members="member1"
      return this
  
  it "should have overriden inherited base member", ->
    expect(result.members).toEqual("member1")
