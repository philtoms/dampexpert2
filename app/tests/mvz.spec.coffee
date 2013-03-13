path = require "path"
injectr = require "injectr"

logSpy = createSpy "log"
listenSpy = createSpy "listen"
notReadySpy = createSpy "not ready"
getSpy = createSpy 'get'
ctxSpy = createSpy 'zappa ctx'

mvz = injectr "./src/mvz.coffee",  
  'zappajs':app: (fn) ->
      fn.call
        enabled:->
        all:->
        get:getSpy
        ctx:ctxSpy
        server:
          listen:listenSpy
          address:->
        app:
          set:->
          settings:env:'test'
          include:->
  ,{
    #console:log: ->
    console: console
    module:parent:filename:path.join(__dirname,"/mvz.spec.coffee")
    __filename:__filename
    __dirname:__dirname
  }

sut = null
mvz 3001, (ready) ->
  sut = this
  if not listenSpy.callCount then notReadySpy()
  ready()

beforeEach ->
  getSpy.reset()
  ctxSpy.reset()
  # spyOn(sut,"include").andCallThrough()
  
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
    
  it "should be in mvz context with immediate access to zappa members", ->
    expect(sut.ctx).toHaveBeenCalledWith(sut)
 
describe "nested zappa modules included in previously included modules", ->

  beforeEach ->
    sut.include './includes/includenested'
    
  it "should be in mvz context with immediate access to zappa members", ->
    expect(sut.ctx).toHaveBeenCalledWith(sut)
  
xdescribe "named included modules that override previosuly named extensions", ->

  beforeEach ->
    result = sut.extend x:controller:-> 
      @val = 123
      @ctx = -> @app.ctx @val
    sut.include x:'./includes/includeoverride'
    
  it "should override existing members", ->
    expect(ctxSpy).toHaveBeenCalledWith(456)
  
describe "included modules that override previosuly named extensions", ->

  beforeEach ->
    sut.extend x:controller:-> 
      @val = 123
      @ctx = -> @app.ctx @val
    sut.include './includes/includeoverride'
    
  it "should override existing members", ->
    expect(ctxSpy).toHaveBeenCalledWith(456)
  
describe "included extension modules", ->
  beforeEach ->
    sut.include './includes/includeextension'
    
  it "should be in extension context", ->
    expect(ctxSpy.mostRecentCall.args[0].val).toEqual(123)

  it "should not extend super context", ->
    expect(sut.includeCtx).not.toBeDefined()
  
describe "child extension modules", ->
  _super=null
  _child=null
  beforeEach ->
    sut.include './includes/includeextension'
    sut.include './includes/extendextension'
    _super = ctxSpy.calls[0].args[0]
    _child = ctxSpy.calls[1].args[0]

  it "should inherit from super", ->
    expect(_child.includeCtx).toBeDefined()

  it "should be in extension context", ->
    expect(sut.ctx).toHaveBeenCalledWith(_child)

  it "should not extend super context", ->
    expect(_super.extendCtx).not.toBeDefined()

