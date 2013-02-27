path = require "path"
injectr = require "injectr"

logSpy = createSpy "log"
listenSpy = createSpy "listen"
notReadySpy = createSpy "not ready"
getSpy = createSpy 'get'
zappaCtxSpy = createSpy 'zappa ctx'

mvz = injectr "./lib/mvz.js",  
  {'zappajs':
    app: (fn) ->
      fn.call {
        all:->
        get:getSpy
        zappaCtx:zappaCtxSpy
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

beforeEach ->
  getSpy.reset()
  zappaCtxSpy.reset()
  spyOn(sut,"include").andCallThrough()
  
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
    sut.include './includes/includezappa'
    
  it "should be in mvz context with immediate access to mvz members", ->
    expect(sut.ctx).toHaveBeenCalledWith(sut)
  
  it "should have immediate access to zappa members", ->
    expect(sut.zappaCtx).toHaveBeenCalledWith(sut)
 
describe "nested included zappa modules", ->

  beforeEach ->
    sut.include './includes/includenested'
    
  it "should be in mvz context with immediate access to mvz members", ->
    expect(sut.ctx).toHaveBeenCalledWith(sut)
  
describe "included override modules", ->
  result = null
  beforeEach ->
    sut.extend 'x':-> 123
    result = sut.include 'x':'./includes/includeoverride'
    
  it "should override existing members", ->
    expect(sut.x).toEqual(456)
  
describe "included extension modules", ->
  result=null
  beforeEach ->
    sut.include './includes/includeextension'
    result = sut.zappaCtx.mostRecentCall.args[0]
    
  it "should be in extension context", ->
    expect(result.includeCtx).toBeDefined()

  it "should not extend super context", ->
    expect(sut.includeCtx).not.toBeDefined()

  it "should have indirect access to zappa members", ->
    expect(result.app).toBeDefined()
  
describe "extended extension modules", ->
  _super=null
  result=null
  beforeEach ->
    sut.include './includes/includeextension'
    _super = sut.zappaCtx.mostRecentCall.args[0]
    debugger
    sut.include './includes/extendextension'
    result = sut.zappaCtx.mostRecentCall.args[0]
    
  it "should inherit from super", ->
    expect(result.includeCtx).toBeDefined()

  it "should be in extension context", ->
    expect(result.extendCtx).toBeDefined()

  it "should not extend super context", ->
    expect(_super.extendCtx).not.toBeDefined()

