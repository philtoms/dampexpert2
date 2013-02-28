@include = 'includeextension':->
  @app.ctx this
  @extendCtx = createSpy('extend ctx')