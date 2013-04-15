(function() {
  var fs, mvz, path, zappa;

  fs = require('fs');

  path = require('path');

  zappa = require('zappajs');

  mvz = function(startApp) {
    var base, basename, bus, extensions, iocContainer, loadQ, onload, ready, root;
    this.version = '0.1.2';
    base = this;
    root = path.dirname(module.parent.filename);
    basename = function(name) {
      return path.basename(path.basename(name || __filename, '.coffee'), '.js');
    };
    bus = null;
    extensions = {};
    iocContainer = {};
    loadQ = [];
    this.include = function(name) {
      var k, obj, sub, v, _ref;
      obj = name;
      if (typeof obj !== 'object') {
        obj = {};
        obj[basename(name)] = name;
      }
      for (k in obj) {
        v = obj[k];
        sub = require(path.join(root, v));
        if (sub.extend) {
          obj[k] = sub.extend;
          this.extend(obj);
        }
        if (sub.include) {
          if (typeof sub.include === 'object') {
            _ref = sub.include;
            for (k in _ref) {
              v = _ref[k];
              extensions[k] = v;
            }
            return;
          }
          sub.include.apply(this);
        }
      }
    };
    this.extend = function(obj) {
      var extend,
        _this = this;
      extend = function(obj, ctx, nestName) {
        var ctor, extension, name;
        for (name in obj) {
          ctor = obj[name];
          if (name === nestName) return extend.call(this, ctor, ctx, name);
          if (name === 'inject') {
            iocContainer[(ctx != null ? ctx.name : void 0) || 'ioc' + iocContainer.length] = ctor;
            return ctx;
          }
          extension = extensions[name];
          if (ctx) {
            if (extension) {
              extension.apply(ctx, [base, this]);
            } else {
              ctx.name = name;
            }
            if (typeof ctor === 'object') {
              return extend.call(this, ctor, ctx, name);
            }
            ctor.apply(ctx);
            return ctx;
          }
          ctx = {
            constructor: function(container) {
              var ioc, k, verb, _i, _len, _ref;
              this.name = name;
              this.app = base.app;
              _ref = ['include', 'extend'];
              for (_i = 0, _len = _ref.length; _i < _len; _i++) {
                verb = _ref[_i];
                this[verb] = base[verb];
              }
              for (k in iocContainer) {
                ioc = iocContainer[k];
                ioc.call(this, base);
              }
              if (extension) extension.apply(this, [base, container]);
              if (typeof ctor === 'object') {
                return extend.call(container, ctor, this, name);
              }
              ctor.apply(this);
              return this;
            }
          };
          if (!extensions[name]) extensions[name] = ctx.constructor;
          return new ctx.constructor(this);
        }
      };
      onload(function() {
        return extend.call(_this, obj);
      });
    };
    onload = function(fn) {
      return loadQ.push(fn);
    };
    base.include('./lib/controller');
    base.include('./lib/viewmodel');
    base.include('./lib/model');
    base.include('./lib/eventsource');
    base.include('./lib/log');
    this.app.enable('cqrs');
    this.app.enable('automap events');
    this.app.set('cqrs', './ws-cqrs');
    this.app.set('bus', './memory-bus');
    this.app.set('model-store', './memory-store');
    ready = function(port) {
      var fn;
      loadQ.shift()();
      iocContainer.log.apply(base, [base]);
      if (this.enabled('cqrs')) {
        bus = require(this.settings['bus']);
        require(this.settings['cqrs']).call(base, bus);
        bus.log = base.log;
      }
      while (fn = loadQ.shift()) {
        fn();
      }
      onload = function(fn) {
        return fn();
      };
      this.listen(port);
      return base.log.info('Express server listening on port %d in %s mode', port, this.settings.env);
    };
    return startApp.apply(this, [ready]);
  };

  module.exports = function(port, app) {
    if (!app) {
      app = port;
      port = 3000;
    }
    return zappa.app(function() {
      var startApp, zapp;
      zapp = this;
      return mvz.call(zapp, startApp = function(ready) {
        var startServer;
        return app.call(zapp, startServer = function() {
          return ready.call(zapp.app, port);
        });
      });
    });
  };

}).call(this);
