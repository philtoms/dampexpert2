path = require "path"
injectr = require "injectr"

emit = {}
setValues = env:'test'

mvz = injectr path.join(__dirname,"../lib/mvz.js"),  
  'zappajs': app: (fn) ->
      fn.call
        all:->
        get:->
        on:(obj)->emit[k]=v for k,v of obj
        app:
          listen:->
          settings:setValues
          set:(k,v)-> setValues[k]=v
          get:(k)-> setValues[k]
          enabled:(k) -> if setValues[k] then setValues[k] else false
          enable:(k) -> setValues[k]=true
          disable:(k) -> if setValues[k] then setValues[k]=false
  ,{
    console: console
    module:parent:filename:path.join(__dirname,"../x")
    __filename:__filename
    __dirname:__dirname
  }

sut = null
m1=null
mvz (ready) ->
  sut = this
  @extend m1:'model':->
    @map f1:123
    @map 'f2'
    @on cmd:-> 
      m1 = this
  ready()
emit.cmd()

beforeEach ->
  sut.app.enable 'automap events'
  sut.reset()
  sut.viewmodel={}
  
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

describe "extended eventsource model", ->

  it "should auto-enable eventsourcing", ->
    sut.extend eventsource:m1:->
      expect(@eventsourcing).toBeDefined()
    
    
describe "included extended model", ->

  beforeEach ->
    sut.include '../app/tests/includes/extendmodel'
    emit.excmd()
    
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
    sut.app.disable 'automap events'
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
    
describe "a commanmd with an unknown id", ->

  m2 = null
  beforeEach ->
    sut.extend m1:->
      @on cmd:(d)->
        @publish evnt:{f1:d.v}
    emit.cmd {id:78,v:'def'}
      
  xit "should log the error and swallow the action", ->
    expect(errors.pop()).toEqual(78)
    
describe "invoking a model through a commanmd", ->

  done=false
  it "should rehydrate its model state", (next) ->
    sut.extend m1:->
      @on cmd1: ->
        @f1='abc'
        @publish evnt:""
      @on cmd2:->
        expect(@f1).toEqual('abc')
        done=true
    emit.cmd1()
    emit.cmd2()
    process.nextTick ->
      if done then next()

describe "model state", ->
    
  done=false
  it "should be maintained through command scope", (next) ->
    sut.extend m1:->
      @on cmd: ->
        @publish evnt1:""
      @on evnt1:(e)->
        @f1='abc'
        @publish evnt2:""
      @on evnt2:->
        expect(@f1).toEqual('abc')
        done=true
    emit.cmd()
    process.nextTick ->
      if done then next()

describe "invoking an event sourced model through a commanmd", ->
 
  done=false
  it "should rehydrate its model state", (next) ->
    sut.extend eventsource:m1:->
      @on cmd1: ->
        @publish evnt:f1:'abc'
      @on evnt:(e)->
        @f1=e.f1
      @on cmd2:->
        expect(@f1).toEqual('abc')
        done=true
    emit.cmd1()
    emit.cmd2()
    process.nextTick ->
      if done then next()

describe "invoking an automapped event sourced model through a command", ->

  done = false
  it "should rehydrate its model state", (next) ->
    sut.extend eventsource:m1:->
      @on cmd1: ->
        @publish evnt:f1:'abc'
      @on cmd2:->
        expect(@f1).toEqual('abc')
        done=true
    emit.cmd1()
    emit.cmd2()
    process.nextTick ->
      if done then next()

