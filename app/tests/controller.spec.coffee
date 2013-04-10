path = require "path"
injectr = require "injectr"

emit = {}
setValues = {}

mvz = injectr.call this, path.join(__dirname,"../src/mvz.coffee"),  
  'zappajs': app: (fn) ->
      fn.call
        on:(obj)->emit[k]=v for k,v of obj
        app:
          server:
            listen:->
            address:-> port:3001
          set:(o)-> setValues[k]=v for k,v of o
          get:(k)-> setValues[k]
          enabled:(k) -> if setValues[k] then setValues[k] else false
          enable:(k) -> setValues[k]=true
          settings:env:'test'
  ,{
    console: console
    module:parent:filename:path.join(__dirname,"../src/x")
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
    mvz 3001, (ready) ->
      app=this
      @extend controller:->
        sut = this
        @extend model:->
          @map f1:123
          @on cmd:->
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

