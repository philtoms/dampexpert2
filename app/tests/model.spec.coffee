path = require "path"
injectr = require "injectr"
allSpy = createSpy("all")
getSpy = createSpy("get")
mvz = injectr "./lib/mvz.js", 
  {'model':
    ->
   'zappajs':
    app: (fn) ->
      fn.call { 
        all:allSpy
        get:getSpy
        server:
          listen:->
          address:->
        app:
          set:->
          settings:env:'test'
      }
  },
  {
    console:{log:=>}
    module:parent:filename:'./'
  }

sut = mvz 3001, (ready) ->
  ready()

describe "routing directly to a model", ->
  result = null
  beforeEach ->
    for k,v of allSpy.mostRecentCall.args[0]
      v.call {
        next:->
        params:['/model']
      }

  it "should register a default controller", ->
    expect(getSpy.argsForCall[0][0]).toEqual('/model')
    expect(typeof getSpy.argsForCall[0][1]).toEqual('function')
