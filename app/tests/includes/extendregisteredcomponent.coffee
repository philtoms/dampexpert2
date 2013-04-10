@extend = 'extendedcomponent':->
  @val = 456
  @app.ctx this
  @extendCtx = createSpy('extend ctx')