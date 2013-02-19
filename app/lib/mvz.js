(function() {
  var fs, mvz, path, zappa,
    __slice = [].slice;

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
    extensions = {
      app: base
    };
    base.all({
      "*?*": function() {
        var m, name, route;
        name = this.params[0].split('/')[1];
        route = '/' + name;
        if (!routes[route]) {
          m = base.include(route);
        }
        if (typeof m === 'function') {
          (function(name) {
            var ctrlr, view;
            ctrlr = base.extend({
              controller: function() {
                return this;
              }
            }, route);
            view = {};
            return ctrlr.get(function() {
              view[name] = ctrlr.model();
              return this.render(view);
            });
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
      var ctrlr, name, verb, _fn, _i, _len, _ref;
      name = filepath != null ? path.basename(filepath, '.coffee') : '';
      if ((route != null) && name) {
        name = '/' + name;
      }
      this.route = this.includepath = route != null ? route + name : name;
      ctrlr = this;
      _ref = ['get', 'post', 'put', 'del'];
      _fn = function(verb) {
        return ctrlr[verb] = function() {
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
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        verb = _ref[_i];
        _fn(verb);
      }
      if (this.route.indexOf('/') !== 0) {
        this.route = '/' + this.route;
      }
      routes[this.route] = {
        controller: this.constructor,
        filepath: filepath
      };
      this.model = base.include(this.includepath, ["models"]);
      return this;
    };
    extensions['model'] = function(filepath, route) {
      var name;
      name = filepath != null ? path.basename(filepath, '.coffee') : '';
      if ((route != null) && name) {
        name = '/' + name;
      }
      return this.route = this.includepath = route != null ? route + name : name;
    };
    this.include = extensions['include'] = function(name, folders) {
      var folder, sub, _i, _len, _ref;
      _ref = folders || ['', 'controllers', 'models'];
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        folder = _ref[_i];
        try {
          sub = require(path.join(root, folder, name));
          if (sub.extend) {
            this.extend(sub.extend, name);
          }
          if (sub.include) {
            sub.include.apply(base, [base]);
          }
          return sub;
        } catch (ex) {
          base.log(ex);
        }
      }
    };
    this.extend = extensions['extend'] = function(obj, includeName) {
      var e, extension, k, m, v, _ref, _super;
      if (typeof obj === 'function') {
        obj = {
          constructor: obj
        };
      }
      for (k in obj) {
        v = obj[k];
        _super = this[k] || ((_ref = routes[k]) != null ? _ref.controller : void 0) || extensions[k];
        if (_super) {
          extension = v.call(new _super(includeName, this.includepath));
          if (typeof extension !== 'object') {
            throw "extension of " + k + " must return object";
          }
          for (e in extensions) {
            m = extensions[e];
            extension[e] = m;
          }
          return extension;
        }
        extensions[k] = v;
        if (k === 'log') {
          this[k] = v;
        }
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
