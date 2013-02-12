module.exports = (opts) ->
  queue = opts.qadaptor || require './memory.qadaptor'
  log = opts.log || {debug:->,info:->,error:->}
  zappa = opts.zappa
  idempotent = (opts.idempotent? opts.idempotent) || true
  
  _on = zappa.on
    # http://stackoverflow.com/questions/8832414/overriding-socket-ios-emit-and-on/9674248#9674248
  (->
    emit = zappa.socket.emit
    zappa.socket.emit = ->
      emit.apply socket, arguments_

    $emit = zappa.socket.$emit
    zappa.socket.$emit = ->
      $emit.apply socket, arguments_
  )()

  # queue incomming commands
  zappa.on '*': ->
      queue.push @data

  cqrs = 
    
    emit: (msg) ->
      zappa.emit msg