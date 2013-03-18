path = require "path"
injectr = require "injectr"

emit = {}
setValues = {}

mvz = injectr.call this, path.join(__dirname,"../src/mvz.coffee"),  
  'zappajs': app: (fn) ->
      fn.call
        enabled:(k) -> if setValues[k] then setValues[k] else false
        enable:(k) -> setValues[k]=true
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
mvz 3001, (ready) ->
  sut = this
  @extend m1:model:->
    @map f1:123
    @map f2:456
    @on cmd:->
      @publish evnt:789
  ready()

beforeEach ->
  sut.reset()
  
describe "viewmodels", ->
 
  it "should subscribe to model events", ->
    sut.extend viewmodel:->
      @on evnt:(d)->
        expect(d).toEqual(789)
    emit.cmd()    
