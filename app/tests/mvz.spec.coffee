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
        get:getSpy
        app:
          ctx:ctxSpy
          server:
            listen:listenSpy
            address:-> port:3001
          set:->
          enabled:->
          enable:->
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
    expect(sut.app.ctx).toHaveBeenCalledWith(sut)
    
describe "nested zappa modules included in previously included modules", ->

  beforeEach ->
    sut.include '../tests/includes/includenested'
    
  it "should be in mvz context with immediate access to zappa members", ->
    expect(sut.app.ctx).toHaveBeenCalledWith(sut)
  
describe "included modules that override previosuly named extensions", ->

  beforeEach ->
    sut.extend x:controller:-> 
      @val = 123
      @ctx = -> @app.ctx @val
    sut.include '../tests/includes/includeoverride'
    
  it "should override existing members", ->
    expect(ctxSpy).toHaveBeenCalledWith(456)
    
describe "extended components without internal name", ->
  _ext=null
  beforeEach ->
    sut.include '../tests/includes/extendedcomponent'
    _ext = ctxSpy.calls[0].args[0]

  it "should be named by file name convention", ->
    expect(_ext.name).toEqual('extendedcomponent')
    
describe "extended components with internal names", ->
  beforeEach ->
    debugger
    sut.include '../tests/includes/extendedcomponentwithinternalname'

  it "should have the internal name value as a property", ->
    expect(ctxSpy.calls[0].args[0].name).toEqual('extendedcomponentwithinternalname')
    
describe "components that extend registered components", ->
  _super=null
  _child=null
  beforeEach ->
    sut.include '../tests/includes/extendedcomponent'
    sut.include '../tests/includes/extendregisteredcomponent'
    _super = ctxSpy.calls[0].args[0]
    _child = ctxSpy.calls[1].args[0]

  it "should inherit from extension point", ->
    expect(_child.includeCtx).toBeDefined()

  it "should be in extension context", ->
    expect(sut.app.ctx).toHaveBeenCalledWith(_child)

  it "should not extend extension point context", ->
    expect(_super.extendCtx).not.toBeDefined()

describe "nested extension points", ->
  nameSpy = createSpy('name')
  beforeEach ->
    sut.extend ext1:viewmodel:-> @p1=1;nameSpy @name
    sut.extend ext2:viewmodel:-> @p2=2;nameSpy @name
    sut.extend ext3:viewmodel:-> @p3=3;nameSpy @name
    
  it "should progresively update the component name", ->
    sut.extend ext1:ext2:ext3:->
    expect(nameSpy).toHaveBeenCalledWith('ext1')
    expect(nameSpy).toHaveBeenCalledWith('ext2')
    expect(nameSpy).toHaveBeenCalledWith('ext3')

  it "should all be included in the component", ->
    ext=null
    sut.extend ext1:ext2:ext3:-> ext=this
    expect(ext.p1).toBeDefined()
    expect(ext.p2).toBeDefined()
    expect(ext.p3).toBeDefined()

describe "registered components", ->
  beforeEach ->
    sut.include '../tests/includes/registeredcomponent'
    
  it "should be extensible", ->
    ext=null
    sut.extend registeredcomponent:-> ext=this
    expect(ext.f1).toEqual(1)

describe "registered components that override previouly registered components", ->
  beforeEach ->
    sut.include '../tests/includes/registeredcomponent'
    sut.include '../tests/includes/overrideregisteredcomponent'
    
  it "should be extensible", ->
    ext=null
    sut.extend registeredcomponent:-> ext=this
    expect(ext.f1).toEqual(2)

