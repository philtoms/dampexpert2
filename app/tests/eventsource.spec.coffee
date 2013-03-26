path = require "path"
injectr = require "injectr"

publishSpy = createSpy("publish")
  
sut = injectr "./src/eventsource.coffee",
  'node-uuid':v1:->1
  'store':
      query:(id,cb)-> cb [
        {id:'1/1/msg',f1:1},
        {id:'1/2/msg',f1:2}
      ]
      store:(id,event,cb)->
        console.log event
        publishSpy(id,event)
  ,{
    console: console
  }

ctx = {
    app:
      get:createSpy("get").andReturn("store")
    log:debug:->
    on:(obj) -> obj.msg(123)
    publish:(obj) ->
}

describe "event source wrapper", ->
 
  onSpy = createSpy("on")
  
  it "should require model repository", ->
    expect(ctx.app.get).toHaveBeenCalled()
    
  it "should overload on", ->
    ctx.on msg:onSpy
    expect(onSpy).toHaveBeenCalledWith(123)
    
    
describe "calling event source wrapper", ->
 
  repo = sut.apply ctx,[]
  it "should return model repository interface", ->
    expect(repo.load).toBeDefined()
    expect(repo.store).toBeDefined()

describe "loading from event source", ->
 
  eventSpy = createSpy("event")
  init = {f1:123}
  aggr = {}
  repo = sut.apply ctx,[init,{msg:(e)->@f1=e.f1;eventSpy(e)}]
  repo.load 1,(e,a) -> aggr=a

  it "should call event handlers in model context", ->
    expect(eventSpy.callCount).toEqual(2)
    
  it "should pass correct event", ->
    event = eventSpy.mostRecentCall.args[0] 
    expect(event.id).toEqual('1')
    
  it "should rehydrate aggregate", ->
    expect(aggr.f1).toEqual(2)
    
  it "should not cause initial model to be changed", ->
    expect(init.f1).toEqual(123)
 
 
 describe "event source publish", ->
 
  it "should store correctly formatted events", ->
    ctx.on msg:->@publish msg:{id:1, f1:123}
    
    expect(publishSpy).toHaveBeenCalledWith('1/1/msg',{id:1,f1:123})
