@extend = controller: ->

  @include 'header'
  @include 'main' # placeholder
  @include 'footer' 

  @get ->
    
    @render()
  
  return this # to register as extension