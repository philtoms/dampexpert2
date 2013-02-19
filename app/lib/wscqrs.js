(function() {

  this.include = function() {
    var bus, _on;
    bus = this.bus || require('./memory.bus');
    _on = this.on;
    return this.on = function(obj) {
      var k, router, v, ws_handler;
      router = function(obj) {
        console.log("routing " + obj.message);
        bus.subscribe(obj.message, obj.handler);
        return function() {
          var ack, ctx,
            _this = this;
          ack = function() {
            return typeof _this.ack === "function" ? _this.ack({
              message: obj.message,
              time: new Date
            }) : void 0;
          };
          ctx = function(handler, data) {
            _this.data = data;
            return handler.apply(_this);
          };
          this.publish = function(obj, ack) {
            var k, v;
            for (k in obj) {
              v = obj[k];
              console.log("publishing message " + k);
              bus.publish(k, v, ctx, ack);
            }
            return _this.emit(obj);
          };
          return bus.publish(obj.message, this.data, ctx, ack);
        };
      };
      ws_handler = {};
      for (k in obj) {
        v = obj[k];
        ws_handler[k] = router({
          message: k,
          handler: v
        });
        _on(ws_handler);
      }
    };
  };

}).call(this);
