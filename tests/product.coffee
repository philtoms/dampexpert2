jasmine = require('jasmine-node')

product = {}

describe "creating a new product", ->

  beforeEach ->
    product = 
      id: 1
      name: "p1"
      
  it "should have an id", ->
    expect(product.id).toBe "p1"