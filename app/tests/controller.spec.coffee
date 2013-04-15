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

app = null
sut = null
sut_vm = null
done=false
tloop = ->
  if done
    done() 
  else 
    process.nextTick tloop

describe "controllers as containers", ->

  beforeEach ->
    done=false
    debugger
    mvz (ready) ->
      app=this
      @extend controller:->
        sut = this
        debugger
        @extend model:->
          @map f1:123
          @on cmd:->
            debugger
            @publish evnt:f1:789
        @extend viewmodel:->
          sut_vm = this
      ready()

  it "should auto-map viewmodel onto locally scoped models", (next) ->
    app.on evnt:->
      expect(sut.viewmodel.f1).toEqual(789)
      done=next
    emit.cmd()    
    tloop()
    
  it "should auto-map same scope viewmodels onto locally scoped models", (next) ->
    app.on evnt:->
      expect(sut_vm.viewmodel.f1).toEqual(789)
      done=next
    emit.cmd()    
    tloop()

