require 'mvz' (ready) ->

  @enable 'defultRouting','eventSourcing'
  
  @extend model:->
    @on purchase:(item) ->
      if inStock item
        @publish purchase_confirmation:item
      
    @on purchase_confirmation:(item) ->
    
  @extend view:->
    @emit purchase:{id:item.id,quantity:2}
    @on purchase_confirmation:(item) ->
      $('body').append "Sale complete: #{@data.transId}"
  ready()
