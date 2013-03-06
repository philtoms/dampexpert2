@include = 'controller':->
  @val = 123
  @app.ctx this
  @includeCtx = createSpy('include Ctx')
  