path = require "path"
injectr = require "injectr"

ctxSpy = createSpy 'zappa ctx'
emit = {}
setValues = {}

mvz = injectr.call this, "./src/mvz.coffee",  
  'zappajs': app: (fn) ->
      fn.call
        enabled:(k) -> setValues[k]?
        enable:(k) -> setValues[k]=true
        disable:(k) -> delete setValues[k]?
        all:->
        get:->
        on:(obj)->emit[k]=v for k,v of obj
        ctx:ctxSpy
        server:
          listen:->
          address:->
        app:
          set:(o)-> setValues[k]=v for k,v of o
          get:(k)-> setValues[k]
          settings:env:'test'
          bus:require path.join(__dirname, '../src/memory-bus')
   './ws-cqrs': require('../src/ws-cqrs')  
   './memory-bus': require('../src/memory-bus')  
   './eventsource': require('../src/eventsource')  
  ,{
    #console:log: ->
    console: console
    module:parent:filename:path.join(__dirname,"/model.spec.coffee")
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
emit['cmd']()

beforeEach ->
  sut.disable 'automap events'
  #ctxSpy.reset()
  
describe "model mappings", ->
 
  it "should be initialised with optional value", ->
    expect(m1.f1).toEqual(123)

  it "should be null if no optional value supplied", ->
    expect(m1.f2).toEqual(null)

describe "viewmodel data", ->
 
  it "should be accessible in calling context", ->
    expect(sut.viewmodel.f1).toEqual(123)
    expect(sut.viewmodel.f2).toEqual(null)

describe "extended model", ->

  m2 = null
  beforeEach ->
    sut.extend m1:->
      @map 'f2':'abc'
      @on cmd2:-> 
        m2 = this
    emit['cmd2']()
    
  it "should inherit base model mappings", ->
    expect(m2.f1).toEqual(123)

  it "should override base model mappings", ->
    expect(m2.f2).toEqual('abc')

describe "implicit event handler", ->

  m3 = null
  beforeEach ->
    sut.extend m1:->
      @on cmd3:->
        m3 = this
        @publish evnt3:{f2:'def'}
    emit['cmd3']()
    
  it "should automap mapped properties", ->
    expect(m3.f2).toEqual('def')
    expect(sut.viewmodel.f2).toEqual('def')
    

describe "explicit event handler", ->

  m4 = null
  beforeEach ->
    sut.extend m1:->
      @on cmd4:->
        m4 = this
        @publish evnt4:{f1:'abc'}
      @on evnt4:->@f2='def'
    emit['cmd4']()
    
  it "should not automap event properties", ->
    expect(m4.f1).toEqual(123)
    expect(sut.viewmodel.f2).toEqual('def')
