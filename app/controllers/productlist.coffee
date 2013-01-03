@extend = controller: ->
  # repo filter to take up to first 'count' showcased products
  # returns promise in fetch scope
  showcase = fetch, count ->
    fetch
      @id 'product',
      @where v -> v.isShowcased,
      @take count

  @get = ->
    # will render on promise
    @render(showcase @repo.fetch,10)
  
  @post = ids ->
    # create uow in session scope
    @repo.session ->

      showcase(@fetch,10, data ->
        data.each p ->
          p.isShowcased=false
    
        @fetch ids, data ->
          data.each p ->
            p.isShowcased=true
    
  @put = updated ->
    # use immediate uow
    @repo.fetch updated.id, v -> 
        v.isShowcased=updated.isShowcased
