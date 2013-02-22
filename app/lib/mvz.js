(function() {
  var fs, mvz, path, zappa,
    __slice = Array.prototype.slice;

  fs = require('fs');

  path = require('path');

  zappa = require('zappajs');

  mvz = function(ready) {
    var base, extensions, root, routes;
    this.version = '0.1.1';
    root = path.dirname(module.parent.filename);
    base = this;
    base.app.set("views", path.join(root, "views"));
    routes = {};
    extensions = {};
    base.all({
      "*?*": function() {
        var m, name, route;
        name = this.params[0].split('/')[1];
        route = '/' + name;
        if (!routes[route]) m = base.include(route);
        if (typeof m === 'function') {
          (function(name) {
            var view;
            base.extend({
              controller: function() {
                this.get(function() {
                  return view[name] = this.model();
                });
                return this(render(view));
              }
            }, route);
            return view = {};
          })(name);
        }
        return this.next();
      }
    });
    this.registerRoutes = function(r) {
      var route, _i, _len, _results;
      _results = [];
      for (_i = 0, _len = r.length; _i < _len; _i++) {
        route = r[_i];
        _results.push(this.include(r));
      }
      return _results;
    };
    extensions['controller'] = function(filepath, route) {
      var ctx, mpath, name, verb, _fn, _i, _j, _len, _len2, _ref, _ref2;
      name = filepath != null ? path.basename(filepath, '.coffee') : '';
      if ((route != null) && name) name = '/' + name;
      this.route = this.includepath = route != null ? route + name : name;
      ctx = this;
      _ref = ['io', 'on', 'include', 'extend'];
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        verb = _ref[_i];
        ctx[verb] = base[verb];
      }
      _ref2 = ['get', 'post', 'put', 'del'];
      _fn = function(verb) {
        return ctx[verb] = function() {
          var args, handler, r, subroute, _results;
          args = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
          base.log("registering " + this.route);
          if (args.length === 1) {
            r = args[0];
            if (typeof r !== 'object') {
              r = {
                '': args[0]
              };
            }
            _results = [];
            for (subroute in r) {
              handler = r[subroute];
              _results.push(base[verb](this.route + subroute, handler));
            }
            return _results;
          } else {
            return base[verb](this.route + args[0], args[1]);
          }
        };
      };
      for (_j = 0, _len2 = _ref2.length; _j < _len2; _j++) {
        verb = _ref2[_j];
        _fn(verb);
      }
      if (this.route.indexOf('/') !== 0) this.route = '/' + this.route;
      routes[this.route] = {
        controller: this.constructor,
        filepath: filepath
      };
      mpath = path.join('models', this.includepath, name);
      return this;
    };
    extensions['model'] = function(filepath, route) {
      var name;
      name = filepath != null ? path.basename(filepath, '.coffee') : '';
      if ((route != null) && name) name = '/' + name;
      return this.route = this.includepath = route != null ? route + name : name;
    };
    this.include = function(name) {
      var k, sub, v;
      if (typeof name === 'object') {
        for (k in name) {
          v = name[k];
          this[k] = this.include(v);
        }
        return this[k];
      }
      sub = require(path.join(root, name));
      if (sub.include) {
        if (typeof sub.include === 'object') {
          return this.extend(sub.include, name);
        } else {
          return sub.include.apply(this, [this]);
        }
      }
    };
    this.extend = function(obj, includeName) {
      var ctx, k, v, _extension, _ref, _super;
      if (typeof obj === 'function') {
        obj = {
          constructor: obj
        };
      }
      for (k in obj) {
        v = obj[k];
        _super = this[k] || ((_ref = routes[k]) != null ? _ref.controller : void 0) || extensions[k];
        if (_super) {
          ctx = new _super(includeName, this.includepath);
        } else {
          extensions[k] = v;
          ctx = this;
        }
        _extension = v.call(ctx);
        return _extension;
      }
    };
    ready.apply(this);
    return this;
  };

  module.exports = function(port, app) {
    return zappa.app(function() {
      var ready, zapp;
      zapp = this;
      return mvz.call(zapp, ready = function() {
        return app.call(zapp, ready = function() {
          var _ref;
          zapp.server.listen(port || 3000);
          zapp.log = zapp.log || function() {};
          return zapp.log('Express server listening on port %d in %s mode', (_ref = zapp.server.address()) != null ? _ref.port : void 0, zapp.app.settings.env);
        });
      });
    });
  };

}).call(this);
