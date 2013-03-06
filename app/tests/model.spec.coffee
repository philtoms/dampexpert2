path = require "path"
injectr = require "injectr"

ctxSpy = createSpy 'zappa ctx'

mvz = injectr "./src/mvz.coffee",  
  {'zappajs':
    app: (fn) ->
      fn.call {
        all:->
        get:->
        ctx:ctxSpy
        server:
          listen:->
          address:->
        app:
          set:->
          settings:env:'test'
      }
  },
  {
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
    m1 = this
  ready()

beforeEach ->
  #ctxSpy.reset()
  
describe "model", ->
 
  it "bindings should be initialised with optional value", ->
    expect(m1.f1).toEqual(123)

  it "viewdata should be accessible in calling context", ->
    expect(sut.data.f1).toEqual(123)

describe "extended model", ->

  m2 = null
  beforeEach ->
    sut.extend m1:->
      @bind 'f2':456
      m2 = this
      
  it "should inherit base model bindings", ->
    expect(m2.f1).toEqual(123)

  it "viewdata should be accessible in calling context", ->
    expect(sut.data.f2).toEqual(456)

