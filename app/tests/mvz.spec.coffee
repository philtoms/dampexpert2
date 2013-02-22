path = require "path"
injectr = require "injectr"

logSpy = createSpy "log"
listenSpy = createSpy "listen"
notReadySpy = createSpy "not ready"
getSpy = createSpy 'get'

mvz = injectr "./lib/mvz.js",  
  {'zappajs':
    app: (fn) ->
      fn.call {
        all:->
        get:getSpy
        server:
          listen:listenSpy
          address:->
        app:
          set:->
          settings:env:'test'
      }
  },
  {
    #console:log: ->
    console: console
    module:parent:filename:path.join(__dirname,"/mvz.spec.coffee")
  }
sut = null
mvz 3001, (ready) ->
  sut = this
  sut.ctx = createSpy("ctx")
  if not listenSpy.callCount then notReadySpy()
  ready()

describe "intitialized application", ->

  it "should not have started listening until app ready", ->
    expect(notReadySpy).toHaveBeenCalled()

  it "should be in mvz context with immediate access to zappa members", ->
    expect(sut.get).toBeDefined()
    
  it "should be in mvz context with immediate access to mvz members", ->
    expect(sut.extend).toBeDefined()
    
describe "ready application", ->

  it "should be listening on expected port", ->
    expect(listenSpy).toHaveBeenCalledWith(3001)

describe "included zappa modules", ->

  beforeEach ->
    getSpy.reset()
    spyOn(sut,"include").andCallThrough()
    sut.include './includes/includezappa'
    
  it "should be in mvz context with immediate access to mvz members", ->
    expect(sut.ctx).toHaveBeenCalledWith(sut)
  
  it "should have immediate access to zappa members", ->
    expect(sut.get.callCount).toEqual(1)
 
describe "nested included zappa modules", ->

  beforeEach ->
    getSpy.reset()
    spyOn(sut,"include").andCallThrough()
    sut.include './includes/includenested'
    
  it "should be in mvz context with immediate access to mvz members", ->
    expect(sut.ctx).toHaveBeenCalledWith(sut)
  
describe "included override modules", ->
  result = null
  beforeEach ->
    getSpy.reset()
    sut.extend 'x':-> 123
    result = sut.include 'x':'./includes/includeoverride'
    
  it "should override existing members", ->
    expect(sut.x).toEqual(456)
  
describe "included extension modules", ->

  beforeEach ->
    getSpy.reset()
    sut.include './includes/includeextension'
    
  it "should be in zappa context with direct access to zappa members", ->
    expect(sut.get).toHaveBeenCalled()
