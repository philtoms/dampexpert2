(function() {
  var uuid;

  uuid = require('node-uuid');

  this.include = function() {
    var _on;
    _on = this.on;
    return this.on = function(obj) {
      var es_handler, k, router, v, _results;
      router = function(obj) {
        console.log("es wrapping " + obj.message);
        return function() {
          var _publish;
          _publish = this.publish;
          this.publish = function(obj, cb) {
            var evntKey, k, v, _results;
            _publish.apply(this, [obj, cb]);
            _results = [];
            for (k in obj) {
              v = obj[k];
              if (!(k.id != null)) {
                evntKey = {
                  event: k,
                  id: uuid.v4()
                };
                if (!v.id) {
                  v.id = uuid.v4();
                }
                _results.push(console.log("storing " + k + "," + evntKey.id + " : " + v));
              } else {
                _results.push(console.log("already stored " + k + "," + evntKey.id + " : " + v));
              }
            }
            return _results;
          };
          return obj.handler.apply(this);
        };
      };
      es_handler = {};
      _results = [];
      for (k in obj) {
        v = obj[k];
        es_handler[k] = router({
          message: k,
          handler: v
        });
        _results.push(_on(es_handler));
      }
      return _results;
    };
  };

}).call(this);
