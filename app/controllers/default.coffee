@include = controller: ->

  @include 'header'
  @include 'main':-> # placeholder
  @include 'footer' 

  @get ->
    
    @render()
