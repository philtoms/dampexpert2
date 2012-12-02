product = null

describe "creating a new product", ->

  beforeEach ->
    product = 
      id: 1
      name: "p1"
    console.log product
      
  it "should have an id", ->
    expect(product.id).toEqual(1)