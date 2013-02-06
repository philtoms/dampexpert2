path = require "path"
injectr = require "injectr"
getSpy = createSpy("get")
mvz = injectr "./lib/mvz.coffee", 
  {'zappajs':
    app: (fn) ->
      fn.call {
        all:->
        get:getSpy
        server:
          listen:->
          address:->
        app:
          set:->
          settings:env:'test'
      }
  },
  {
    console:log:->
    module:parent:filename:path.join(__dirname,"/controller.spec.coffee")
  }

sut = mvz 3001, (ready) ->
  ready()
  
describe "extending the controller", ->
  result = null
  beforeEach ->
    getSpy.reset()
    result = sut.include "extendcontroller"

  it "should have established a default route", ->
    expect(result.route).toEqual("/extendcontroller")
    
  it "should have added base extension methods to the extension", ->
    expect(result.extend).toBeDefined()
    
  it "should have added controller extension methods to the extension", ->
    expect(result.get).toBeDefined()
    
  it "should have registered a default route handler", ->
    expect(typeof getSpy.argsForCall[0][1]).toEqual('function')

  it "should have added zappa to new controller", ->
    expect(result.app).toBeDefined()

describe "further extending an extension", ->
  result = null
  beforeEach ->
    base = sut.include "extendcontroller"
    result = base.include "extendcontroller"
  
  it "should have established a default subroute", ->
    expect(result.route).toEqual("/extendcontroller/extendcontroller")
    
describe "further extending an extension on the same route", ->
  result = null
  beforeEach ->
    base = sut.include "extendcontroller"
    result = base.extend -> return this
  
  it "should not have established a new default route", ->
    expect(result.route).toEqual("/extendcontroller")
    
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
