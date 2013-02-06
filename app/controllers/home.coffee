@extend = controller: ->

  @include 'header'
  @include 'main' # placeholder
  @include 'footer' 

  @index ->
    
    @render()