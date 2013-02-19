path = require "path"
injectr = require "injectr"

logSpy = createSpy "log"
listenSpy = createSpy "listen"
notReadySpy = createSpy "not ready"

mvz = injectr "./lib/mvz.js",  
  {'zappajs':
    app: (fn) ->
      fn.call {
        all:->
        get:->
        server:
          listen:listenSpy
          address:->
        app:
          set:->
          settings:env:'test'
      }
  },
  {
    console:log: ->
    module:parent:filename:path.join(__dirname,"/mvz.spec.coffee")
  }

sut = mvz 3001, (ready) ->
  if not listenSpy.callCount then notReadySpy()
  ready()

describe "intitialized application", ->

  it "should not have started listening until app ready", ->
    expect(notReadySpy).toHaveBeenCalled()

  it "should have inheritted zappa.app", ->
    expect(sut.get).toBeDefined()
    
describe "ready application", ->

  it "should be listening on expected port", ->
    expect(listenSpy).toHaveBeenCalledWith(3001)

describe "include", ->

  it "should be able to load zappa modules", ->
    expect(listenSpy).toHaveBeenCalledWith(3001)
 
  it "should be able to load extension modules", ->
    expect(listenSpy).toHaveBeenCalledWith(3001)
 
  it "should be able to extend extension modules", ->
    expect(listenSpy).toHaveBeenCalledWith(3001)

  it "extensions should have inheritted zappa.app", ->
    expect(listenSpy).toHaveBeenCalledWith(3001)