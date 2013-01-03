injectr = require "injectr"
getSpy = createSpy()
listenSpy = createSpy()
mvz = injectr "./lib/mvz.coffee", 
  zappa: app: (fn) ->
          return {
            app:{
             listen: listenSpy
             address:->
             settings:env:{}
            }
            root: __dirname
            get: getSpy
            log: (x) -> console.log x
          }
          
mvzSut = null
mvz 80, -> mvzSut = this

describe "initialized mvz", ->
  
  it "should be listening on expected port", ->
    expect(listenSpy.argsForCall[0][0]).toEqual(80)
  
describe "extended controller", ->
  result = null
  beforeEach ->
    getSpy.reset()
    result = mvzSut.include "../tests/includetest"
  
  it "should have established a default route", ->
    expect(result.route).toEqual("includetest")
    
  it "should have extended zappa route verbs", ->
    expect(result.get).toBeDefined()
    expect(result.put).toBeDefined()
    expect(result.post).toBeDefined()
    expect(result.del).toBeDefined()

  it "should have registered a default route handler", ->
    expect(typeof getSpy.argsForCall[0][1]).toEqual('function')

  it "should have added zappa to new cotroller", ->
    expect(result.app).toBeDefined()

describe "further extension of extended controller", ->
  result = null
  beforeEach ->
    base = mvzSut.include "../tests/includetest"
    result = base.extend (-> return this), "extended"
  
  it "should have inherited include method", ->
    expect(result.include).toBeDefined()

  it "should have extended zappa route verbs", ->
    expect(result.get).toBeDefined()
    expect(result.put).toBeDefined()
    expect(result.post).toBeDefined()
    expect(result.del).toBeDefined()

  it "should have established a default subroute", ->
    expect(result.route).toEqual("includetest/extended")
    
describe "further extension of extension on same route", ->
  result = null
  beforeEach ->
    base = mvzSut.include "../tests/includetest"
    result = base.extend -> return this
  
  it "should not have established a new default route", ->
    expect(result.route).toEqual("includetest")
    
describe "extension of a member", ->
  result = null
  beforeEach ->
    base = mvzSut.include "../tests/includetest"
    result = base.extend "member":-> return this
  
  it "should have inherited include method", ->
    expect(result.include).toBeDefined()

  it "should have inherited base member", ->
    expect(result.member).toEqual("member")

describe "override of extension member", ->
  result = null
  beforeEach ->
    base = mvzSut.include "../tests/includetest"
    result = base.extend "member":-> 
      @member="member1"
      return this
  
  it "should have overriden inherited base member", ->
    expect(result.member).toEqual("member1")
