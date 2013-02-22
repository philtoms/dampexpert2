(function() {
  var exchange, uuid;

  uuid = require('node-uuid');

  exchange = {};

  module.exports = {
    publish: function(msg, data, ctx, ack) {
      var wrapper, _i, _len, _ref, _results;
      if (typeof ack === "function") ack();
      _ref = exchange[msg];
      _results = [];
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        wrapper = _ref[_i];
        console.log("publishing " + msg + " to handler " + wrapper.id);
        _results.push(ctx(wrapper.handler, data));
      }
      return _results;
    },
    subscribe: function(msg, handler) {
      var wrapper;
      wrapper = {
        id: uuid.v4(),
        handler: handler
      };
      if (!exchange[msg]) {
        exchange[msg] = [wrapper];
      } else {
        exchange[msg].push(wrapper);
      }
      return console.log("handler " + wrapper.id + " subscribing to " + msg);
    }
  };

}).call(this);
