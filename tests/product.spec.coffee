fake = require "injectr"
product = fake "tests/product.coffee",
  fs1: (x) -> x+x

describe "creating a new product", ->

  beforeEach ->
    console.log product
      
  it "should have an id", ->
    expect(product.id).toEqual(1)