path = require "path"
injectr = require "injectr"

emit = {}
setValues = {}

mvz = injectr.call this, path.join(__dirname,"../src/mvz.coffee"),  
  'zappajs': app: (fn) ->
      fn.call
        enabled:(k) -> if setValues[k] then setValues[k] else false
        enable:(k) -> setValues[k]=true
        disable:(k) -> if setValues[k] then setValues[k]=false
        all:->
        get:->
        on:(obj)->emit[k]=v for k,v of obj
        app:
          server:
            listen:->
            address:->
          set:(o)-> setValues[k]=v for k,v of o
          get:(k)-> setValues[k]
          settings:env:'test'
  ,{
    console: console
    module:parent:filename:path.join(__dirname,"../src/x")
    __filename:__filename
    __dirname:__dirname
  }

sut = null
m1=null
mvz 3001, (ready) ->
  sut = this
  @extend m1:'model':->
    @map f1:123
    @map 'f2'
    @on cmd:-> 
      m1 = this
  ready()
emit.cmd()

beforeEach ->
  sut.enable 'automap events'
  sut.reset()
  sut.viewmodel={}
  vmodel=null
  
describe "model state mappings", ->
 
  it "should be initialised with optional value", ->
    expect(m1.f1).toEqual(123)

  it "should be null if no optional value supplied", ->
    expect(m1.f2).toEqual(null)

describe "extended model", ->

  m2 = null
  beforeEach ->
    sut.extend m1:->
      @map 'f2':'abc'
      @on cmd:-> 
        m2 = this
    emit.cmd()
    
  it "should inherit base model mappings", ->
    expect(m2.f1).toEqual(123)

  it "should override base model mappings", ->
    expect(m2.f2).toEqual('abc')

describe "included extended model", ->

  beforeEach ->
    sut.include '../tests/includes/extendmodel'
    emit['excmd']()
    
  it "should be accessible in calling context", ->
    expect(sut.viewmodel.f1).toEqual('ex1')
    expect(sut.viewmodel.f2).toEqual(456)

describe "publishing without an event handler with automap switched on", ->

  m2 = null
  beforeEach ->
    sut.extend m1:->
      @on cmd:->
        m2 = this
        @publish evnt3:{f2:'def'}
    emit.cmd()
    
  it "should automap mapped properties", ->
    expect(m2.f2).toEqual('def')
    #expect(sut.viewmodel.f2).toEqual('def')
    
describe "publishing without an event handler with automap switched off", ->

  m2 = null
  beforeEach ->
    sut.disable 'automap events'
    sut.extend m1:->
      @on cmd:->
        m2 = this
        @publish evnt3:{f1:'abc'}
    emit.cmd()
    
  it "should not automap to model state", ->
    expect(m2.f1).toEqual(123)
    
  it "should not automap to viewmodel", ->
    expect(sut.viewmodel.f1).toEqual(123)
    
describe "publishing to an explicit event handler", ->

  m2 = null
  beforeEach ->
    sut.extend m1:->
      @on cmd:->
        m2 = this
        @publish evnt:{f1:'abc', f2:'def'}
      @on evnt:->@f2=345
    emit.cmd()
    
  it "should not automap to model state", ->
    expect(m2.f1).toEqual(123)
    
xdescribe "a commanmd with an unknown id", ->

  m2 = null
  beforeEach ->
    sut.extend m1:->
      @on cmd:(d)->
        m2 = this
        @publish evnt:{f1:d.v}
    emit.cmd {v:'abc'}
    emit.cmd {id:78,v:'def'}
      
  it "should log the error and swallow the action", ->
    expect(errors.pop()).toEqual(78)
    expect(m2.f1).toEqual('abc')
    
describe "invoking a model through a commanmd", ->
    
  it "should rehydrate its modelstate", ->
    sut.extend m1:->
      @on cmd: (v)->
        @publish evnt:{f1:'abc'}
      @on evnt:->
        expect(@f1).toEqual('abc')
    emit.cmd()
    
describe "eot", ->
  xit "x", -> console.log id for id of models