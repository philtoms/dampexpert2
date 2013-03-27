path = require "path"
injectr = require "injectr"

storeSpy = createSpy("store")
uuid=0

sut = injectr "./src/eventsource.coffee",
  'node-uuid':v1:->++uuid
  'memory-store':
      query:(id,cb)-> cb null,[
        {id:'1/1/msg',f1:1},
        {id:'1/2/msg',f1:2}
      ]
      store:(id,event,cb)->
        storeSpy(id,event)
  ,{
    console: console
  }
  
ctx=null
beforeEach ->
  ctx = {
    app:
      get:createSpy("get").andReturn("memory-store")
    log:debug:->
    publish:(obj) ->
    on: (obj) -> obj.msg.call this,123
  }

describe "event source wrapper", ->
 
  onSpy = createSpy("on")
  beforeEach ->
    sut.apply ctx,[]
    
  it "should require model repository", ->
    expect(ctx.app.get).toHaveBeenCalled()
    
  it "should overload on", ->
    ctx.on msg:onSpy
    expect(onSpy).toHaveBeenCalledWith(123)
    
    
describe "calling event source wrapper", ->
 
  repo = null
  beforeEach ->
    repo = sut.apply ctx,[]
  
  it "should return model repository interface", ->
    expect(repo.load).toBeDefined()
    expect(repo.store).toBeDefined()

describe "loading from event source", ->
 
  eventSpy = createSpy("event")
  init = {f1:123}
  aggr = {}
  
  beforeEach ->
    repo = sut.apply ctx,[init,{msg:(e)->@f1=e.f1;eventSpy(e)}]
    repo.load 1,(e,a) -> aggr=a

  it "should call event handlers in model context", ->
    expect(eventSpy.callCount).toEqual(2)
    
  it "should pass corrected event", ->
    event = eventSpy.mostRecentCall.args[0] 
    expect(event.id).toEqual('1')
    
  it "should rehydrate aggregate", ->
    expect(aggr.f1).toEqual(2)
    
  it "should not cause initial model to be changed", ->
    expect(init.f1).toEqual(123)
 
 
 describe "event source publish", ->

  beforeEach ->
    repo = sut.apply ctx,[]
  
  it "should store correctly formatted events", ->
    uuid=0
    ctx.on msg:->@publish msg:{id:1, f1:123}
    ctx.on msg:->@publish msg:{id:1, f1:456}
    
    expect(storeSpy).toHaveBeenCalledWith('1/1/msg',{id:1,f1:123})
    expect(storeSpy).toHaveBeenCalledWith('1/2/msg',{id:1,f1:456})
