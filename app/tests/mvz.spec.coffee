path = require "path"
injectr = require "injectr"

logSpy = createSpy("log").andReturn null
listenSpy = createSpy "listen"
notReadySpy = createSpy "not ready"
getSpy = createSpy 'get'
ctxSpy = createSpy 'zappa ctx'

mvz = injectr "./src/mvz.coffee",  
  'zappajs':app: (fn) ->
      fn.call
        enabled:->
        get:getSpy
        ctx:ctxSpy
        app:
          server:
            listen:listenSpy
            address:->
          set:->
          get:logSpy
          settings:env:'test'
          include:->
  ,{
    console: console
    module:parent:filename:path.join(__dirname,"../src/x")
    __filename:__filename
    __dirname:__dirname
  }

sut = null
beforeEach ->
  getSpy.reset()
  ctxSpy.reset()
  mvz 3001, (ready) ->
    sut = this
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

  it "should have established logging", ->
    expect(logSpy).toHaveBeenCalledWith('loglevel')
    
describe "included zappa modules", ->

  beforeEach ->
    sut.include '../tests/includes/includezappa'
    
  it "should be in mvz context with immediate access to zappa members", ->
    expect(sut.ctx).toHaveBeenCalledWith(sut)
    
describe "nested zappa modules included in previously included modules", ->

  beforeEach ->
    sut.include '../tests/includes/includenested'
    
  it "should be in mvz context with immediate access to zappa members", ->
    expect(sut.ctx).toHaveBeenCalledWith(sut)
  
describe "included modules that override previosuly named extensions", ->

  beforeEach ->
    sut.extend x:controller:-> 
      @val = 123
      @ctx = -> @app.ctx @val
    sut.include '../tests/includes/includeoverride'
    
  it "should override existing members", ->
    expect(ctxSpy).toHaveBeenCalledWith(456)
    
describe "extensions", ->
  _ext=null
  beforeEach ->
    sut.include '../tests/includes/includeextension'
    _ext = ctxSpy.calls[0].args[0]

  it "should be named", ->
    expect(_ext.name).toEqual('includeextension')
    
describe "extensions with name overrides", ->
  _ext=null
  beforeEach ->
    sut.include '../tests/includes/includeextensionwithnameoverride'
    _ext = ctxSpy.calls[0].args[0]

  it "should have the override name", ->
    expect(_ext.name).toEqual('nameoverride')
    
describe "extension modules that extend extension point modules", ->
  _super=null
  _child=null
  beforeEach ->
    sut.include '../tests/includes/includeextension'
    sut.include '../tests/includes/extendincludeextension'
    _super = ctxSpy.calls[0].args[0]
    _child = ctxSpy.calls[1].args[0]

  it "should inherit from extension point", ->
    expect(_child.includeCtx).toBeDefined()

  it "should be in extension context", ->
    expect(sut.ctx).toHaveBeenCalledWith(_child)

  it "should not extend extension point context", ->
    expect(_super.extendCtx).not.toBeDefined()

describe "nested extention points", ->
  beforeEach ->
    sut.extend p1:viewmodel:-> @f1=1
    sut.extend p2:viewmodel:-> @f2=2
    sut.extend p3:viewmodel:-> @f3=3
    
  it "should all be included in extenstion", ->
    ext=null
    sut.extend p1:p2:p3:-> ext=this
    expect(ext.f1).toBeDefined()
    expect(ext.f2).toBeDefined()
    expect(ext.f3).toBeDefined()
