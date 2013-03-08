path = require "path"
injectr = require "injectr"

ctxSpy = createSpy 'zappa ctx'
ctxOn = null

mvz = injectr.call this, "./src/mvz.coffee",  
  'zappajs': app: (fn) ->
      fn.call
        all:->
        get:->
        on:(obj)->ctxOn=obj
        ctx:ctxSpy
        server:
          listen:->
          address:->
        app:
          set:->
          settings:env:'test'
          bus:require path.join(__dirname, '../src/memory-bus')
          include:(p)->
            sub = require path.join(__dirname, '../src',p)
            sub.include.apply(this, [this])    
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
    @bind 'f1':123
    @bind 'f2'
    m1 = this
  ready()

beforeEach ->
  #ctxSpy.reset()
  
describe "model bindings", ->
 
  it "should be initialised with optional value", ->
    expect(m1.f1).toEqual(123)

  it "should be null if no optional value supplied", ->
    expect(m1.f2).toEqual(null)

describe "model viewdata", ->
 
  it "should be accessible in calling context", ->
    expect(sut.data.f1).toEqual(123)

describe "extended model", ->

  m2 = null
  beforeEach ->
    sut.extend m1:->
      @bind 'f2':456,
      m2 = this
      
  it "should inherit base model bindings", ->
    expect(m2.f1).toEqual(123)

  it "should override base model bindings", ->
    expect(m2.f2).toEqual(456)

  it "viewdata should be accessible in calling context", ->
    expect(sut.data.f2).toEqual(456)

describe "auto mapping", ->

  m3 = null
  beforeEach ->
    sut.extend m1:->
      @bind 'f2':456,@map
      @on cmd3:->
        @publish evnt3:{f1:'abc',f2:'def'}
      m3 = this
    ctxOn.cmd3()
    
  it "should only map flagged properties", ->
    expect(m3.f2).toEqual('def')
    expect(m3.f1).toEqual(123)
