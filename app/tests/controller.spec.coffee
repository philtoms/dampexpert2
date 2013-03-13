path = require "path"
injectr = require "injectr"

ctxSpy = createSpy 'zappa ctx'
ctxOn = null

mvz = injectr.call this, "./src/mvz.coffee",  
  'zappajs': app: (fn) ->
      fn.call
        all:->
        get:->
        enabled:->
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
  ,{
    #console:log: ->
    console: console
    module:parent:filename:path.join(__dirname,"/controller.spec.coffee")
    __filename:__filename
    __dirname:__dirname
  }

sut = null
c1=null
mvz 3001, (ready) ->
  sut = this
  @extend c1:'controller':->
    c1 = this
  ready()

beforeEach ->
  #ctxSpy.reset()
  
xdescribe "model view", ->

  c2 = null
  beforeEach ->
    sut.extend c1:->
      @extend model:->
        @bind 'f1':123,@map
      c2=this
      
  it "should be available in controller as @data", ->
    expect(c2.data.f1).toEqual(123)
