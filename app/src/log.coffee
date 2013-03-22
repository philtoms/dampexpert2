# default all logs to console
level = 1
log = console.log
for k,v of {'debug':0,'info':1,'warn':2,'error':3}
  do (k,v) ->
    log[k] = -> (console[k] || log).apply null, arguments if v>=level

@extend = inject: (base) ->
  @log = log
  level= base.app.get 'loglevel' || 1
