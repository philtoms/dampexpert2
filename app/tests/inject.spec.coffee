path = require "path"
injectr = require "injectr"

mvz = injectr "./src/mvz.coffee",  
  'zappajs':app: (fn) ->
      fn.call
        enabled:->
        app:
          set:->
          get:->
          settings:env:'test'
          include:->
          server:
            listen:->
            address:->
  ,{
    console: console
    module:parent:filename:path.join(__dirname,"/mvz.spec.coffee")
    __filename:__filename
    __dirname:__dirname
  }

sut = null
mvz 3001, (ready) ->
  sut = this
  ready()

describe "ioc container", ->
 
  it "should inject ioc extensions", ->
    sut.extend inject:->@x=->
    sut.extend viewmodel:->
      expect(@x).toBeDefined()
      
  it "should inject included ioc extensions", ->
    sut.include './includes/includeinject'
    sut.extend viewmodel:->
      expect(@x).toBeDefined()
      
  it "should inject extensions that override default behaviour", ->
    sut.extend inject:->
      @x=->''
      @log = (m) -> @x = m
      @log 'xyz'
    sut.extend viewmodel:->
      expect(@x).toEqual('xyz')