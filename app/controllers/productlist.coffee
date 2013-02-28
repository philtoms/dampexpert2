@include = controller: ->
  # repo filter to take up to first 'count' showcased products
  # returns promise in fetch scope
  showcase = (fetch, count, cb) ->
    fetch ->
      @id 'product'
      @where (v) -> v.isShowcased
      @take count
      cb

  @get ->
    # will render on promise
    showcase @repo.fetch,10 @render
  
  @post (ids) ->
    # create uow in session scope
    @repo.session ->

      showcase @fetch, 10, (p) ->
        p.isShowcased=false
    
        @fetch ids, (p) ->
          p.isShowcased=true
    
  @put (updated) ->
    # use immediate uow
    @repo.fetch @updated.id, p -> 
        p.isShowcased=updated.isShowcased
