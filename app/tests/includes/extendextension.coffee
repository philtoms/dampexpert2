@include = 'includeextension':->
  @app.zappaCtx this
  @extendCtx = createSpy('extend ctx')