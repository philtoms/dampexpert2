path = require "path"
injectr = require "injectr"

emit = {}
setValues = env:'test'
 
mvz = injectr.call this, path.join(__dirname,"../lib/mvz.js"),  
  'zappajs': app: (fn) ->
      fn.call
        on:(obj)->emit[k]=v for k,v of obj
        app:
          listen:->
          set:(k,v)-> setValues[k]=v
          get:(k)-> setValues[k]
          enabled:(k) -> if setValues[k] then setValues[k] else false
          enable:(k) -> setValues[k]=true
          settings:setValues
  ,{
    console: console
    module:parent:filename:path.join(__dirname,"../x")
    __filename:__filename
    __dirname:__dirname
  }

sut = null
done=false
tloop = ->
  if done
    done() 
  else 
    process.nextTick tloop

describe "viewmodels", ->

  beforeEach ->
    done=false
    mvz (ready) ->
      @extend viewmodel:->
        sut = this
        @extend model:->
          @map f1:123
          @on cmd:->
            @publish evnt:f1:789
      ready()
      
  it "should subscribe to model events", (next) ->
    sut.on evnt:(d)->
      expect(d.f1).toEqual(789)
      done=next
    emit.cmd()
    tloop()
    
  it "should auto-map onto locally scoped models", (next) ->
    sut.on evnt:->
      expect(@viewmodel.f1).toEqual(789)
      done=next
    emit.cmd()    
    tloop()
