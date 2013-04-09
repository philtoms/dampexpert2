path = require "path"
injectr = require "injectr"

storeSpy = createSpy("store")
setValues = {}

sut = injectr "./src/eventstore.coffee",
  'memory-store':
      loadAll:(id,cb)-> cb null,[
        {id:'1/1/msg',payload:{id:'1',f1:1}},
        {id:'1/2/msg',payload:{id:'1',f1:2}},
        {id:'2/1/evnt1',payload:{id:'1',f1:1}}
        {id:'2/2/evnt2',payload:{id:'1',f1:2}}
      ].filter (x) -> x.id[0]==''+id
      store:(id,event,cb)->
        storeSpy(id,event)
      hasState:->false
  ,{
    console: console
  }
  
ctx=null
beforeEach ->
  storeSpy.reset()
  ctx = {
    app:
      get:createSpy("get").andReturn("memory-store")
      enabled:(k) -> if setValues[k] then setValues[k] else false
      enable:(k) -> setValues[k]=true
    log:debug:->
    publish:->
    on: (obj) -> obj.msg.call this,{f1:123}
  }

describe "event source wrapper", ->
 
  repo = null
  onSpy = createSpy("on")
  beforeEach ->
    repo = sut.apply ctx,[{},{}]
    repo.store()
    
  it "should require model repository", ->
    expect(ctx.app.get).toHaveBeenCalled()
    
  it "should wrap model on handler", ->
    ctx.on msg:onSpy
    expect(onSpy).toHaveBeenCalledWith(f1:123)
        
  it "should return model repository interface", ->
    expect(repo.load).toBeDefined()
    expect(repo.store).toBeDefined()

describe "loading an aggregate from event source", ->
 
  eventSpy = createSpy("event")
  init = {f1:123}
  aggr = {}
  
  beforeEach ->
    # initialize es with initial value and handlers
    repo = sut.apply ctx,[init,{msg:(e)->@f1=e.f1;eventSpy(e)}]
    repo.load 1,(err,a) -> aggr=a

  it "should call event handlers in model context", ->
    expect(eventSpy.callCount).toEqual(2)
    
  it "should pass corrected event", ->
    event = eventSpy.mostRecentCall.args[0] 
    expect(event.id).toEqual('1')
    
  it "should rehydrate aggregate", ->
    expect(aggr.f1).toEqual(2)
    
  it "should not cause initial model to be changed", ->
    expect(init.f1).toEqual(123)
 
 
describe "event source publish events", ->

  beforeEach ->
    repo = sut.apply ctx,[{},{}]
    ctx.on msg:->@publish evnt1:{id:2, f1:123}
    ctx.on msg:->@publish evnt2:{id:2, f1:456}
    repo.store()
      
  it "should be stored correctly formatted", ->
    expect(storeSpy.callCount).toEqual(2)
    expect(storeSpy).toHaveBeenCalledWith('2/1/evnt1',{id:'2/1/evnt1',payload:{id:2,f1:123}})
    expect(storeSpy).toHaveBeenCalledWith('2/2/evnt2',{id:'2/2/evnt2',payload:{id:2,f1:456}})

  it "should be stored in sequence order", ->
    expect(storeSpy.calls[0].args[0]).toEqual('2/1/evnt1')
    expect(storeSpy.calls[1].args[0]).toEqual('2/2/evnt2')
    
describe "reloaded event source publish events", ->

  repo=null
  hydratingCount=0
  beforeEach ->
    repo = sut.apply ctx,[{},{
      evnt1:(e)->hydratingCount++ if @hydrating
      evnt2:(e)->hydratingCount++ if @hydrating
    }]
      
  it "should be in a hydrating state", ->

    repo.load 2,->
    expect(hydratingCount).toEqual(2)
    
  it "should not be restored when published", ->
    ctx.on msg:->@hydrating=true;@publish evnt1:{id:2, f1:123}
    ctx.on msg:->@hydrating=true;@publish evnt2:{id:2, f1:456}

    expect(storeSpy.callCount).toEqual(0)
    
describe "nested event source publish events", ->

  repo=null
  eventSpy = createSpy("event")
  beforeEach ->
    ctx.on = (obj) -> 
      obj.msg?.call this,{f1:123}
      obj.evnt1?.call this,{f1:456}
      obj.evnt2?.call this,{f1:789}
    ctx.publish = eventSpy

    repo = sut.apply ctx,[{},{}]
  
  it "should not be called when hydrating", ->
    ctx.on msg:->@publish evnt1:{id:2, f1:123}
    ctx.on evnt1:->@hydrating=true;@publish evnt2:{id:2, f1:456}

    expect(eventSpy.callCount).toEqual(1)

  it "should be stored in nested sequence order", ->
    ctx.on msg:->@publish evnt1:{id:2, f1:123}
    ctx.on evnt1:->@publish evnt2:{id:2, f1:456}    
    repo.store()
    
    expect(storeSpy.calls[0].args[0]).toEqual('2/1/evnt1')
    expect(storeSpy.calls[1].args[0]).toEqual('2/2/evnt2')
    
