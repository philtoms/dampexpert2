path = require "path"
injectr = require "injectr"

logSpy = createSpy "log"
listenSpy = createSpy "listen"
notReadySpy = createSpy "not ready"
getSpy = createSpy 'get'
ctxSpy = createSpy 'zappa ctx'

mvz = injectr "./src/mvz.coffee",  
  {'zappajs':
    app: (fn) ->
      fn.call {
        all:->
        get:getSpy
        ctx:ctxSpy
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
    __filename:__filename
    __dirname:__dirname
  }

result = null  
sut = null
mvz 3001, (ready) ->
  sut = this
  if not listenSpy.callCount then notReadySpy()
  ready()

beforeEach ->
  result=null
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
  
xdescribe "named included modules that ovverride previosuly named extensions", ->

  beforeEach ->
    result = sut.extend x:controller:-> @ctx = -> 123
    sut.include x:'./includes/includeoverride'
    
  it "should override existing members", ->
    expect(result.ctx()).toEqual(456)
  
describe "included extension modules", ->
  beforeEach ->
    result = sut.include './includes/includeextension'
    
  it "should be in extension context", ->
    expect(sut.ctx).toHaveBeenCalledWith(result)

  it "should not extend super context", ->
    expect(sut.includeCtx).not.toBeDefined()
  
describe "extended extension modules", ->
  _super=null
  beforeEach ->
    _super = sut.include './includes/includeextension'
    result = sut.include './includes/extendextension'
    
  it "should inherit from super", ->
    expect(result.includeCtx).toBeDefined()

  it "should be in extension context", ->
    expect(sut.ctx).toHaveBeenCalledWith(result)

  it "should not extend super context", ->
    expect(_super.extendCtx).not.toBeDefined()

