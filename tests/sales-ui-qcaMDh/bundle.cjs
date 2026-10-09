Warning: truncated output (original token count: 496981)
... 939346 bytes omitted ...

var __create = Object.create;
var __defProp = Object.defineProperty;
var __getOwnPropDesc = Object.getOwnPropertyDescriptor;
var __getOwnPropNames = Object.getOwnPropertyNames;
var __getProtoOf = Object.getPrototypeOf;
var __hasOwnProp = Object.prototype.hasOwnProperty;
var __commonJS = (cb, mod) => function __require() {
  try {
    return mod || (0, cb[__getOwnPropNames(cb)[0]])((mod = { exports: {} }).exports, mod), mod.exports;
  } catch (e) {
    throw mod = 0, e;
  }
};
var __export = (target, all) => {
  for (var name in all)
    __defProp(target, name, { get: all[name], enumerable: true });
};
var __copyProps = (to, from, except, desc) => {
  if (from && typeof from === "object" || typeof from === "function") {
    for (let key of __getOwnPropNames(from))
      if (!__hasOwnProp.call(to, key) && key !== except)
        __defProp(to, key, { get: () => from[key], enumerable: !(desc = __getOwnPropDesc(from, key)) || desc.enumerable });
  }
  return to;
};
var __toESM = (mod, isNodeMode, target) => (target = mod != null ? __create(__getProtoOf(mod)) : {}, __copyProps(
  // If the importer is in node compatibility mode or this is not an ESM
  // file that has been converted to a CommonJS file using a Babel-
  // compatible transform (i.e. "__esModule" has not been set), then set
  // "default" to the CommonJS "module.exports" for node compatibility.
  isNodeMode || !mod || !mod.__esModule ? __defProp(target, "default", { value: mod, enumerable: true }) : target,
  mod
));
var __toCommonJS = (mod) => __copyProps(__defProp({}, "__esModule", { value: true }), mod);

// node_modules/react/cjs/react-jsx-runtime.production.js
var require_react_jsx_runtime_production = __commonJS({
  "node_modules/react/cjs/react-jsx-runtime.production.js"(exports2) {
    "use strict";
    var REACT_ELEMENT_TYPE = /* @__PURE__ */ Symbol.for("react.transitional.element");
    var REACT_FRAGMENT_TYPE = /* @__PURE__ */ Symbol.for("react.fragment");
    function jsxProd(type, config, maybeKey) {
      var key = null;
      void 0 !== maybeKey && (key = "" + maybeKey);
      void 0 !== config.key && (key = "" + config.key);
      if ("key" in config) {
        maybeKey = {};
        for (var propName in config)
          "key" !== propName && (maybeKey[propName] = config[propName]);
      } else maybeKey = config;
      config = maybeKey.ref;
      return {
        $$typeof: REACT_ELEMENT_TYPE,
        type,
        key,
        ref: void 0 !== config ? config : null,
        props: maybeKey
      };
    }
    exports2.Fragment = REACT_FRAGMENT_TYPE;
    exports2.jsx = jsxProd;
    exports2.jsxs = jsxProd;
  }
});

// node_modules/react/cjs/react-jsx-runtime.development.js
var require_react_jsx_runtime_development = __commonJS({
  "node_modules/react/cjs/react-jsx-runtime.development.js"(exports2) {
    "use strict";
    "production" !== process.env.NODE_ENV && (function() {
      function getComponentNameFromType(type) {
        if (null == type) return null;
        if ("function" === typeof type)
          return type.$$typeof === REACT_CLIENT_REFERENCE ? null : type.displayName || type.name || null;
        if ("string" === typeof type) return type;
        switch (type) {
          case REACT_FRAGMENT_TYPE:
            return "Fragment";
          case REACT_PROFILER_TYPE:
            return "Profiler";
          case REACT_STRICT_MODE_TYPE:
            return "StrictMode";
          case REACT_SUSPENSE_TYPE:
            return "Suspense";
          case REACT_SUSPENSE_LIST_TYPE:
            return "SuspenseList";
          case REACT_ACTIVITY_TYPE:
            return "Activity";
          case REACT_VIEW_TRANSITION_TYPE:
            return "ViewTransition";
        }
        if ("object" === typeof type)
          switch ("number" === typeof type.tag && console.error(
            "Received an unexpected object in getComponentNameFromType(). This is likely a bug in React. Please file an issue."
          ), type.$$typeof) {
            case REACT_PORTAL_TYPE:
              return "Portal";
            case REACT_CONTEXT_TYPE:
              return type.displayName || "Context";
            case REACT_CONSUMER_TYPE:
              return (type._context.displayName || "Context") + ".Consumer";
            case REACT_FORWARD_REF_TYPE:
              var innerType = type.render;
              type = type.displayName;
              type || (type = innerType.displayName || innerType.name || "", type = "" !== type ? "ForwardRef(" + type + ")" : "ForwardRef");
              return type;
            case REACT_MEMO_TYPE:
              return innerType = type.displayName || null, null !== innerType ? innerType : getComponentNameFromType(type.type) || "Memo";
            case REACT_LAZY_TYPE:
              innerType = type._payload;
              type = type._init;
              try {
                return getComponentNameFromType(type(innerType));
              } catch (x) {
              }
          }
        return null;
      }
      function testStringCoercion(value) {
        return "" + value;
      }
      function checkKeyStringCoercion(value) {
        try {
          testStringCoercion(value);
          var JSCompiler_inline_result = false;
        } catch (e) {
          JSCompiler_inline_result = true;
        }
        if (JSCompiler_inline_result) {
          JSCompiler_inline_result = console;
          var JSCompiler_temp_const = JSCompiler_inline_result.error;
          var JSCompiler_inline_result$jscomp$0 = "function" === typeof Symbol && Symbol.toStringTag && value[Symbol.toStringTag] || value.constructor.name || "Object";
          JSCompiler_temp_const.call(
            JSCompiler_inline_result,
            "The provided key is an unsupported type %s. This value must be coerced to a string before using it here.",
            JSCompiler_inline_result$jscomp$0
          );
          return testStringCoercion(value);
        }
      }
      function getTaskName(type) {
        if (type === REACT_FRAGMENT_TYPE) return "<>";
        if ("object" === typeof type && null !== type && type.$$typeof === REACT_LAZY_TYPE)
          return "<...>";
        try {
          var name = getComponentNameFromType(type);
          return name ? "<" + name + ">" : "<...>";
        } catch (x) {
          return "<...>";
        }
      }
      function getOwner() {
        var dispatcher = ReactSharedInternals.A;
        return null === dispatcher ? null : dispatcher.getOwner();
      }
      function UnknownOwner() {
        return Error("react-stack-top-frame");
      }
      function hasValidKey(config) {
        if (hasOwnProperty.call(config, "key")) {
          var getter = Object.getOwnPropertyDescriptor(config, "key").get;
          if (getter && getter.isReactWarning) return false;
        }
        return void 0 !== config.key;
      }
      function defineKeyPropWarningGetter(props, displayName) {
        function warnAboutAccessingKey() {
          specialPropKeyWarningShown || (specialPropKeyWarningShown = true, console.error(
            "%s: `key` is not a prop. Trying to access it will result in `undefined` being returned. If you need to access the same value within the child component, you should pass it as a different prop. (https://react.dev/link/special-props)",
            displayName
          ));
        }
        warnAboutAccessingKey.isReactWarning = true;
        Object.defineProperty(props, "key", {
          get: warnAboutAccessingKey,
          configurable: true
        });
      }
      function elementRefGetterWithDeprecationWarning() {
        var componentName = getComponentNameFromType(this.type);
        didWarnAboutElementRef[componentName] || (didWarnAboutElementRef[componentName] = true, console.error(
          "Accessing element.ref was removed in React 19. ref is now a regular prop. It will be removed from the JSX Element type in a future release."
        ));
        componentName = this.props.ref;
        return void 0 !== componentName ? componentName : null;
      }
      function ReactElement(type, key, props, owner, debugStack, debugTask) {
        var refProp = props.ref;
        type = {
          $$typeof: REACT_ELEMENT_TYPE,
          type,
          key,
          props,
          _owner: owner
        };
        null !== (void 0 !== refProp ? refProp : null) ? Object.defineProperty(type, "ref", {
          enumerable: false,
          get: elementRefGetterWithDeprecationWarning
        }) : Object.defineProperty(type, "ref", { enumerable: false, value: null });
        type._store = {};
        Object.defineProperty(type._store, "validated", {
          configurable: false,
          enumerable: false,
          writable: true,
          value: 0
        });
        Object.defineProperty(type, "_debugInfo", {
          configurable: false,
          enumerable: false,
          writable: true,
          value: null
        });
        Object.defineProperty(type, "_debugStack", {
          configurable: false,
          enumerable: false,
          writable: true,
          value: debugStack
        });
        Object.defineProperty(type, "_debugTask", {
          configurable: false,
          enumerable: false,
          writable: true,
          value: debugTask
        });
        Object.freeze && (Object.freeze(type.props), Object.freeze(type));
        return type;
      }
      function jsxDEVImpl(type, config, maybeKey, isStaticChildren, debugStack, debugTask) {
        var children = config.children;
        if (void 0 !== children)
          if (isStaticChildren)
            if (isArrayImpl(children)) {
              for (isStaticChildren = 0; isStaticChildren < children.length; isStaticChildren++)
                validateChildKeys(children[isStaticChildren]);
              Object.freeze && Object.freeze(children);
            } else
              console.error(
                "React.jsx: Static children should always be an array. You are likely explicitly calling React.jsxs or React.jsxDEV. Use the Babel transform instead."
              );
          else validateChildKeys(children);
        if (hasOwnProperty.call(config, "key")) {
          children = getComponentNameFromType(type);
          var keys = Object.keys(config).filter(function(k) {
            return "key" !== k;
          });
          isStaticChildren = 0 < keys.length ? "{key: someKey, " + keys.join(": ..., ") + ": ...}" : "{key: someKey}";
          didWarnAboutKeySpread[children + isStaticChildren] || (keys = 0 < keys.length ? "{" + keys.join(": ..., ") + ": ...}" : "{}", console.error(
            'A props object containing a "key" prop is being spread into JSX:\n  let props = %s;\n  <%s {...props} />\nReact keys must be passed directly to JSX without using spread:\n  let props = %s;\n  <%s key={someKey} {...props} />',
            isStaticChildren,
            children,
            keys,
            children
          ), didWarnAboutKeySpread[children + isStaticChildren] = true);
        }
        children = null;
        void 0 !== maybeKey && (checkKeyStringCoercion(maybeKey), children = "" + maybeKey);
        hasValidKey(config) && (checkKeyStringCoercion(config.key), children = "" + config.key);
        if ("key" in config) {
          maybeKey = {};
          for (var propName in config)
            "key" !== propName && (maybeKey[propName] = config[propName]);
        } else maybeKey = config;
        children && defineKeyPropWarningGetter(
          maybeKey,
          "function" === typeof type ? type.displayName || type.name || "Unknown" : type
        );
        return ReactElement(
          type,
          children,
          maybeKey,
          getOwner(),
          debugStack,
          debugTask
        );
      }
      function validateChildKeys(node) {
        isValidElement(node) ? node._store && (node._store.validated = 1) : "object" === typeof node && null !== node && node.$$typeof === REACT_LAZY_TYPE && ("fulfilled" === node._payload.status ? isValidElement(node._payload.value) && node._payload.value._store && (node._payload.value._store.validated = 1) : node._store && (node._store.validated = 1));
      }
      function isValidElement(object) {
        return "object" === typeof object && null !== object && object.$$typeof === REACT_ELEMENT_TYPE;
      }
      var React16 = require("/workspace/scratch/76b8a24bf15c/imanservice/node_modules/react/index.js"), REACT_ELEMENT_TYPE = /* @__PURE__ */ Symbol.for("react.transitional.element"), REACT_PORTAL_TYPE = /* @__PURE__ */ Symbol.for("react.portal"), REACT_FRAGMENT_TYPE = /* @__PURE__ */ Symbol.for("react.fragment"), REACT_STRICT_MODE_TYPE = /* @__PURE__ */ Symbol.for("react.strict_mode"), REACT_PROFILER_TYPE = /* @__PURE__ */ Symbol.for("react.profiler"), REACT_CONSUMER_TYPE = /* @__PURE__ */ Symbol.for("react.consumer"), REACT_CONTEXT_TYPE = /* @__PURE__ */ Symbol.for("react.context"), REACT_FORWARD_REF_TYPE = /* @__PURE__ */ Symbol.for("react.forward_ref"), REACT_SUSPENSE_TYPE = /* @__PURE__ */ Symbol.for("react.suspense"), REACT_SUSPENSE_LIST_TYPE = /* @__PURE__ */ Symbol.for("react.suspense_list"), REACT_MEMO_TYPE = /* @__PURE__ */ Symbol.for("react.memo"), REACT_LAZY_TYPE = /* @__PURE__ */ Symbol.for("react.lazy"), REACT_ACTIVITY_TYPE = /* @__PURE__ */ Symbol.for("react.activity"), REACT_VIEW_TRANSITION_TYPE = /* @__PURE__ */ Symbol.for("react.view_transition"), REACT_CLIENT_REFERENCE = /* @__PURE__ */ Symbol.for("react.client.reference"), ReactSharedInternals = React16.__CLIENT_INTERNALS_DO_NOT_USE_OR_WARN_USERS_THEY_CANNOT_UPGRADE, hasOwnProperty = Object.prototype.hasOwnProperty, isArrayImpl = Array.isArray, createTask = console.createTask ? console.createTask : function() {
        return null;
      };
      React16 = {
        react_stack_bottom_frame: function(callStackForError) {
          return callStackForError();
        }
      };
      var specialPropKeyWarningShown;
      var didWarnAboutElementRef = {};
      var unknownOwnerDebugStack = React16.react_stack_bottom_frame.bind(
        React16,
        UnknownOwner
      )();
      var unknownOwnerDebugTask = createTask(getTaskName(UnknownOwner));
      var didWarnAboutKeySpread = {};
      exports2.Fragment = REACT_FRAGMENT_TYPE;
      exports2.jsx = function(type, config, maybeKey) {
        var trackActualOwner = 1e4 > ReactSharedInternals.recentlyCreatedOwnerStacks++;
        if (trackActualOwner) {
          var previousStackTraceLimit = Error.stackTraceLimit;
          Error.stackTraceLimit = 10;
          var debugStackDEV = Error("react-stack-top-frame");
          Error.stackTraceLimit = previousStackTraceLimit;
        } else debugStackDEV = unknownOwnerDebugStack;
        return jsxDEVImpl(
          type,
          config,
          maybeKey,
          false,
          debugStackDEV,
          trackActualOwner ? createTask(getTaskName(type)) : unknownOwnerDebugTask
        );
      };
      exports2.jsxs = function(type, config, maybeKey) {
        var trackActualOwner = 1e4 > ReactSharedInternals.recentlyCreatedOwnerStacks++;
        if (trackActualOwner) {
          var previousStackTraceLimit = Error.stackTraceLimit;
          Error.stackTraceLimit = 10;
          var debugStackDEV = Error("react-stack-top-frame");
          Error.stackTraceLimit = previousStackTraceLimit;
        } else debugStackDEV = unknownOwnerDebugStack;
        return jsxDEVImpl(
          type,
          config,
          maybeKey,
          true,
          debugStackDEV,
          trackActualOwner ? createTask(getTaskName(type)) : unknownOwnerDebugTask
        );
      };
    })();
  }
});

// node_modules/react/jsx-runtime.js
var require_jsx_runtime = __commonJS({
  "node_modules/react/jsx-runtime.js"(exports2, module2) {
    "use strict";
    if (process.env.NODE_ENV === "production") {
      module2.exports = require_react_jsx_runtime_production();
    } else {
      module2.exports = require_react_jsx_runtime_development();
    }
  }
});

// node_modules/fflate/lib/node.cjs
var require_node = __commonJS({
  "node_modules/fflate/lib/node.cjs"(exports2) {
    "use strict";
    exports2.deflate = deflate;
    exports2.deflateSync = deflateSync;
    exports2.inflate = inflate;
    exports2.inflateSync = inflateSync;
    exports2.gzip = gzip;
    exports2.compress = gzip;
    exports2.gzipSync = gzipSync;
    exports2.compressSync = gzipSync;
    exports2.gunzip = gunzip;
    exports2.gunzipSync = gunzipSync;
    exports2.zlib = zlib;
    exports2.zlibSync = zlibSync;
    exports2.unzlib = unzlib;
    exports2.unzlibSync = unzlibSync;
    exports2.gzip = gzip;
    exports2.compress = gzip;
    exports2.decompress = decompress;
    exports2.decompressSync = decompressSync;
    exports2.strToU8 = strToU8;
    exports2.strFromU8 = strFromU8;
    exports2.zip = zip;
    exports2.zipSync = zipSync;
    exports2.unzip = unzip;
    exports2.unzipSync = unzipSync;
    var _a;
    var Worker;
    var isMarkedAsUntransferable;
    var workerAdd = ";var __w=require('worker_threads');__w.parentPort.on('message',function(m){onmessage({data:m})}),postMessage=function(m,t){__w.parentPort.postMessage(m,t)},close=process.exit;self=global";
    try {
      _a = require("worker_threads"), Worker = _a.Worker, isMarkedAsUntransferable = _a.isMarkedAsUntransferable;
    } catch (e) {
    }
    var node_worker_1 = {};
    node_worker_1["default"] = Worker ? function(c, _, msg, transfer, cb) {
      var done = false;
      var w = new Worker(c + workerAdd, { eval: true }).on("error", function(e) {
        return cb(e, null);
      }).on("message", function(m) {
        return cb(null, m);
      }).on("exit", function(c2) {
        if (c2 && !done)
          cb(new Error("exited with code " + c2), null);
      });
      if (isMarkedAsUntransferable)
        transfer = transfer.filter(function(t) {
          return !isMarkedAsUntransferable(t);
        });
      w.postMessage(msg, transfer);
      w.terminate = function() {
        done = true;
        return Worker.prototype.terminate.call(w);
      };
      return w;
    } : function(_, __, ___, ____, cb) {
      setImmediate(function() {
        return cb(new Error("async operations unsupported - update to Node 12+ (or Node 10-11 with the --experimental-worker CLI flag)"), null);
      });
      var NOP = function() {
      };
      return {
        terminate: NOP,
        postMessage: NOP
      };
    };
    var u8 = Uint8Array;
    var u16 = Uint16Array;
    var i32 = Int32Array;
    var fleb = new u8([
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      1,
      1,
      1,
      1,
      2,
      2,
      2,
      2,
      3,
      3,
      3,
      3,
      4,
      4,
      4,
      4,
      5,
      5,
      5,
      5,
      0,
      /* unused */
      0,
      0,
      /* impossible */
      0
    ]);
    var fdeb = new u8([
      0,
      0,
      0,
      0,
      1,
      1,
      2,
      2,
      3,
      3,
      4,
      4,
      5,
      5,
      6,
      6,
      7,
      7,
      8,
      8,
      9,
      9,
      10,
      10,
      11,
      11,
      12,
      12,
      13,
      13,
      /* unused */
      0,
      0
    ]);
    var clim = new u8([16, 17, 18, 0, 8, 7, 9, 6, 10, 5, 11, 4, 12, 3, 13, 2, 14, 1, 15]);
    var freb = function(eb, start) {
      var b = new u16(31);
      for (var i2 = 0; i2 < 31; ++i2) {
        b[i2] = start += 1 << eb[i2 - 1];
      }
      var r = new i32(b[30]);
      for (var i2 = 1; i2 < 30; ++i2) {
        for (var j = b[i2]; j < b[i2 + 1]; ++j) {
          r[j] = j - b[i2] << 5 | i2;
        }
      }
      return { b, r };
    };
    var _a = freb(fleb, 2);
    var fl = _a.b;
    var revfl = _a.r;
    fl[28] = 258, revfl[258] = 28;
    var _b = freb(fdeb, 0);
    var fd = _b.b;
    var revfd = _b.r;
    var rev = new u16(32768);
    for (i = 0; i < 32768; ++i) {
      x = (i & 43690) >> 1 | (i & 21845) << 1;
      x = (x & 52428) >> 2 | (x & 13107) << 2;
      x = (x & 61680) >> 4 | (x & 3855) << 4;
      rev[i] = ((x & 65280) >> 8 | (x & 255) << 8) >> 1;
    }
    var x;
    var i;
    var hMap = (function(cd, mb, r) {
      var s = cd.length;
      var i2 = 0;
      var l = new u16(mb);
      for (; i2 < s; ++i2) {
        if (cd[i2])
          ++l[cd[i2] - 1];
      }
      var le = new u16(mb);
      for (i2 = 1; i2 < mb; ++i2) {
        le[i2] = le[i2 - 1] + l[i2 - 1] << 1;
      }
      var co;
      if (r) {
        co = new u16(1 << mb);
        var rvb = 15 - mb;
        for (i2 = 0; i2 < s; ++i2) {
          if (cd[i2]) {
            var sv = i2 << 4 | cd[i2];
            var r_1 = mb - cd[i2];
            var v = le[cd[i2] - 1]++ << r_1;
            for (var m = v | (1 << r_1) - 1; v <= m; ++v) {
              co[rev[v] >> rvb] = sv;
            }
          }
        }
      } else {
        co = new u16(s);
        for (i2 = 0; i2 < s; ++i2) {
          if (cd[i2]) {
            co[i2] = rev[le[cd[i2] - 1]++] >> 15 - cd[i2];
          }
        }
      }
      return co;
    });
    var flt = new u8(288);
    for (i = 0; i < 144; ++i)
      flt[i] = 8;
    var i;
    for (i = 144; i < 256; ++i)
      flt[i] = 9;
    var i;
    for (i = 256; i < 280; ++i)
      flt[i] = 7;
    var i;
    for (i = 280; i < 288; ++i)
      flt[i] = 8;
    var i;
    var fdt = new u8(32);
    for (i = 0; i < 32; ++i)
      fdt[i] = 5;
    var i;
    var flm = /* @__PURE__ */ hMap(flt, 9, 0);
    var flrm = /* @__PURE__ */ hMap(flt, 9, 1);
    var fdm = /* @__PURE__ */ hMap(fdt, 5, 0);
    var fdrm = /* @__PURE__ */ hMap(fdt, 5, 1);
    var max = function(a) {
      var m = a[0];
      for (var i2 = 1; i2 < a.length; ++i2) {
        if (a[i2] > m)
          m = a[i2];
      }
      return m;
    };
    var bits = function(d, p, m) {
      var o = p / 8 | 0;
      return (d[o] | d[o + 1] << 8) >> (p & 7) & m;
    };
    var bits16 = function(d, p) {
      var o = p / 8 | 0;
      return (d[o] | d[o + 1] << 8 | d[o + 2] << 16) >> (p & 7);
    };
    var shft = function(p) {
      return (p + 7) / 8 | 0;
    };
    var slc = function(v, s, e) {
      if (s == null || s < 0)
        s = 0;
      if (e == null || e > v.length)
        e = v.length;
      return new u8(v.subarray(s, e));
    };
    exports2.FlateErrorCode = {
      UnexpectedEOF: 0,
      InvalidBlockType: 1,
      InvalidLengthLiteral: 2,
      InvalidDistance: 3,
      StreamFinished: 4,
      NoStreamHandler: 5,
      InvalidHeader: 6,
      NoCallback: 7,
      InvalidUTF8: 8,
      ExtraFieldTooLong: 9,
      InvalidDate: 10,
      FilenameTooLong: 11,
      StreamFinishing: 12,
      InvalidZipData: 13,
      UnknownCompressionMethod: 14
    };
    var ec = [
      "unexpected EOF",
      "invalid block type",
      "invalid length/literal",
      "invalid distance",
      "stream finished",
      "no stream handler",
      ,
      // determined by compression function
      "no callback",
      "invalid UTF-8 data",
      "extra field too long",
      "date not in range 1980-2099",
      "filename too long",
      "stream finishing",
      "invalid zip data"
      // determined by unknown compression method
    ];
    var err = function(ind, msg, nt) {
      var e = new Error(msg || ec[ind]);
      e.code = ind;
      if (Error.captureStackTrace)
        Error.captureStackTrace(e, err);
      if (!nt)
        throw e;
      return e;
    };
    var inflt = function(dat, st, buf, dict) {
      var sl = dat.length, dl = dict ? dict.length : 0;
      if (!sl || st.f && !st.l)
        return buf || new u8(0);
      var noBuf = !buf;
      var resize = noBuf || st.i != 2;
      var noSt = st.i;
      if (noBuf)
        buf = new u8(sl * 3);
      var cbuf = function(l2) {
        var bl = buf.length;
        if (l2 > bl) {
          var nbuf = new u8(Math.max(bl * 2, l2));
          nbuf.set(buf);
          buf = nbuf;
        }
      };
      var final = st.f || 0, pos = st.p || 0, bt = st.b || 0, lm = st.l, dm = st.d, lbt = st.m, dbt = st.n;
      var tbts = sl * 8;
      do {
        if (!lm) {
          final = bits(dat, pos, 1);
          var type = bits(dat, pos + 1, 3);
          pos += 3;
          if (!type) {
            var s = shft(pos) + 4, l = dat[s - 4] | dat[s - 3] << 8, t = s + l;
            if (t > sl) {
              if (noSt)
                err(0);
              break;
            }
            if (resize)
              cbuf(bt + l);
            buf.set(dat.subarray(s, t), bt);
            st.b = bt += l, st.p = pos = t * 8, st.f = final;
            continue;
          } else if (type == 1)
            lm = flrm, dm = fdrm, lbt = 9, dbt = 5;
          else if (type == 2) {
            var hLit = bits(dat, pos, 31) + 257, hcLen = bits(dat, pos + 10, 15) + 4;
            var tl = hLit + bits(dat, pos + 5, 31) + 1;
            pos += 14;
            var ldt = new u8(tl);
            var clt = new u8(19);
            for (var i2 = 0; i2 < hcLen; ++i2) {
              clt[clim[i2]] = bits(dat, pos + i2 * 3, 7);
            }
            pos += hcLen * 3;
            var clb = max(clt), clbmsk = (1 << clb) - 1;
            var clm = hMap(clt, clb, 1);
            for (var i2 = 0; i2 < tl; ) {
              var r = clm[bits(dat, pos, clbmsk)];
              pos += r & 15;
              var s = r >> 4;
              if (s < 16) {
                ldt[i2++] = s;
              } else {
                var c = 0, n = 0;
                if (s == 16)
                  n = 3 + bits(dat, pos, 3), pos += 2, c = ldt[i2 - 1];
                else if (s == 17)
                  n = 3 + bits(dat, pos, 7), pos += 3;
                else if (s == 18)
                  n = 11 + bits(dat, pos, 127), pos += 7;
                while (n--)
                  ldt[i2++] = c;
              }
            }
            var lt = ldt.subarray(0, hLit), dt = ldt.subarray(hLit);
            lbt = max(lt);
            dbt = max(dt);
            lm = hMap(lt, lbt, 1);
            dm = hMap(dt, dbt, 1);
          } else
            err(1);
          if (pos > tbts) {
            if (noSt)
              err(0);
            break;
          }
        }
        if (resize)
          cbuf(bt + 131072);
        var lms = (1 << lbt) - 1, dms = (1 << dbt) - 1;
        var lpos = pos;
        for (; ; lpos = pos) {
          var c = lm[bits16(dat, pos) & lms], sym = c >> 4;
          pos += c & 15;
          if (pos > tbts) {
            if (noSt)
              err(0);
            break;
          }
          if (!c)
            err(2);
          if (sym < 256)
            buf[bt++] = sym;
          else if (sym == 256) {
            lpos = pos, lm = null;
            break;
          } else {
            var add = sym - 254;
            if (sym > 264) {
              var i2 = sym - 257, b = fleb[i2];
              add = bits(dat, pos, (1 << b) - 1) + fl[i2];
              pos += b;
            }
            var d = dm[bits16(dat, pos) & dms], dsym = d >> 4;
            if (!d)
              err(3);
            pos += d & 15;
            var dt = fd[dsym];
            if (dsym > 3) {
              var b = fdeb[dsym];
              dt += bits16(dat, pos) & (1 << b) - 1, pos += b;
            }
            if (pos > tbts) {
              if (noSt)
                err(0);
              break;
            }
            if (resize)
              cbuf(bt + 131072);
            var end = bt + add;
            if (bt < dt) {
              var shift = dl - dt, dend = Math.min(dt, end);
              if (shift + bt < 0)
                err(3);
              for (; bt < dend; ++bt)
                buf[bt] = dict[shift + bt];
            }
            for (; bt < end; ++bt)
              buf[bt] = buf[bt - dt];
          }
        }
        st.l = lm, st.p = lpos, st.b = bt, st.f = final;
        if (lm)
          final = 1, st.m = lbt, st.d = dm, st.n = dbt;
      } while (!final);
      return bt != buf.length && noBuf ? slc(buf, 0, bt) : buf.subarray(0, bt);
    };
    var wbits = function(d, p, v) {
      v <<= p & 7;
      var o = p / 8 | 0;
      d[o] |= v;
      d[o + 1] |= v >> 8;
    };
    var wbits16 = function(d, p, v) {
      v <<= p & 7;
      var o = p / 8 | 0;
      d[o] |= v;
      d[o + 1] |= v >> 8;
      d[o + 2] |= v >> 16;
    };
    var hTree = function(d, mb) {
      var t = [];
      for (var i2 = 0; i2 < d.length; ++i2) {
        if (d[i2])
          t.push({ s: i2, f: d[i2] });
      }
      var s = t.length;
      var t2 = t.slice();
      if (!s)
        return { t: et, l: 0 };
      if (s == 1) {
        var v = new u8(t[0].s + 1);
        v[t[0].s] = 1;
        return { t: v, l: 1 };
      }
      t.sort(function(a, b) {
        return a.f - b.f;
      });
      t.push({ s: -1, f: 25001 });
      var l = t[0], r = t[1], i0 = 0, i1 = 1, i22 = 2;
      t[0] = { s: -1, f: l.f + r.f, l, r };
      while (i1 != s - 1) {
        l = t[t[i0].f < t[i22].f ? i0++ : i22++];
        r = t[i0 != i1 && t[i0].f < t[i22].f ? i0++ : i22++];
        t[i1++] = { s: -1, f: l.f + r.f, l, r };
      }
      var maxSym = t2[0].s;
      for (var i2 = 1; i2 < s; ++i2) {
        if (t2[i2].s > maxSym)
          maxSym = t2[i2].s;
      }
      var tr = new u16(maxSym + 1);
      var mbt = ln(t[i1 - 1], tr, 0);
      if (mbt > mb) {
        var i2 = 0, dt = 0;
        var lft = mbt - mb, cst = 1 << lft;
        t2.sort(function(a, b) {
          return tr[b.s] - tr[a.s] || a.f - b.f;
        });
        for (; i2 < s; ++i2) {
          var i2_1 = t2[i2].s;
          if (tr[i2_1] > mb) {
            dt += cst - (1 << mbt - tr[i2_1]);
            tr[i2_1] = mb;
          } else
            break;
        }
        dt >>= lft;
        while (dt > 0) {
          var i2_2 = t2[i2].s;
          if (tr[i2_2] < mb)
            dt -= 1 << mb - tr[i2_2]++ - 1;
          else
            ++i2;
        }
        for (; i2 >= 0 && dt; --i2) {
          var i2_3 = t2[i2].s;
          if (tr[i2_3] == mb) {
            --tr[i2_3];
            ++dt;
          }
        }
        mbt = mb;
      }
      return { t: new u8(tr), l: mbt };
    };
    var ln = function(n, l, d) {
      return n.s == -1 ? Math.max(ln(n.l, l, d + 1), ln(n.r, l, d + 1)) : l[n.s] = d;
    };
    var lc = function(c) {
      var s = c.length;
      while (s && !c[--s])
        ;
      var cl = new u16(++s);
      var cli = 0, cln = c[0], cls = 1;
      var w = function(v) {
        cl[cli++] = v;
      };
      for (var i2 = 1; i2 <= s; ++i2) {
        if (c[i2] == cln && i2 != s)
          ++cls;
        else {
          if (!cln && cls > 2) {
            for (; cls > 138; cls -= 138)
              w(32754);
            if (cls > 2) {
              w(cls > 10 ? cls - 11 << 5 | 28690 : cls - 3 << 5 | 12305);
              cls = 0;
            }
          } else if (cls > 3) {
            w(cln), --cls;
            for (; cls > 6; cls -= 6)
              w(8304);
            if (cls > 2)
              w(cls - 3 << 5 | 8208), cls = 0;
          }
          while (cls--)
            w(cln);
          cls = 1;
          cln = c[i2];
        }
      }
      return { c: cl.subarray(0, cli), n: s };
    };
    var clen = function(cf, cl) {
      var l = 0;
      for (var i2 = 0; i2 < cl.length; ++i2)
        l += cf[i2] * cl[i2];
      return l;
    };
    var wfblk = function(out, pos, dat) {
      var s = dat.length;
      var o = shft(pos + 2);
      out[o] = s & 255;
      out[o + 1] = s >> 8;
      out[o + 2] = out[o] ^ 255;
      out[o + 3] = out[o + 1] ^ 255;
      for (var i2 = 0; i2 < s; ++i2)
        out[o + i2 + 4] = dat[i2];
      return (o + 4 + s) * 8;
    };
    var wblk = function(dat, out, final, syms, lf, df, eb, li, bs, bl, p) {
      wbits(out, p++, final);
      ++lf[256];
      var _a2 = hTree(lf, 15), dlt = _a2.t, mlb = _a2.l;
      var _b2 = hTree(df, 15), ddt = _b2.t, mdb = _b2.l;
      var _c = lc(dlt), lclt = _c.c, nlc = _c.n;
      var _d = lc(ddt), lcdt = _d.c, ndc = _d.n;
      var lcfreq = new u16(19);
      for (var i2 = 0; i2 < lclt.length; ++i2)
        ++lcfreq[lclt[i2] & 31];
      for (var i2 = 0; i2 < lcdt.length; ++i2)
        ++lcfreq[lcdt[i2] & 31];
      var _e = hTree(lcfreq, 7), lct = _e.t, mlcb = _e.l;
      var nlcc = 19;
      for (; nlcc > 4 && !lct[clim[nlcc - 1]]; --nlcc)
        ;
      var flen = bl + 5 << 3;
      var ftlen = clen(lf, flt) + clen(df, fdt) + eb;
      var dtlen = clen(lf, dlt) + clen(df, ddt) + eb + 14 + 3 * nlcc + clen(lcfreq, lct) + 2 * lcfreq[16] + 3 * lcfreq[17] + 7 * lcfreq[18];
      if (bs >= 0 && flen <= ftlen && flen <= dtlen)
        return wfblk(out, p, dat.subarray(bs, bs + bl));
      var lm, ll, dm, dl;
      wbits(out, p, 1 + (dtlen < ftlen)), p += 2;
      if (dtlen < ftlen) {
        lm = hMap(dlt, mlb, 0), ll = dlt, dm = hMap(ddt, mdb, 0), dl = ddt;
        var llm = hMap(lct, mlcb, 0);
        wbits(out, p, nlc - 257);
        wbits(out, p + 5, ndc - 1);
        wbits(out, p + 10, nlcc - 4);
        p += 14;
        for (var i2 = 0; i2 < nlcc; ++i2)
          wbits(out, p + 3 * i2, lct[clim[i2]]);
        p += 3 * nlcc;
        var lcts = [lclt, lcdt];
        for (var it = 0; it < 2; ++it) {
          var clct = lcts[it];
          for (var i2 = 0; i2 < clct.length; ++i2) {
            var len = clct[i2] & 31;
            wbits(out, p, llm[len]), p += lct[len];
            if (len > 15)
              wbits(out, p, clct[i2] >> 5 & 127), p += clct[i2] >> 12;
          }
        }
      } else {
        lm = flm, ll = flt, dm = fdm, dl = fdt;
      }
      for (var i2 = 0; i2 < li; ++i2) {
        var sym = syms[i2];
        if (sym > 255) {
          var len = sym >> 18 & 31;
          wbits16(out, p, lm[len + 257]), p += ll[len + 257];
          if (len > 7)
            wbits(out, p, sym >> 23 & 31), p += fleb[len];
          var dst = sym & 31;
          wbits16(out, p, dm[dst]), p += dl[dst];
          if (dst > 3)
            wbits16(out, p, sym >> 5 & 8191), p += fdeb[dst];
        } else {
          wbits16(out, p, lm[sym]), p += ll[sym];
        }
      }
      wbits16(out, p, lm[256]);
      return p + ll[256];
    };
    var deo = /* @__PURE__ */ new i32([65540, 131080, 131088, 131104, 262176, 1048704, 1048832, 2114560, 2117632]);
    var et = /* @__PURE__ */ new u8(0);
    var dflt = function(dat, lvl, plvl, pre, post, st) {
      var s = st.z || dat.length;
      var o = new u8(pre + s + 5 * (1 + Math.ceil(s / 7e3)) + post);
      var w = o.subarray(pre, o.length - post);
      var lst = st.l;
      var pos = (st.r || 0) & 7;
      if (lvl) {
        if (pos)
          w[0] = st.r >> 3;
        var opt = deo[lvl - 1];
        var n = opt >> 13, c = opt & 8191;
        var msk_1 = (1 << plvl) - 1;
        var prev = st.p || new u16(32768), head = st.h || new u16(msk_1 + 1);
        var bs1_1 = Math.ceil(plvl / 3), bs2_1 = 2 * bs1_1;
        var hsh = function(i3) {
          return (dat[i3] ^ dat[i3 + 1] << bs1_1 ^ dat[i3 + 2] << bs2_1) & msk_1;
        };
        var syms = new i32(25e3);
        var lf = new u16(288), df = new u16(32);
        var lc_1 = 0, eb = 0, i2 = st.i || 0, li = 0, wi = st.w || 0, bs = 0;
        for (; i2 + 2 < s; ++i2) {
          var hv = hsh(i2);
          var imod = i2 & 32767, pimod = head[hv];
          prev[imod] = pimod;
          head[hv] = imod;
          if (wi <= i2) {
            var rem = s - i2;
            if ((lc_1 > 7e3 || li > 24576) && (rem > 423 || !lst)) {
              pos = wblk(dat, w, 0, syms, lf, df, eb, li, bs, i2 - bs, pos);
              li = lc_1 = eb = 0, bs = i2;
              for (var j = 0; j < 286; ++j)
                lf[j] = 0;
              for (var j = 0; j < 30; ++j)
                df[j] = 0;
            }
            var l = 2, d = 0, ch_1 = c, dif = imod - pimod & 32767;
            if (rem > 2 && hv == hsh(i2 - dif)) {
              var maxn = Math.min(n, rem) - 1;
              var maxd = Math.min(32767, i2);
              var ml = Math.min(258, rem);
              while (dif <= maxd && --ch_1 && imod != pimod) {
                if (dat[i2 + l] == dat[i2 + l - dif]) {
                  var nl = 0;
                  for (; nl < ml && dat[i2 + nl] == dat[i2 + nl - dif]; ++nl)
                    ;
                  if (nl > l) {
                    l = nl, d = dif;
                    if (nl > maxn)
                      break;
                    var mmd = Math.min(dif, nl - 2);
                    var md = 0;
                    for (var j = 0; j < mmd; ++j) {
                      var ti = i2 - dif + j & 32767;
                      var pti = prev[ti];
                      var cd = ti - pti & 32767;
                      if (cd > md)
                        md = cd, pimod = ti;
                    }
                  }
                }
                imod = pimod, pimod = prev[imod];
                dif += imod - pimod & 32767;
              }
            }
            if (d) {
              syms[li++] = 268435456 | revfl[l] << 18 | revfd[d];
              var lin = revfl[l] & 31, din = revfd[d] & 31;
              eb += fleb[lin] + fdeb[din];
              ++lf[257 + lin];
              ++df[din];
              wi = i2 + l;
              ++lc_1;
            } else {
              syms[li++] = dat[i2];
              ++lf[dat[i2]];
            }
          }
        }
        for (i2 = Math.max(i2, wi); i2 < s; ++i2) {
          syms[li++] = dat[i2];
          ++lf[dat[i2]];
        }
        pos = wblk(dat, w, lst, syms, lf, df, eb, li, bs, i2 - bs, pos);
        if (!lst) {
          st.r = pos & 7 | w[pos / 8 | 0] << 3;
          pos -= 7;
          st.h = head, st.p = prev, st.i = i2, st.w = wi;
        }
      } else {
        for (var i2 = st.w || 0; i2 < s + lst; i2 += 65535) {
          var e = i2 + 65535;
          if (e >= s) {
            w[pos / 8 | 0] = lst;
            e = s;
          }
          pos = wfblk(w, pos + 1, dat.subarray(i2, e));
        }
        st.i = s;
      }
      return slc(o, 0, pre + shft(pos) + post);
    };
    var crct = /* @__PURE__ */ (function() {
      var t = new Int32Array(256);
      for (var i2 = 0; i2 < 256; ++i2) {
        var c = i2, k = 9;
        while (--k)
          c = (c & 1 && -306674912) ^ c >>> 1;
        t[i2] = c;
      }
      return t;
    })();
    var crc = function() {
      var c = -1;
      return {
        p: function(d) {
          var cr = c;
          for (var i2 = 0; i2 < d.length; ++i2)
            cr = crct[cr & 255 ^ d[i2]] ^ cr >>> 8;
          c = cr;
        },
        d: function() {
          return ~c;
        }
      };
    };
    var adler = function() {
      var a = 1, b = 0;
      return {
        p: function(d) {
          var n = a, m = b;
          var l = d.length | 0;
          for (var i2 = 0; i2 != l; ) {
            var e = Math.min(i2 + 2655, l);
            for (; i2 < e; ++i2)
              m += n += d[i2];
            n = (n & 65535) + 15 * (n >> 16), m = (m & 65535) + 15 * (m >> 16);
          }
          a = n, b = m;
        },
        d: function() {
          a %= 65521, b %= 65521;
          return (a & 255) << 24 | (a & 65280) << 8 | (b & 255) << 8 | b >> 8;
        }
      };
    };
    var dopt = function(dat, opt, pre, post, st) {
      if (!st) {
        st = { l: 1 };
        if (opt.dictionary) {
          var dict = opt.dictionary.subarray(-32768);
          var newDat = new u8(dict.length + dat.length);
          newDat.set(dict);
          newDat.set(dat, dict.length);
          dat = newDat;
          st.w = dict.length;
        }
      }
      return dflt(dat, opt.level == null ? 6 : opt.level, opt.mem == null ? st.l ? Math.ceil(Math.max(8, Math.min(13, Math.log(dat.length))) * 1.5) : 20 : 12 + opt.mem, pre, post, st);
    };
    var mrg = function(a, b) {
      var o = {};
      for (var k in a)
        o[k] = a[k];
      for (var k in b)
        o[k] = b[k];
      return o;
    };
    var wcln = function(fn, fnStr, td2) {
      var dt = fn();
      var st = fn.toString();
      var ks = st.slice(st.indexOf("[") + 1, st.lastIndexOf("]")).replace(/\s+/g, "").split(",");
      for (var i2 = 0; i2 < dt.length; ++i2) {
        var v = dt[i2], k = ks[i2];
        if (typeof v == "function") {
          fnStr += ";" + k + "=";
          var st_1 = v.toString();
          if (v.prototype) {
            if (st_1.indexOf("[native code]") != -1) {
              var spInd = st_1.indexOf(" ", 8) + 1;
              fnStr += st_1.slice(spInd, st_1.indexOf("(", spInd));
            } else {
              fnStr += st_1;
              for (var t in v.prototype)
                fnStr += ";" + k + ".prototype." + t + "=" + v.prototype[t].toString();
            }
          } else
            fnStr += st_1;
        } else
          td2[k] = v;
      }
      return fnStr;
    };
    var ch = [];
    var cbfs = function(v) {
      var tl = [];
      for (var k in v) {
        if (v[k].buffer) {
          tl.push((v[k] = new v[k].constructor(v[k])).buffer);
        }
      }
      return tl;
    };
    var wrkr = function(fns, init, id, cb) {
      if (!ch[id]) {
        var fnStr = "", td_1 = {}, m = fns.length - 1;
        for (var i2 = 0; i2 < m; ++i2)
          fnStr = wcln(fns[i2], fnStr, td_1);
        ch[id] = { c: wcln(fns[m], fnStr, td_1), e: td_1 };
      }
      var td2 = mrg({}, ch[id].e);
      return (0, node_worker_1.default)(ch[id].c + ";onmessage=function(e){for(var k in e.data)self[k]=e.data[k];onmessage=" + init.toString() + "}", id, td2, cbfs(td2), cb);
    };
    var bInflt = function() {
      return [u8, u16, i32, fleb, fdeb, clim, fl, fd, flrm, fdrm, rev, ec, hMap, max, bits, bits16, shft, slc, err, inflt, inflateSync, pbf, gopt];
    };
    var bDflt = function() {
      return [u8, u16, i32, fleb, fdeb, clim, revfl, revfd, flm, flt, fdm, fdt, rev, deo, et, hMap, wbits, wbits16, hTree, ln, lc, clen, wfblk, wblk, shft, slc, dflt, dopt, deflateSync, pbf];
    };
    var gze = function() {
      return [gzh, gzhl, wbytes, crc, crct];
    };
    var guze = function() {
      return [gzs, gzl];
    };
    var zle = function() {
      return [zlh, wbytes, adler];
    };
    var zule = function() {
      return [zls];
    };
    var pbf = function(msg) {
      return postMessage(msg, [msg.buffer]);
    };
    var gopt = function(o) {
      return o && {
        out: o.size && new u8(o.size),
        dictionary: o.dictionary
      };
    };
    var cbify = function(dat, opts2, fns, init, id, cb) {
      var w = wrkr(fns, init, id, function(err2, dat2) {
        w.terminate();
        cb(err2, dat2);
      });
      w.postMessage([dat, opts2], opts2.consume ? [dat.buffer] : []);
      return function() {
        w.terminate();
      };
    };
    var astrm = function(strm) {
      strm.ondata = function(dat, final) {
        return postMessage([dat, final], [dat.buffer]);
      };
      return function(ev) {
        if (ev.data[0]) {
          strm.push(ev.data[0], ev.data[1]);
          postMessage([ev.data[0].length]);
        } else
          strm.flush(ev.data[1]);
      };
    };
    var astrmify = function(fns, strm, opts2, init, id, flush, ext) {
      var t;
      var w = wrkr(fns, init, id, function(err2, dat) {
        if (err2)
          w.terminate(), strm.ondata.call(strm, err2);
        else if (!Array.isArray(dat))
          ext(dat);
        else if (dat.length == 1) {
          strm.queuedSize -= dat[0];
          if (strm.ondrain)
            strm.ondrain(dat[0]);
        } else {
          if (dat[1])
            w.terminate();
          strm.ondata.call(strm, err2, dat[0], dat[1]);
        }
      });
      w.postMessage(opts2);
      strm.queuedSize = 0;
      strm.push = function(d, f) {
        if (!strm.ondata)
          err(5);
        if (t)
          strm.ondata(err(4, 0, 1), null, !!f);
        strm.queuedSize += d.length;
        w.postMessage([d, t = f], d.buffer instanceof ArrayBuffer ? [d.buffer] : []);
      };
      strm.terminate = function() {
        w.terminate();
      };
      if (flush) {
        strm.flush = function(sync) {
          w.postMessage([0, sync]);
        };
      }
    };
    var b2 = function(d, b) {
      return d[b] | d[b + 1] << 8;
    };
    var b4 = function(d, b) {
      return (d[b] | d[b + 1] << 8 | d[b + 2] << 16 | d[b + 3] << 24) >>> 0;
    };
    var b8 = function(d, b) {
      return b4(d, b) + b4(d, b + 4) * 4294967296;
    };
    var wbytes = function(d, b, v) {
      for (; v; ++b)
        d[b] = v, v >>>= 8;
    };
    var gzh = function(c, o) {
      var fn = o.filename;
      c[0] = 31, c[1] = 139, c[2] = 8, c[8] = o.level < 2 ? 4 : o.level == 9 ? 2 : 0, c[9] = 3;
      if (o.mtime != 0)
        wbytes(c, 4, Math.floor(new Date(o.mtime || Date.now()) / 1e3));
      if (fn) {
        c[3] = 8;
        for (var i2 = 0; i2 <= fn.length; ++i2)
          c[i2 + 10] = fn.charCodeAt(i2);
      }
    };
    var gzs = function(d) {
      if (d[0] != 31 || d[1] != 139 || d[2] != 8)
        err(6, "invalid gzip data");
      var flg = d[3];
      var st = 10;
      if (flg & 4)
        st += (d[10] | d[11] << 8) + 2;
      for (var zs = (flg >> 3 & 1) + (flg >> 4 & 1); zs > 0; zs -= !d[st++])
        ;
      return st + (flg & 2);
    };
    var gzl = function(d) {
      var l = d.length;
      return (d[l - 4] | d[l - 3] << 8 | d[l - 2] << 16 | d[l - 1] << 24) >>> 0;
    };
    var gzhl = function(o) {
      return 10 + (o.filename ? o.filename.length + 1 : 0);
    };
    var zlh = function(c, o) {
      var lv = o.level, fl2 = lv == 0 ? 0 : lv < 6 ? 1 : lv == 9 ? 3 : 2;
      c[0] = 120, c[1] = fl2 << 6 | (o.dictionary && 32);
      c[1] |= 31 - (c[0] << 8 | c[1]) % 31;
      if (o.dictionary) {
        var h = adler();
        h.p(o.dictionary);
        wbytes(c, 2, h.d());
      }
    };
    var zls = function(d, dict) {
      if ((d[0] & 15) != 8 || d[0] >> 4 > 7 || (d[0] << 8 | d[1]) % 31)
        err(6, "invalid zlib data");
      if ((d[1] >> 5 & 1) == +!dict)
        err(6, "invalid zlib data: " + (d[1] & 32 ? "need" : "unexpected") + " dictionary");
      return (d[1] >> 3 & 4) + 2;
    };
    function StrmOpt(opts2, cb) {
      if (typeof opts2 == "function")
        cb = opts2, opts2 = {};
      this.ondata = cb;
      return opts2;
    }
    var Deflate = /* @__PURE__ */ (function() {
      function Deflate2(opts2, cb) {
        if (typeof opts2 == "function")
          cb = opts2, opts2 = {};
        this.ondata = cb;
        this.o = opts2 || {};
        this.s = { l: 0, i: 32768, w: 32768, z: 32768 };
        this.b = new u8(98304);
        if (this.o.dictionary) {
          var dict = this.o.dictionary.subarray(-32768);
          this.b.set(dict, 32768 - dict.length);
          this.s.i = 32768 - dict.length;
        }
      }
      Deflate2.prototype.p = function(c, f) {
        this.ondata(dopt(c, this.o, 0, 0, this.s), f);
      };
      Deflate2.prototype.push = function(chunk, final) {
        if (!this.ondata)
          err(5);
        if (this.s.l)
          err(4);
        var endLen = chunk.length + this.s.z;
        if (endLen > this.b.length) {
          if (endLen > 2 * this.b.length - 32768) {
            var newBuf = new u8(endLen & -32768);
            newBuf.set(this.b.subarray(0, this.s.z));
            this.b = newBuf;
          }
          var split = this.b.length - this.s.z;
          this.b.set(chunk.subarray(0, split), this.s.z);
          this.s.z = this.b.length;
          this.p(this.b, false);
          this.b.set(this.b.subarray(-32768));
          this.b.set(chunk.subarray(split), 32768);
          this.s.z = chunk.length - split + 32768;
          this.s.i = 32766, this.s.w = 32768;
        } else {
          this.b.set(chunk, this.s.z);
          this.s.z += chunk.length;
        }
        this.s.l = final & 1;
        if (this.s.z > this.s.w + 8191 || final) {
          this.p(this.b, final || false);
          this.s.w = this.s.i, this.s.i -= 2;
        }
        if (final) {
          this.s = this.o = {};
          this.b = et;
        }
      };
      Deflate2.prototype.flush = function(sync) {
        if (!this.ondata)
          err(5);
        if (this.s.l)
          err(4);
        this.p(this.b, false);
        this.s.w = this.s.i, this.s.i -= 2;
        if (sync) {
          var c = new u8(6);
          c[0] = this.s.r >> 3;
          var ep = wfblk(c, this.s.r, et);
          this.s.r = 0;
          this.ondata(c.subarray(0, ep >> 3), false);
        }
      };
      return Deflate2;
    })();
    exports2.Deflate = Deflate;
    var AsyncDeflate = /* @__PURE__ */ (function() {
      function AsyncDeflate2(opts2, cb) {
        astrmify([
          bDflt,
          function() {
            return [astrm, Deflate];
          }
        ], this, StrmOpt.call(this, opts2, cb), function(ev) {
          var strm = new Deflate(ev.data);
          onmessage = astrm(strm);
        }, 6, 1);
      }
      return AsyncDeflate2;
    })();
    exports2.AsyncDeflate = AsyncDeflate;
    function deflate(data, opts2, cb) {
      if (!cb)
        cb = opts2, opts2 = {};
      if (typeof cb != "function")
        err(7);
      return cbify(data, opts2, [
        bDflt
      ], function(ev) {
        return pbf(deflateSync(ev.data[0], ev.data[1]));
      }, 0, cb);
    }
    function deflateSync(data, opts2) {
      return dopt(data, opts2 || {}, 0, 0);
    }
    var Inflate = /* @__PURE__ */ (function() {
      function Inflate2(opts2, cb) {
        if (typeof opts2 == "function")
          cb = opts2, opts2 = {};
        this.ondata = cb;
        var dict = opts2 && opts2.dictionary && opts2.dictionary.subarray(-32768);
        this.s = { i: 0, b: dict ? dict.length : 0 };
        this.o = new u8(32768);
        this.p = new u8(0);
        if (dict)
          this.o.set(dict);
      }
      Inflate2.prototype.e = function(c) {
        if (!this.ondata)
          err(5);
        if (this.d)
          err(4);
        if (!this.p.length)
          this.p = c;
        else if (c.length) {
          var n = new u8(this.p.length + c.length);
          n.set(this.p), n.set(c, this.p.length), this.p = n;
        }
      };
      Inflate2.prototype.c = function(final) {
        this.s.i = +(this.d = final || false);
        var bts = this.s.b;
        var dt = inflt(this.p, this.s, this.o);
        this.ondata(slc(dt, bts, this.s.b), this.d);
        this.o = slc(dt, this.s.b - 32768), this.s.b = this.o.length;
        this.p = slc(this.p, this.s.p / 8 | 0), this.s.p &= 7;
      };
      Inflate2.prototype.push = function(chunk, final) {
        this.e(chunk), this.c(final);
      };
      return Inflate2;
    })();
    exports2.Inflate = Inflate;
    var AsyncInflate = /* @__PURE__ */ (function() {
      function AsyncInflate2(opts2, cb) {
        astrmify([
          bInflt,
          function() {
            return [astrm, Inflate];
          }
        ], this, StrmOpt.call(this, opts2, cb), function(ev) {
          var strm = new Inflate(ev.data);
          onmessage = astrm(strm);
        }, 7, 0);
      }
      return AsyncInflate2;
    })();
    exports2.AsyncInflate = AsyncInflate;
    function inflate(data, opts2, cb) {
      if (!cb)
        cb = opts2, opts2 = {};
      if (typeof cb != "function")
        err(7);
      return cbify(data, opts2, [
        bInflt
      ], function(ev) {
        return pbf(inflateSync(ev.data[0], gopt(ev.data[1])));
      }, 1, cb);
    }
    function inflateSync(data, opts2) {
      return inflt(data, { i: 2 }, opts2 && opts2.out, opts2 && opts2.dictionary);
    }
    var Gzip = /* @__PURE__ */ (function() {
      function Gzip2(opts2, cb) {
        this.c = crc();
        this.l = 0;
        this.v = 1;
        Deflate.call(this, opts2, cb);
      }
      Gzip2.prototype.push = function(chunk, final) {
        this.c.p(chunk);
        this.l += chunk.length;
        Deflate.prototype.push.call(this, chunk, final);
      };
      Gzip2.prototype.p = function(c, f) {
        var raw = dopt(c, this.o, this.v && gzhl(this.o), f && 8, this.s);
        if (this.v)
          gzh(raw, this.o), this.v = 0;
        if (f)
          wbytes(raw, raw.length - 8, this.c.d()), wbytes(raw, raw.length - 4, this.l);
        this.ondata(raw, f);
      };
      Gzip2.prototype.flush = function(sync) {
        Deflate.prototype.flush.call(this, sync);
      };
      return Gzip2;
    })();
    exports2.Gzip = Gzip;
    exports2.Compress = Gzip;
    var AsyncGzip = /* @__PURE__ */ (function() {
      function AsyncGzip2(opts2, cb) {
        astrmify([
          bDflt,
          gze,
          function() {
            return [astrm, Deflate, Gzip];
          }
        ], this, StrmOpt.call(this, opts2, cb), function(ev) {
          var strm = new Gzip(ev.data);
          onmessage = astrm(strm);
        }, 8, 1);
      }
      return AsyncGzip2;
    })();
    exports2.AsyncGzip = AsyncGzip;
    exports2.AsyncCompress = AsyncGzip;
    function gzip(data, opts2, cb) {
      if (!cb)
        cb = opts2, opts2 = {};
      if (typeof cb != "function")
        err(7);
      return cbify(data, opts2, [
        bDflt,
        gze,
        function() {
          return [gzipSync];
        }
      ], function(ev) {
        return pbf(gzipSync(ev.data[0], ev.data[1]));
      }, 2, cb);
    }
    function gzipSync(data, opts2) {
      if (!opts2)
        opts2 = {};
      var c = crc(), l = data.length;
      c.p(data);
      var d = dopt(data, opts2, gzhl(opts2), 8), s = d.length;
      return gzh(d, opts2), wbytes(d, s - 8, c.d()), wbytes(d, s - 4, l), d;
    }
    var Gunzip = /* @__PURE__ */ (function() {
      function Gunzip2(opts2, cb) {
        this.v = 1;
        this.r = 0;
        Inflate.call(this, opts2, cb);
      }
      Gunzip2.prototype.push = function(chunk, final) {
        Inflate.prototype.e.call(this, chunk);
        this.r += chunk.length;
        if (this.v) {
          var p = this.p.subarray(this.v - 1);
          var s = p.length > 3 ? gzs(p) : 4;
          if (s > p.length) {
            if (!final)
              return;
          } else if (this.v > 1 && this.onmember) {
            this.onmember(this.r - p.length);
          }
          this.p = p.subarray(s), this.v = 0;
        }
        Inflate.prototype.c.call(this, 0);
        if (this.s.f && !this.s.l) {
          this.v = shft(this.s.p) + 9;
          this.s = { i: 0 };
          this.o = new u8(0);
          this.push(new u8(0), final);
        } else if (final) {
          Inflate.prototype.c.call(this, final);
        }
      };
      return Gunzip2;
    })();
    exports2.Gunzip = Gunzip;
    var AsyncGunzip = /* @__PURE__ */ (function() {
      function AsyncGunzip2(opts2, cb) {
        var _this = this;
        astrmify([
          bInflt,
          guze,
          function() {
            return [astrm, Inflate, Gunzip];
          }
        ], this, StrmOpt.call(this, opts2, cb), function(ev) {
          var strm = new Gunzip(ev.data);
          strm.onmember = function(offset) {
            return postMessage(offset);
          };
          onmessage = astrm(strm);
        }, 9, 0, function(offset) {
          return _this.onmember && _this.onmember(offset);
        });
      }
      return AsyncGunzip2;
    })();
    exports2.AsyncGunzip = AsyncGunzip;
    function gunzip(data, opts2, cb) {
      if (!cb)
        cb = opts2, opts2 = {};
      if (typeof cb != "function")
        err(7);
      return cbify(data, opts2, [
        bInflt,
        guze,
        function() {
          return [gunzipSync];
        }
      ], function(ev) {
        return pbf(gunzipSync(ev.data[0], ev.data[1]));
      }, 3, cb);
    }
    function gunzipSync(data, opts2) {
      var st = gzs(data);
      if (st + 8 > data.length)
        err(6, "invalid gzip data");
      return inflt(data.subarray(st, -8), { i: 2 }, opts2 && opts2.out || new u8(gzl(data)), opts2 && opts2.dictionary);
    }
    var Zlib = /* @__PURE__ */ (function() {
      function Zlib2(opts2, cb) {
        this.c = adler();
        this.v = 1;
        Deflate.call(this, opts2, cb);
      }
      Zlib2.prototype.push = function(chunk, final) {
        this.c.p(chunk);
        Deflate.prototype.push.call(this, chunk, final);
      };
      Zlib2.prototype.p = function(c, f) {
        var raw = dopt(c, this.o, this.v && (this.o.dictionary ? 6 : 2), f && 4, this.s);
        if (this.v)
          zlh(raw, this.o), this.v = 0;
        if (f)
          wbytes(raw, raw.length - 4, this.c.d());
        this.ondata(raw, f);
      };
      Zlib2.prototype.flush = function(sync) {
        Deflate.prototype.flush.call(this, sync);
      };
      return Zlib2;
    })();
    exports2.Zlib = Zlib;
    var AsyncZlib = /* @__PURE__ */ (function() {
      function AsyncZlib2(opts2, cb) {
        astrmify([
          bDflt,
          zle,
          function() {
            return [astrm, Deflate, Zlib];
          }
        ], this, StrmOpt.call(this, opts2, cb), function(ev) {
          var strm = new Zlib(ev.data);
          onmessage = astrm(strm);
        }, 10, 1);
      }
      return AsyncZlib2;
    })();
    exports2.AsyncZlib = AsyncZlib;
    function zlib(data, opts2, cb) {
      if (!cb)
        cb = opts2, opts2 = {};
      if (typeof cb != "function")
        err(7);
      return cbify(data, opts2, [
        bDflt,
        zle,
        function() {
          return [zlibSync];
        }
      ], function(ev) {
        return pbf(zlibSync(ev.data[0], ev.data[1]));
      }, 4, cb);
    }
    function zlibSync(data, opts2) {
      if (!opts2)
        opts2 = {};
      var a = adler();
      a.p(data);
      var d = dopt(data, opts2, opts2.dictionary ? 6 : 2, 4);
      return zlh(d, opts2), wbytes(d, d.length - 4, a.d()), d;
    }
    var Unzlib = /* @__PURE__ */ (function() {
      function Unzlib2(opts2, cb) {
        Inflate.call(this, opts2, cb);
        this.v = opts2 && opts2.dictionary ? 2 : 1;
      }
      Unzlib2.prototype.push = function(chunk, final) {
        Inflate.prototype.e.call(this, chunk);
        if (this.v) {
          if (this.p.length < 6 && !final)
            return;
          this.p = this.p.subarray(zls(this.p, this.v - 1)), this.v = 0;
        }
        if (final) {
          if (this.p.length < 4)
            err(6, "invalid zlib data");
          this.p = this.p.subarray(0, -4);
        }
        Inflate.prototype.c.call(this, final);
      };
      return Unzlib2;
    })();
    exports2.Unzlib = Unzlib;
    var AsyncUnzlib = /* @__PURE__ */ (function() {
      function AsyncUnzlib2(opts2, cb) {
        astrmify([
          bInflt,
          zule,
          function() {
            return [astrm, Inflate, Unzlib];
          }
        ], this, StrmOpt.call(this, opts2, cb), function(ev) {
          var strm = new Unzlib(ev.data);
          onmessage = astrm(strm);
        }, 11, 0);
      }
      return AsyncUnzlib2;
    })();
    exports2.AsyncUnzlib = AsyncUnzlib;
    function unzlib(data, opts2, cb) {
      if (!cb)
        cb = opts2, opts2 = {};
      if (typeof cb != "function")
        err(7);
      return cbify(data, opts2, [
        bInflt,
        zule,
        function() {
          return [unzlibSync];
        }
      ], function(ev) {
        return pbf(unzlibSync(ev.data[0], gopt(ev.data[1])));
      }, 5, cb);
    }
    function unzlibSync(data, opts2) {
      return inflt(data.subarray(zls(data, opts2 && opts2.dictionary), -4), { i: 2 }, opts2 && opts2.out, opts2 && opts2.dictionary);
    }
    var Decompress = /* @__PURE__ */ (function() {
      function Decompress2(opts2, cb) {
        this.o = StrmOpt.call(this, opts2, cb) || {};
        this.G = Gunzip;
        this.I = Inflate;
        this.Z = Unzlib;
      }
      Decompress2.prototype.i = function() {
        var _this = this;
        this.s.ondata = function(dat, final) {
          _this.ondata(dat, final);
        };
      };
      Decompress2.prototype.push = function(chunk, final) {
        if (!this.ondata)
          err(5);
        if (!this.s) {
          if (this.p && this.p.length) {
            var n = new u8(this.p.length + chunk.length);
            n.set(this.p), n.set(chunk, this.p.length);
          } else
            this.p = chunk;
          if (this.p.length > 2) {
            this.s = this.p[0] == 31 && this.p[1] == 139 && this.p[2] == 8 ? new this.G(this.o) : (this.p[0] & 15) != 8 || this.p[0] >> 4 > 7 || (this.p[0] << 8 | this.p[1]) % 31 ? new this.I(this.o) : new this.Z(this.o);
            this.i();
            this.s.push(this.p, final);
            this.p = null;
          }
        } else
          this.s.push(chunk, final);
      };
      return Decompress2;
    })();
    exports2.Decompress = Decompress;
    var AsyncDecompress = /* @__PURE__ */ (function() {
      function AsyncDecompress2(opts2, cb) {
        Decompress.call(this, opts2, cb);
        this.queuedSize = 0;
        this.G = AsyncGunzip;
        this.I = AsyncInflate;
        this.Z = AsyncUnzlib;
      }
      AsyncDecompress2.prototype.i = function() {
        var _this = this;
        this.s.ondata = function(err2, dat, final) {
          _this.ondata(err2, dat, final);
        };
        this.s.ondrain = function(size) {
          _this.queuedSize -= size;
          if (_this.ondrain)
            _this.ondrain(size);
        };
      };
      AsyncDecompress2.prototype.push = function(chunk, final) {
        this.queuedSize += chunk.length;
        Decompress.prototype.push.call(this, chunk, final);
      };
      return AsyncDecompress2;
    })();
    exports2.AsyncDecompress = AsyncDecompress;
    function decompress(data, opts2, cb) {
      if (!cb)
        cb = opts2, opts2 = {};
      if (typeof cb != "function")
        err(7);
      return data[0] == 31 && data[1] == 139 && data[2] == 8 ? gunzip(data, opts2, cb) : (data[0] & 15) != 8 || data[0] >> 4 > 7 || (data[0] << 8 | data[1]) % 31 ? inflate(data, opts2, cb) : unzlib(data, opts2, cb);
    }
    function decompressSync(data, opts2) {
      return data[0] == 31 && data[1] == 139 && data[2] == 8 ? gunzipSync(data, opts2) : (data[0] & 15) != 8 || data[0] >> 4 > 7 || (data[0] << 8 | data[1]) % 31 ? inflateSync(data, opts2) : unzlibSync(data, opts2);
    }
    var fltn = function(d, p, t, o) {
      for (var k in d) {
        var val = d[k], n = p + k, op = o;
        if (Array.isArray(val))
          op = mrg(o, val[1]), val = val[0];
        if (ArrayBuffer.isView(val))
          t[n] = [val, op];
        else {
          t[n += "/"] = [new u8(0), op];
          fltn(val, n, t, o);
        }
      }
    };
    var te = typeof TextEncoder != "undefined" && /* @__PURE__ */ new TextEncoder();
    var td = typeof TextDecoder != "undefined" && /* @__PURE__ */ new TextDecoder();
    var tds = 0;
    try {
      td.decode(et, { stream: true });
      tds = 1;
    } catch (e) {
    }
    var dutf8 = function(d) {
      for (var r = "", i2 = 0; ; ) {
        var c = d[i2++];
        var eb = (c > 127) + (c > 223) + (c > 239);
        if (i2 + eb > d.length)
          return { s: r, r: slc(d, i2 - 1) };
        if (!eb)
          r += String.fromCharCode(c);
        else if (eb == 3) {
          c = ((c & 15) << 18 | (d[i2++] & 63) << 12 | (d[i2++] & 63) << 6 | d[i2++] & 63) - 65536, r += String.fromCharCode(55296 | c >> 10, 56320 | c & 1023);
        } else if (eb & 1)
          r += String.fromCharCode((c & 31) << 6 | d[i2++] & 63);
        else
          r += String.fromCharCode((c & 15) << 12 | (d[i2++] & 63) << 6 | d[i2++] & 63);
      }
    };
    var DecodeUTF8 = /* @__PURE__ */ (function() {
      function DecodeUTF82(cb) {
        this.ondata = cb;
        if (tds)
          this.t = new TextDecoder();
        else
          this.p = et;
      }
      DecodeUTF82.prototype.push = function(chunk, final) {
        if (!this.ondata)
          err(5);
        final = !!final;
        if (this.t) {
          this.ondata(this.t.decode(chunk, { stream: true }), final);
          if (final) {
            if (this.t.decode().length)
              err(8);
            this.t = null;
          }
          return;
        }
        if (!this.p)
          err(4);
        var dat = new u8(this.p.length + chunk.length);
        dat.set(this.p);
        dat.set(chunk, this.p.length);
        var _a2 = dutf8(dat), s = _a2.s, r = _a2.r;
        if (final) {
          if (r.length)
            err(8);
          this.p = null;
        } else
          this.p = r;
        this.ondata(s, final);
      };
      return DecodeUTF82;
    })();
    exports2.DecodeUTF8 = DecodeUTF8;
    var EncodeUTF8 = /* @__PURE__ */ (function() {
      function EncodeUTF82(cb) {
        this.ondata = cb;
      }
      EncodeUTF82.prototype.push = function(chunk, final) {
        if (!this.ondata)
          err(5);
        if (this.d)
          err(4);
        this.ondata(strToU8(chunk), this.d = final || false);
      };
      return EncodeUTF82;
    })();
    exports2.EncodeUTF8 = EncodeUTF8;
    function strToU8(str, latin1) {
      if (latin1) {
        var ar_1 = new u8(str.length);
        for (var i2 = 0; i2 < str.length; ++i2)
          ar_1[i2] = str.charCodeAt(i2);
        return ar_1;
      }
      if (te)
        return te.encode(str);
      var l = str.length;
      var ar = new u8(str.length + (str.length >> 1));
      var ai = 0;
      var w = function(v) {
        ar[ai++] = v;
      };
      for (var i2 = 0; i2 < l; ++i2) {
        if (ai + 5 > ar.length) {
          var n = new u8(ai + 8 + (l - i2 << 1));
          n.set(ar);
          ar = n;
        }
        var c = str.charCodeAt(i2);
        if (c < 128 || latin1)
          w(c);
        else if (c < 2048)
          w(192 | c >> 6), w(128 | c & 63);
        else if (c > 55295 && c < 57344)
          c = 65536 + (c & 1023 << 10) | str.charCodeAt(++i2) & 1023, w(240 | c >> 18), w(128 | c >> 12 & 63), w(128 | c >> 6 & 63), w(128 | c & 63);
        else
          w(224 | c >> 12), w(128 | c >> 6 & 63), w(128 | c & 63);
      }
      return slc(ar, 0, ai);
    }
    function strFromU8(dat, latin1) {
      if (latin1) {
        var r = "";
        for (var i2 = 0; i2 < dat.length; i2 += 16384)
          r += String.fromCharCode.apply(null, dat.subarray(i2, i2 + 16384));
        return r;
      } else if (td) {
        return td.decode(dat);
      } else {
        var _a2 = dutf8(dat), s = _a2.s, r = _a2.r;
        if (r.length)
          err(8);
        return s;
      }
    }
    var dbf = function(l) {
      return l == 1 ? 3 : l < 6 ? 2 : l == 9 ? 1 : 0;
    };
    var slzh = function(d, b) {
      return b + 30 + b2(d, b + 26) + b2(d, b + 28);
    };
    var zh = function(d, b, z) {
      var fnl = b2(d, b + 28), efl = b2(d, b + 30), fn = strFromU8(d.subarray(b + 46, b + 46 + fnl), !(b2(d, b + 8) & 2048)), es = b + 46 + fnl;
      var _a2 = z64hs(d, es, efl, z, b4(d, b + 20), b4(d, b + 24), b4(d, b + 42)), sc = _a2[0], su = _a2[1], off = _a2[2];
      return [b2(d, b + 10), sc, su, fn, es + efl + b2(d, b + 32), off];
    };
    var z64hs = function(d, b, l, z, sc, su, off) {
      var nsc = sc == 4294967295, nsu = su == 4294967295, noff = off == 4294967295, e = b + l;
      var nf = nsc + nsu + noff;
      if (z && nf) {
        for (; b + 4 < e; b += 4 + b2(d, b + 2)) {
          if (b2(d, b) == 1) {
            return [
              nsc ? b8(d, b + 4 + 8 * nsu) : sc,
              nsu ? b8(d, b + 4) : su,
              noff ? b8(d, b + 4 + 8 * (nsu + nsc)) : off,
              1
            ];
          }
        }
        if (z < 2)
          err(13);
      }
      return [sc, su, off, 0];
    };
    var exfl = function(ex) {
      var le = 0;
      if (ex) {
        for (var k in ex) {
          var l = ex[k].length;
          if (l > 65535)
            err(9);
          le += l + 4;
        }
      }
      return le;
    };
    var wzh = function(d, b, f, fn, u, c, ce, co) {
      var fl2 = fn.length, ex = f.extra, col = co && co.length;
      var exl = exfl(ex);
      wbytes(d, b, ce != null ? 33639248 : 67324752), b += 4;
      if (ce != null)
        d[b++] = 20, d[b++] = f.os;
      d[b] = 20, b += 2;
      d[b++] = f.flag << 1 | (c < 0 && 8), d[b++] = u && 8;
      d[b++] = f.compression & 255, d[b++] = f.compression >> 8;
      var dt = new Date(f.mtime == null ? Date.now() : f.mtime), y = dt.getFullYear() - 1980;
      if (y < 0 || y > 119)
        err(10);
      wbytes(d, b, y << 25 | dt.getMonth() + 1 << 21 | dt.getDate() << 16 | dt.getHours() << 11 | dt.getMinutes() << 5 | dt.getSeconds() >> 1), b += 4;
      if (c != -1) {
        wbytes(d, b, f.crc);
        wbytes(d, b + 4, c < 0 ? -c - 2 : c);
        wbytes(d, b + 8, f.size);
      }
      wbytes(d, b + 12, fl2);
      wbytes(d, b + 14, exl), b += 16;
      if (ce != null) {
        wbytes(d, b, col);
        wbytes(d, b + 6, f.attrs);
        wbytes(d, b + 10, ce), b += 14;
      }
      d.set(fn, b);
      b += fl2;
      if (exl) {
        for (var k in ex) {
          var exf = ex[k], l = exf.length;
          wbytes(d, b, +k);
          wbytes(d, b + 2, l);
          d.set(exf, b + 4), b += 4 + l;
        }
      }
      if (col)
        d.set(co, b), b += col;
      return b;
    };
    var wzf = function(o, b, c, d, e) {
      wbytes(o, b, 101010256);
      wbytes(o, b + 8, c);
      wbytes(o, b + 10, c);
      wbytes(o, b + 12, d);
      wbytes(o, b + 16, e);
    };
    var ZipPassThrough = /* @__PURE__ */ (function() {
      function ZipPassThrough2(filename) {
        this.filename = filename;
        this.c = crc();
        this.size = 0;
        this.compression = 0;
      }
      ZipPassThrough2.prototype.process = function(chunk, final) {
        this.ondata(null, chunk, final);
      };
      ZipPassThrough2.prototype.push = function(chunk, final) {
        if (!this.ondata)
          err(5);
        this.c.p(chunk);
        this.size += chunk.length;
        if (final)
          this.crc = this.c.d();
        this.process(chunk, final || false);
      };
      return ZipPassThrough2;
    })();
    exports2.ZipPassThrough = ZipPassThrough;
    var ZipDeflate = /* @__PURE__ */ (function() {
      function ZipDeflate2(filename, opts2) {
        var _this = this;
        if (!opts2)
          opts2 = {};
        ZipPassThrough.call(this, filename);
        this.d = new Deflate(opts2, function(dat, final) {
          _this.ondata(null, dat, final);
        });
        this.compression = 8;
        this.flag = dbf(opts2.level);
      }
      ZipDeflate2.prototype.process = function(chunk, final) {
        try {
          this.d.push(chunk, final);
        } catch (e) {
          this.ondata(e, null, final);
        }
      };
      ZipDeflate2.prototype.push = function(chunk, final) {
        ZipPassThrough.prototype.push.call(this, chunk, final);
      };
      return ZipDeflate2;
    })();
    exports2.ZipDeflate = ZipDeflate;
    var AsyncZipDeflate = /* @__PURE__ */ (function() {
      function AsyncZipDeflate2(filename, opts2) {
        var _this = this;
        if (!opts2)
          opts2 = {};
        ZipPassThrough.call(this, filename);
        this.d = new AsyncDeflate(opts2, function(err2, dat, final) {
          _this.ondata(err2, dat, final);
        });
        this.compression = 8;
        this.flag = dbf(opts2.level);
        this.terminate = this.d.terminate;
      }
      AsyncZipDeflate2.prototype.process = function(chunk, final) {
        this.d.push(chunk, final);
      };
      AsyncZipDeflate2.prototype.push = function(chunk, final) {
        ZipPassThrough.prototype.push.call(this, chunk, final);
      };
      return AsyncZipDeflate2;
    })();
    exports2.AsyncZipDeflate = AsyncZipDeflate;
    var Zip = /* @__PURE__ */ (function() {
      function Zip2(cb) {
        this.ondata = cb;
        this.u = [];
        this.d = 1;
      }
      Zip2.prototype.add = function(file) {
        var _this = this;
        if (!this.ondata)
          err(5);
        if (this.d & 2)
          this.ondata(err(4 + (this.d & 1) * 8, 0, 1), null, false);
        else {
          var f = strToU8(file.filename), fl_1 = f.length;
          var com = file.comment, o = com && strToU8(com);
          var u = fl_1 != file.filename.length || o && com.length != o.length;
          var hl_1 = fl_1 + exfl(file.extra) + 30;
          if (fl_1 > 65535)
            this.ondata(err(11, 0, 1), null, false);
          var header = new u8(hl_1);
          wzh(header, 0, file, f, u, -1);
          var chks_1 = [header];
          var pAll_1 = function() {
            for (var _i = 0, chks_2 = chks_1; _i < chks_2.length; _i++) {
              var chk = chks_2[_i];
              _this.ondata(null, chk, false);
            }
            chks_1 = [];
          };
          var tr_1 = this.d;
          this.d = 0;
          var ind_1 = this.u.length;
          var uf_1 = mrg(file, {
            f,
            u,
            o,
            t: function() {
              if (file.terminate)
                file.terminate();
            },
            r: function() {
              pAll_1();
              if (tr_1) {
                var nxt = _this.u[ind_1 + 1];
                if (nxt)
                  nxt.r();
                else
                  _this.d = 1;
              }
              tr_1 = 1;
            }
          });
          var cl_1 = 0;
          file.ondata = function(err2, dat, final) {
            if (err2) {
              _this.ondata(err2, dat, final);
              _this.terminate();
            } else {
              cl_1 += dat.length;
              chks_1.push(dat);
              if (final) {
                var dd = new u8(16);
                wbytes(dd, 0, 134695760);
                wbytes(dd, 4, file.crc);
                wbytes(dd, 8, cl_1);
                wbytes(dd, 12, file.size);
                chks_1.push(dd);
                uf_1.c = cl_1, uf_1.b = hl_1 + cl_1 + 16, uf_1.crc = file.crc, uf_1.size = file.size;
                if (tr_1)
                  uf_1.r();
                tr_1 = 1;
              } else if (tr_1)
                pAll_1();
            }
          };
          this.u.push(uf_1);
        }
      };
      Zip2.prototype.end = function() {
        var _this = this;
        if (this.d & 2) {
          this.ondata(err(4 + (this.d & 1) * 8, 0, 1), null, true);
          return;
        }
        if (this.d)
          this.e();
        else
          this.u.push({
            r: function() {
              if (!(_this.d & 1))
                return;
              _this.u.splice(-1, 1);
              _this.e();
            },
            t: function() {
            }
          });
        this.d = 3;
      };
      Zip2.prototype.e = function() {
        var bt = 0, l = 0, tl = 0;
        for (var _i = 0, _a2 = this.u; _i < _a2.length; _i++) {
          var f = _a2[_i];
          tl += 46 + f.f.length + exfl(f.extra) + (f.o ? f.o.length : 0);
        }
        var out = new u8(tl + 22);
        for (var _b2 = 0, _c = this.u; _b2 < _c.length; _b2++) {
          var f = _c[_b2];
          wzh(out, bt, f, f.f, f.u, -f.c - 2, l, f.o);
          bt += 46 + f.f.length + exfl(f.extra) + (f.o ? f.o.length : 0), l += f.b;
        }
        wzf(out, bt, this.u.length, tl, l);
        this.ondata(null, out, true);
        this.d = 2;
      };
      Zip2.prototype.terminate = function() {
        for (var _i = 0, _a2 = this.u; _i < _a2.length; _i++) {
          var f = _a2[_i];
          f.t();
        }
        this.d = 2;
      };
      return Zip2;
    })();
    exports2.Zip = Zip;
    function zip(data, opts2, cb) {
      if (!cb)
        cb = opts2, opts2 = {};
      if (typeof cb != "function")
        err(7);
      var r = {};
      fltn(data, "", r, opts2);
      var k = Object.keys(r);
      var lft = k.length, o = 0, tot = 0;
      var slft = lft, files = new Array(lft);
      var term = [];
      var tAll = function() {
        for (var i3 = 0; i3 < term.length; ++i3)
          term[i3]();
      };
      var cbd = function(a, b) {
        mt(function() {
          cb(a, b);
        });
      };
      mt(function() {
        cbd = cb;
      });
      var cbf = function() {
        var out = new u8(tot + 22), oe = o, cdl = tot - o;
        tot = 0;
        for (var i3 = 0; i3 < slft; ++i3) {
          var f = files[i3];
          try {
            var l = f.c.length;
            wzh(out, tot, f, f.f, f.u, l);
            var badd = 30 + f.f.length + exfl(f.extra);
            var loc = tot + badd;
            out.set(f.c, loc);
            wzh(out, o, f, f.f, f.u, l, tot, f.m), o += 16 + badd + (f.m ? f.m.length : 0), tot = loc + l;
          } catch (e) {
            return cbd(e, null);
          }
        }
        wzf(out, o, files.length, cdl, oe);
        cbd(null, out);
      };
      if (!lft)
        cbf();
      var _loop_1 = function(i3) {
        var fn = k[i3];
        var _a2 = r[fn], file = _a2[0], p = _a2[1];
        var c = crc(), size = file.length;
        c.p(file);
        var f = strToU8(fn), s = f.length;
        var com = p.comment, m = com && strToU8(com), ms = m && m.length;
        var exl = exfl(p.extra);
        var compression = p.level == 0 ? 0 : 8;
        var cbl = function(e, d) {
          if (e) {
            tAll();
            cbd(e, null);
          } else {
            var l = d.length;
            files[i3] = mrg(p, {
              size,
              crc: c.d(),
              c: d,
              f,
              m,
              u: s != fn.length || m && com.length != ms,
              compression
            });
            o += 30 + s + exl + l;
            tot += 76 + 2 * (s + exl) + (ms || 0) + l;
            if (!--lft)
              cbf();
          }
        };
        if (s > 65535)
          cbl(err(11, 0, 1), null);
        if (!compression)
          cbl(null, file);
        else if (size < 16e4) {
          try {
            cbl(null, deflateSync(file, p));
          } catch (e) {
            cbl(e, null);
          }
        } else
          term.push(deflate(file, p, cbl));
      };
      for (var i2 = 0; i2 < slft; ++i2) {
        _loop_1(i2);
      }
      return tAll;
    }
    function zipSync(data, opts2) {
      if (!opts2)
        opts2 = {};
      var r = {};
      var files = [];
      fltn(data, "", r, opts2);
      var o = 0;
      var tot = 0;
      for (var fn in r) {
        var _a2 = r[fn], file = _a2[0], p = _a2[1];
        var compression = p.level == 0 ? 0 : 8;
        var f = strToU8(fn), s = f.length;
        var com = p.comment, m = com && strToU8(com), ms = m && m.length;
        var exl = exfl(p.extra);
        if (s > 65535)
          err(11);
        var d = compression ? deflateSync(file, p) : file, l = d.length;
        var c = crc();
        c.p(file);
        files.push(mrg(p, {
          size: file.length,
          crc: c.d(),
          c: d,
          f,
          m,
          u: s != fn.length || m && com.length != ms,
          o,
          compression
        }));
        o += 30 + s + exl + l;
        tot += 76 + 2 * (s + exl) + (ms || 0) + l;
      }
      var out = new u8(tot + 22), oe = o, cdl = tot - o;
      for (var i2 = 0; i2 < files.length; ++i2) {
        var f = files[i2];
        wzh(out, f.o, f, f.f, f.u, f.c.length);
        var badd = 30 + f.f.length + exfl(f.extra);
        out.set(f.c, f.o + badd);
        wzh(out, o, f, f.f, f.u, f.c.length, f.o, f.m), o += 16 + badd + (f.m ? f.m.length : 0);
      }
      wzf(out, o, files.length, cdl, oe);
      return out;
    }
    var UnzipPassThrough = /* @__PURE__ */ (function() {
      function UnzipPassThrough2() {
      }
      UnzipPassThrough2.prototype.push = function(chunk, final) {
        this.ondata(null, chunk, final);
      };
      UnzipPassThrough2.compression = 0;
      return UnzipPassThrough2;
    })();
    exports2.UnzipPassThrough = UnzipPassThrough;
    var UnzipInflate = /* @__PURE__ */ (function() {
      function UnzipInflate2() {
        var _this = this;
        this.i = new Inflate(function(dat, final) {
          _this.ondata(null, dat, final);
        });
      }
      UnzipInflate2.prototype.push = function(chunk, final) {
        try {
          this.i.push(chunk, final);
        } catch (e) {
          this.ondata(e, null, final);
        }
      };
      UnzipInflate2.compression = 8;
      return UnzipInflate2;
    })();
    exports2.UnzipInflate = UnzipInflate;
    var AsyncUnzipInflate = /* @__PURE__ */ (function() {
      function AsyncUnzipInflate2(_, sz) {
        var _this = this;
        if (sz < 32e4) {
          this.i = new Inflate(function(dat, final) {
            _this.ondata(null, dat, final);
          });
        } else {
          this.i = new AsyncInflate(function(err2, dat, final) {
            _this.ondata(err2, dat, final);
          });
          this.terminate = this.i.terminate;
        }
      }
      AsyncUnzipInflate2.prototype.push = function(chunk, final) {
        if (this.i.terminate)
          chunk = slc(chunk, 0);
        this.i.push(chunk, final);
      };
      AsyncUnzipInflate2.compression = 8;
      return AsyncUnzipInflate2;
    })();
    exports2.AsyncUnzipInflate = AsyncUnzipInflate;
    var Unzip = /* @__PURE__ */ (function() {
      function Unzip2(cb) {
        this.onfile = cb;
        this.k = [];
        this.o = {
          0: UnzipPassThrough
        };
        this.p = et;
      }
      Unzip2.prototype.push = function(chunk, final) {
        var _this = this;
        if (!this.onfile)
          err(5);
        if (!this.p)
          err(4);
        if (this.c > 0) {
          var len = Math.min(this.c, chunk.length);
          var toAdd = chunk.subarray(0, len);
          this.c -= len;
          if (this.d)
            this.d.push(toAdd, !this.c);
          else
            this.k[0].push(toAdd);
          chunk = chunk.subarray(len);
          if (chunk.length)
            return this.push(chunk, final);
        } else {
          var f = 0, i2 = 0, is = void 0, buf = void 0;
          if (!this.p.length)
            buf = chunk;
          else if (!chunk.length)
            buf = this.p;
          else {
            buf = new u8(this.p.length + chunk.length);
            buf.set(this.p), buf.set(chunk, this.p.length);
          }
          var l = buf.length, oc = this.c, add = oc && this.d;
          var _loop_2 = function() {
            var sig = b4(buf, i2);
            if (sig == 67324752) {
              f = 1, is = i2;
              this_1.d = null;
              this_1.c = 0;
              var bf = b2(buf, i2 + 6), cmp_1 = b2(buf, i2 + 8), u = bf & 2048, dd = bf & 8, fnl = b2(buf, i2 + 26), es = b2(buf, i2 + 28);
              if (l > i2 + 30 + fnl + es) {
                var chks_3 = [];
                this_1.k.unshift(chks_3);
                f = 2;
                var lsc = b4(buf, i2 + 18), lsu = b4(buf, i2 + 22);
                var fn_1 = strFromU8(buf.subarray(i2 + 30, i2 += 30 + fnl), !u);
                var _a2 = z64hs(buf, i2, es, 2, lsc, lsu, 0), sc_1 = _a2[0], su_1 = _a2[1], z64 = _a2[3];
                if (dd)
                  sc_1 = -1 - z64;
                i2 += es;
                this_1.c = sc_1;
                var d_1;
                var file_1 = {
                  name: fn_1,
                  compression: cmp_1,
                  start: function() {
                    if (!file_1.ondata)
                      err(5);
                    if (!sc_1)
                      file_1.ondata(null, et, true);
                    else {
                      var ctr = _this.o[cmp_1];
                      if (!ctr)
                        file_1.ondata(err(14, "unknown compression type " + cmp_1, 1), null, false);
                      d_1 = sc_1 < 0 ? new ctr(fn_1) : new ctr(fn_1, sc_1, su_1);
                      d_1.ondata = function(err2, dat3, final2) {
                        file_1.ondata(err2, dat3, final2);
                      };
                      for (var _i = 0, chks_4 = chks_3; _i < chks_4.length; _i++) {
                        var dat2 = chks_4[_i];
                        d_1.push(dat2, false);
                      }
                      if (_this.k[0] == chks_3 && _this.c)
                        _this.d = d_1;
                      else
                        d_1.push(et, true);
                    }
                  },
                  terminate: function() {
                    if (d_1 && d_1.terminate)
                      d_1.terminate();
                  }
                };
                if (sc_1 >= 0)
                  file_1.size = sc_1, file_1.originalSize = su_1;
                this_1.onfile(file_1);
              }
              return "break";
            } else if (oc) {
              if (sig == 134695760) {
                is = i2 += 12 + (oc == -2 && 8), f = 3, this_1.c = 0;
                return "break";
              } else if (sig == 33639248) {
                is = i2 -= 4, f = 3, this_1.c = 0;
                return "break";
              }
            }
          };
          var this_1 = this;
          for (; i2 < l - 4; ++i2) {
            var state_1 = _loop_2();
            if (state_1 === "break")
              break;
          }
          this.p = et;
          if (oc < 0) {
            var dat = f ? buf.subarray(0, is - 12 - (oc == -2 && 8) - (b4(buf, is - 16) == 134695760 && 4)) : buf.subarray(0, i2);
            if (add)
              add.push(dat, !!f);
            else
              this.k[+(f == 2)].push(dat);
          }
          if (f & 2)
            return this.push(buf.subarray(i2), final);
          this.p = buf.subarray(i2);
        }
        if (final) {
          if (this.c)
            err(13);
          this.p = null;
        }
      };
      Unzip2.prototype.register = function(decoder) {
        this.o[decoder.compression] = decoder;
      };
      return Unzip2;
    })();
    exports2.Unzip = Unzip;
    var mt = typeof queueMicrotask == "function" ? queueMicrotask : typeof setTimeout == "function" ? setTimeout : function(fn) {
      fn();
    };
    function unzip(data, opts2, cb) {
      if (!cb)
        cb = opts2, opts2 = {};
      if (typeof cb != "function")
        err(7);
      var term = [];
      var tAll = function() {
        for (var i3 = 0; i3 < term.length; ++i3)
          term[i3]();
      };
      var files = {};
      var cbd = function(a, b) {
        mt(function() {
          cb(a, b);
        });
      };
      mt(function() {
        cbd = cb;
      });
      var e = data.length - 22;
      for (; b4(data, e) != 101010256; --e) {
        if (!e || data.length - e > 65558) {
          cbd(err(13, 0, 1), null);
          return tAll;
        }
      }
      ;
      var lft = b2(data, e + 8);
      if (lft) {
        var c = lft;
        var o = b4(data, e + 16);
        var z = b4(data, e - 20) == 117853008;
        if (z) {
          var ze = b4(data, e - 12);
          z = b4(data, ze) == 101075792;
          if (z) {
            c = lft = b4(data, ze + 32);
            o = b4(data, ze + 48);
          }
        }
        var fltr = opts2 && opts2.filter;
        var _loop_3 = function(i3) {
          var _a2 = zh(data, o, z), c_1 = _a2[0], sc = _a2[1], su = _a2[2], fn = _a2[3], no = _a2[4], off = _a2[5], b = slzh(data, off);
          o = no;
          var cbl = function(e2, d) {
            if (e2) {
              tAll();
              cbd(e2, null);
            } else {
              if (d)
                files[fn] = d;
              if (!--lft)
                cbd(null, files);
            }
          };
          if (!fltr || fltr({
            name: fn,
            size: sc,
            originalSize: su,
            compression: c_1
          })) {
            if (!c_1)
              cbl(null, slc(data, b, b + sc));
            else if (c_1 == 8) {
              var infl = data.subarray(b, b + sc);
              if (su < 524288 || sc > 0.8 * su) {
                try {
                  cbl(null, inflateSync(infl, { out: new u8(su) }));
                } catch (e2) {
                  cbl(e2, null);
                }
              } else
                term.push(inflate(infl, { size: su }, cbl));
            } else
              cbl(err(14, "unknown compression type " + c_1, 1), null);
          } else
            cbl(null, null);
        };
        for (var i2 = 0; i2 < c; ++i2) {
          _loop_3(i2);
        }
      } else
        cbd(null, {});
      return tAll;
    }
    function unzipSync(data, opts2) {
      var files = {};
      var e = data.length - 22;
      for (; b4(data, e) != 101010256; --e) {
        if (!e || data.length - e > 65558)
          err(13);
      }
      ;
      var c = b2(data, e + 8);
      if (!c)
        return {};
      var o = b4(data, e + 16);
      var z = b4(data, e - 20) == 117853008;
      if (z) {
        var ze = b4(data, e - 12);
        z = b4(data, ze) == 101075792;
        if (z) {
          c = b4(data, ze + 32);
          o = b4(data, ze + 48);
        }
      }
      var fltr = opts2 && opts2.filter;
      for (var i2 = 0; i2 < c; ++i2) {
        var _a2 = zh(data, o, z), c_2 = _a2[0], sc = _a2[1], su = _a2[2], fn = _a2[3], no = _a2[4], off = _a2[5], b = slzh(data, off);
        o = no;
        if (!fltr || fltr({
          name: fn,
          size: sc,
          originalSize: su,
          compression: c_2
        })) {
          if (!c_2)
            files[fn] = slc(data, b, b + sc);
          else if (c_2 == 8)
            files[fn] = inflateSync(data.subarray(b, b + sc), { out: new u8(su) });
          else
            err(14, "unknown compression type " + c_2);
        }
      }
      return files;
    }
  }
});

// node_modules/iobuffer/lib/text.js
var require_text = __commonJS({
  "node_modules/iobuffer/lib/text.js"(exports2) {
    "use strict";
    Object.defineProperty(exports2, "__esModule", { value: true });
    exports2.decode = decode;
    exports2.encode = encode;
    function decode(bytes, encoding = "utf8") {
      const decoder = new TextDecoder(encoding);
      return decoder.decode(bytes);
    }
    var encoder = new TextEncoder();
    function encode(str) {
      return encoder.encode(str);
    }
  }
});

// node_modules/iobuffer/lib/IOBuffer.js
var require_IOBuffer = __commonJS({
  "node_modules/iobuffer/lib/IOBuffer.js"(exports2) {
    "use strict";
    Object.defineProperty(exports2, "__esModule", { value: true });
    exports2.IOBuffer = void 0;
    var text_1 = require_text();
    var defaultByteLength = 1024 * 8;
    var hostBigEndian = (() => {
      const array = new Uint8Array(4);
      const view = new Uint32Array(array.buffer);
      return !((view[0] = 1) & array[0]);
    })();
    var typedArrays = {
      int8: globalThis.Int8Array,
      uint8: globalThis.Uint8Array,
      int16: globalThis.Int16Array,
      uint16: globalThis.Uint16Array,
      int32: globalThis.Int32Array,
      uint32: globalThis.Uint32Array,
      uint64: globalThis.BigUint64Array,
      int64: globalThis.BigInt64Array,
      float32: globalThis.Float32Array,
      float64: globalThis.Float64Array
    };
    var IOBuffer = class _IOBuffer {
      /**
       * Reference to the internal ArrayBuffer object.
       */
      buffer;
      /**
       * Byte length of the internal ArrayBuffer.
       */
      byteLength;
      /**
       * Byte offset of the internal ArrayBuffer.
       */
      byteOffset;
      /**
       * Byte length of the internal ArrayBuffer.
       */
      length;
      /**
       * The current offset of the buffer's pointer.
       */
      offset;
      lastWrittenByte;
      littleEndian;
      _data;
      _mark;
      _marks;
      /**
       * Create a new IOBuffer.
       * @param data - The data to construct the IOBuffer with.
       * If data is a number, it will be the new buffer's length<br>
       * If data is `undefined`, the buffer will be initialized with a default length of 8Kb<br>
       * If data is an ArrayBuffer, SharedArrayBuffer, an ArrayBufferView (Typed Array), an IOBuffer instance,
       * or a Node.js Buffer, a view will be created over the underlying ArrayBuffer.
       * @param options - An object for the options.
       * @returns A new IOBuffer instance.
       */
      constructor(data = defaultByteLength, options = {}) {
        let dataIsGiven = false;
        if (typeof data === "number") {
          data = new ArrayBuffer(data);
        } else {
          dataIsGiven = true;
          this.lastWrittenByte = data.byteLength;
        }
        const offset = options.offset ? options.offset >>> 0 : 0;
        const byteLength = data.byteLength - offset;
        let dvOffset = offset;
        if (ArrayBuffer.isView(data) || data instanceof _IOBuffer) {
          if (data.byteLength !== data.buffer.byteLength) {
            dvOffset = data.byteOffset + offset;
          }
          data = data.buffer;
        }
        if (dataIsGiven) {
          this.lastWrittenByte = byteLength;
        } else {
          this.lastWrittenByte = 0;
        }
        this.buffer = data;
        this.length = byteLength;
        this.byteLength = byteLength;
        this.byteOffset = dvOffset;
        this.offset = 0;
        this.littleEndian = true;
        this._data = new DataView(this.buffer, dvOffset, byteLength);
        this._mark = 0;
        this._marks = [];
      }
      /**
       * Checks if the memory allocated to the buffer is sufficient to store more
       * bytes after the offset.
       * @param byteLength - The needed memory in bytes.
       * @returns `true` if there is sufficient space and `false` otherwise.
       */
      available(byteLength = 1) {
        return this.offset + byteLength <= this.length;
      }
      /**
       * Check if little-endian mode is used for reading and writing multi-byte
       * values.
       * @returns `true` if little-endian mode is used, `false` otherwise.
       */
      isLittleEndian() {
        return this.littleEndian;
      }
      /**
       * Set little-endian mode for reading and writing multi-byte values.
       * @returns This.
       */
      setLittleEndian() {
        this.littleEndian = true;
        return this;
      }
      /**
       * Check if big-endian mode is used for reading and writing multi-byte values.
       * @returns `true` if big-endian mode is used, `false` otherwise.
       */
      isBigEndian() {
        return !this.littleEndian;
      }
      /**
       * Switches to big-endian mode for reading and writing multi-byte values.
       * @returns This.
       */
      setBigEndian() {
        this.littleEndian = false;
        return this;
      }
      /**
       * Move the pointer n bytes forward.
       * @param n - Number of bytes to skip.
       * @returns This.
       */
      skip(n = 1) {
        this.offset += n;
        return this;
      }
      /**
       * Move the pointer n bytes backward.
       * @param n - Number of bytes to move back.
       * @returns This.
       */
      back(n = 1) {
        this.offset -= n;
        return this;
      }
      /**
       * Move the pointer to the given offset.
       * @param offset - The offset to move to.
       * @returns This.
       */
      seek(offset) {
        this.offset = offset;
        return this;
      }
      /**
       * Store the current pointer offset.
       * @see {@link IOBuffer#reset}
       * @returns This.
       */
      mark() {
        this._mark = this.offset;
        return this;
      }
      /**
       * Move the pointer back to the last pointer offset set by mark.
       * @see {@link IOBuffer#mark}
       * @returns This.
       */
      reset() {
        this.offset = this._mark;
        return this;
      }
      /**
       * Push the current pointer offset to the mark stack.
       * @see {@link IOBuffer#popMark}
       * @returns This.
       */
      pushMark() {
        this._marks.push(this.offset);
        return this;
      }
      /**
       * Pop the last pointer offset from the mark stack, and set the current
       * pointer offset to the popped value.
       * @see {@link IOBuffer#pushMark}
       * @returns This.
       */
      popMark() {
        const offset = this._marks.pop();
        if (offset === void 0) {
          throw new Error("Mark stack empty");
        }
        this.seek(offset);
        return this;
      }
      /**
       * Move the pointer offset back to 0.
       * @returns This.
       */
      rewind() {
        this.offset = 0;
        return this;
      }
      /**
       * Make sure the buffer has sufficient memory to write a given byteLength at
       * the current pointer offset.
       * If the buffer's memory is insufficient, this method will create a new
       * buffer (a copy) with a length that is twice (byteLength + current offset).
       * @param byteLength - The needed memory in bytes.
       * @returns This.
       */
      ensureAvailable(byteLength = 1) {
        if (!this.available(byteLength)) {
          const lengthNeeded = this.offset + byteLength;
          const newLength = lengthNeeded * 2;
          const newArray = new Uint8Array(newLength);
          newArray.set(new Uint8Array(this.buffer));
          this.buffer = newArray.buffer;
          this.length = newLength;
          this.byteLength = newLength;
          this._data = new DataView(this.buffer);
        }
        return this;
      }
      /**
       * Read a byte and return false if the byte's value is 0, or true otherwise.
       * Moves pointer forward by one byte.
       * @returns The read boolean.
       */
      readBoolean() {
        return this.readUint8() !== 0;
      }
      /**
       * Read a signed 8-bit integer and move pointer forward by 1 byte.
       * @returns The read byte.
       */
      readInt8() {
        return this._data.getInt8(this.offset++);
      }
      /**
       * Read an unsigned 8-bit integer and move pointer forward by 1 byte.
       * @returns The read byte.
       */
      readUint8() {
        return this._data.getUint8(this.offset++);
      }
      /**
       * Alias for {@link IOBuffer#readUint8}.
       * @returns The read byte.
       */
      readByte() {
        return this.readUint8();
      }
      /**
       * Read `n` bytes and move pointer forward by `n` bytes.
       * @param n - Number of bytes to read.
       * @returns The read bytes.
       */
      readBytes(n = 1) {
        return this.readArray(n, "uint8");
      }
      /**
       * Creates an array of corresponding to the type `type` and size `size`.
       * For example type `uint8` will create a `Uint8Array`.
       * @param size - size of the resulting array
       * @param type - number type of elements to read
       * @returns The read array.
       */
      readArray(size, type) {
        const bytes = typedArrays[type].BYTES_PER_ELEMENT * size;
        const offset = this.byteOffset + this.offset;
        const slice = this.buffer.slice(offset, offset + bytes);
        if (this.littleEndian === hostBigEndian && type !== "uint8" && type !== "int8") {
          const slice2 = new Uint8Array(this.buffer.slice(offset, offset + bytes));
          slice2.reverse();
          const returnArray2 = new typedArrays[type](slice2.buffer);
          this.offset += bytes;
          returnArray2.reverse();
          return returnArray2;
        }
        const returnArray = new typedArrays[type](slice);
        this.offset += bytes;
        return returnArray;
      }
      /**
       * Read a 16-bit signed integer and move pointer forward by 2 bytes.
       * @returns The read value.
       */
      readInt16() {
        const value = this._data.getInt16(this.offset, this.littleEndian);
        this.offset += 2;
        return value;
      }
      /**
       * Read a 16-bit unsigned integer and move pointer forward by 2 bytes.
       * @returns The read value.
       */
      readUint16() {
        const value = this._data.getUint16(this.offset, this.littleEndian);
        this.offset += 2;
        return value;
      }
      /**
       * Read a 32-bit signed integer and move pointer forward by 4 bytes.
       * @returns The read value.
       */
      readInt32() {
        const value = this._data.getInt32(this.offset, this.littleEndian);
        this.offset += 4;
        return value;
      }
      /**
       * Read a 32-bit unsigned integer and move pointer forward by 4 bytes.
       * @returns The read value.
       */
      readUint32() {
        const value = this._data.getUint32(this.offset, this.littleEndian);
        this.offset += 4;
        return value;
      }
      /**
       * Read a 32-bit floating number and move pointer forward by 4 bytes.
       * @returns The read value.
       */
      readFloat32() {
        const value = this._data.getFloat32(this.offset, this.littleEndian);
        this.offset += 4;
        return value;
      }
      /**
       * Read a 64-bit floating number and move pointer forward by 8 bytes.
       * @returns The read value.
       */
      readFloat64() {
        const value = this._data.getFloat64(this.offset, this.littleEndian);
        this.offset += 8;
        return value;
      }
      /**
       * Read a 64-bit signed integer number and move pointer forward by 8 bytes.
       * @returns The read value.
       */
      readBigInt64() {
        const value = this._data.getBigInt64(this.offset, this.littleEndian);
        this.offset += 8;
        return value;
      }
      /**
       * Read a 64-bit unsigned integer number and move pointer forward by 8 bytes.
       * @returns The read value.
       */
      readBigUint64() {
        const value = this._data.getBigUint64(this.offset, this.littleEndian);
        this.offset += 8;
        return value;
      }
      /**
       * Read a 1-byte ASCII character and move pointer forward by 1 byte.
       * @returns The read character.
       */
      readChar() {
        return String.fromCharCode(this.readInt8());
      }
      /**
       * Read `n` 1-byte ASCII characters and move pointer forward by `n` bytes.
       * @param n - Number of characters to read.
       * @returns The read characters.
       */
      readChars(n = 1) {
        let result = "";
        for (let i = 0; i < n; i++) {
          result += this.readChar();
        }
        return result;
      }
      /**
       * Read the next `n` bytes, return a UTF-8 decoded string and move pointer
       * forward by `n` bytes.
       * @param n - Number of bytes to read.
       * @returns The decoded string.
       */
      readUtf8(n = 1) {
        return (0, text_1.decode)(this.readBytes(n));
      }
      /**
       * Read the next `n` bytes, return a string decoded with `encoding` and move pointer
       * forward by `n` bytes.
       * If no encoding is passed, the function is equivalent to @see {@link IOBuffer#readUtf8}
       * @param n - Number of bytes to read.
       * @param encoding - The encoding to use. Default is 'utf8'.
       * @returns The decoded string.
       */
      decodeText(n = 1, encoding = "utf8") {
        return (0, text_1.decode)(this.readBytes(n), encoding);
      }
      /**
       * Write 0xff if the passed value is truthy, 0x00 otherwise and move pointer
       * forward by 1 byte.
       * @param value - The value to write.
       * @returns This.
       */
      writeBoolean(value) {
        this.writeUint8(value ? 255 : 0);
        return this;
      }
      /**
       * Write `value` as an 8-bit signed integer and move pointer forward by 1 byte.
       * @param value - The value to write.
       * @returns This.
       */
      writeInt8(value) {
        this.ensureAvailable(1);
        this._data.setInt8(this.offset++, value);
        this._updateLastWrittenByte();
        return this;
      }
      /**
       * Write `value` as an 8-bit unsigned integer and move pointer forward by 1
       * byte.
       * @param value - The value to write.
       * @returns This.
       */
      writeUint8(value) {
        this.ensureAvailable(1);
        this._data.setUint8(this.offset++, value);
        this._updateLastWrittenByte();
        return this;
      }
      /**
       * An alias for {@link IOBuffer#writeUint8}.
       * @param value - The value to write.
       * @returns This.
       */
      writeByte(value) {
        return this.writeUint8(value);
      }
      /**
       * Write all elements of `bytes` as uint8 values and move pointer forward by
       * `bytes.length` bytes.
       * @param bytes - The array of bytes to write.
       * @returns This.
       */
      writeBytes(bytes) {
        this.ensureAvailable(bytes.length);
        for (let i = 0; i < bytes.length; i++) {
          this._data.setUint8(this.offset++, bytes[i]);
        }
        this._updateLastWrittenByte();
        return this;
      }
      /**
       * Write `value` as a 16-bit signed integer and move pointer forward by 2
       * bytes.
       * @param value - The value to write.
       * @returns This.
       */
      writeInt16(value) {
        this.ensureAvailable(2);
        this._data.setInt16(this.offset, value, this.littleEndian);
        this.offset += 2;
        this._updateLastWrittenByte();
        return this;
      }
      /**
       * Write `value` as a 16-bit unsigned integer and move pointer forward by 2
       * bytes.
       * @param value - The value to write.
       * @returns This.
       */
      writeUint16(value) {
        this.ensureAvailable(2);
        this._data.setUint16(this.offset, value, this.littleEndian);
        this.offset += 2;
        this._updateLastWrittenByte();
        return this;
      }
      /**
       * Write `value` as a 32-bit signed integer and move pointer forward by 4
       * bytes.
       * @param value - The value to write.
       * @returns This.
       */
      writeInt32(value) {
        this.ensureAvailable(4);
        this._data.setInt32(this.offset, value, this.littleEndian);
        this.offset += 4;
        this._updateLastWrittenByte();
        return this;
      }
      /**
       * Write `value` as a 32-bit unsigned integer and move pointer forward by 4
       * bytes.
       * @param value - The value to write.
       * @returns This.
       */
      writeUint32(value) {
        this.ensureAvailable(4);
        this._data.setUint32(this.offset, value, this.littleEndian);
        this.offset += 4;
        this._updateLastWrittenByte();
        return this;
      }
      /**
       * Write `value` as a 32-bit floating number and move pointer forward by 4
       * bytes.
       * @param value - The value to write.
       * @returns This.
       */
      writeFloat32(value) {
        this.ensureAvailable(4);
        this._data.setFloat32(this.offset, value, this.littleEndian);
        this.offset += 4;
        this._updateLastWrittenByte();
        return this;
      }
      /**
       * Write `value` as a 64-bit floating number and move pointer forward by 8
       * bytes.
       * @param value - The value to write.
       * @returns This.
       */
      writeFloat64(value) {
        this.ensureAvailable(8);
        this._data.setFloat64(this.offset, value, this.littleEndian);
        this.offset += 8;
        this._updateLastWrittenByte();
        return this;
      }
      /**
       * Write `value` as a 64-bit signed bigint and move pointer forward by 8
       * bytes.
       * @param value - The value to write.
       * @returns This.
       */
      writeBigInt64(value) {
        this.ensureAvailable(8);
        this._data.setBigInt64(this.offset, value, this.littleEndian);
        this.offset += 8;
        this._updateLastWrittenByte();
        return this;
      }
      /**
       * Write `value` as a 64-bit unsigned bigint and move pointer forward by 8
       * bytes.
       * @param value - The value to write.
       * @returns This.
       */
      writeBigUint64(value) {
        this.ensureAvailable(8);
        this._data.setBigUint64(this.offset, value, this.littleEndian);
        this.offset += 8;
        this._updateLastWrittenByte();
        return this;
      }
      /**
       * Write the charCode of `str`'s first character as an 8-bit unsigned integer
       * and move pointer forward by 1 byte.
       * @param str - The character to write.
       * @returns This.
       */
      writeChar(str) {
        return this.writeUint8(str.charCodeAt(0));
      }
      /**
       * Write the charCodes of all `str`'s characters as 8-bit unsigned integers
       * and move pointer forward by `str.length` bytes.
       * @param str - The characters to write.
       * @returns This.
       */
      writeChars(str) {
        for (let i = 0; i < str.length; i++) {
          this.writeUint8(str.charCodeAt(i));
        }
        return this;
      }
      /**
       * UTF-8 encode and write `str` to the current pointer offset and move pointer
       * forward according to the encoded length.
       * @param str - The string to write.
       * @returns This.
       */
      writeUtf8(str) {
        return this.writeBytes((0, text_1.encode)(str));
      }
      /**
       * Export a Uint8Array view of the internal buffer.
       * The view starts at the byte offset and its length
       * is calculated to stop at the last written byte or the original length.
       * @returns A new Uint8Array view.
       */
      toArray() {
        return new Uint8Array(this.buffer, this.byteOffset, this.lastWrittenByte);
      }
      /**
       *  Get the total number of bytes written so far, regardless of the current offset.
       * @returns - Total number of bytes.
       */
      getWrittenByteLength() {
        return this.lastWrittenByte - this.byteOffset;
      }
      /**
       * Update the last written byte offset
       * @private
       */
      _updateLastWrittenByte() {
        if (this.offset > this.lastWrittenByte) {
          this.lastWrittenByte = this.offset;
        }
      }
    };
    exports2.IOBuffer = IOBuffer;
  }
});

// node_modules/pako/lib/zlib/trees.js
var require_trees = __commonJS({
  "node_modules/pako/lib/zlib/trees.js"(exports2, module2) {
    "use strict";
    var Z_FIXED = 4;
    var Z_BINARY = 0;
    var Z_TEXT = 1;
    var Z_UNKNOWN = 2;
    function zero(buf) {
      let len = buf.length;
      while (--len >= 0) {
        buf[len] = 0;
      }
    }
    var STORED_BLOCK = 0;
    var STATIC_TREES = 1;
    var DYN_TREES = 2;
    var MIN_MATCH = 3;
    var MAX_MATCH = 258;
    var LENGTH_CODES = 29;
    var LITERALS = 256;
    var L_CODES = LITERALS + 1 + LENGTH_CODES;
    var D_CODES = 30;
    var BL_CODES = 19;
    var HEAP_SIZE = 2 * L_CODES + 1;
    var MAX_BITS = 15;
    var Buf_size = 16;
    var MAX_BL_BITS = 7;
    var END_BLOCK = 256;
    var REP_3_6 = 16;
    var REPZ_3_10 = 17;
    var REPZ_11_138 = 18;
    var extra_lbits = (
      /* extra bits for each length code */
      new Uint8Array([0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 2, 2, 2, 2, 3, 3, 3, 3, 4, 4, 4, 4, 5, 5, 5, 5, 0])
    );
    var extra_dbits = (
      /* extra bits for each distance code */
      new Uint8Array([0, 0, 0, 0, 1, 1, 2, 2, 3, 3, 4, 4, 5, 5, 6, 6, 7, 7, 8, 8, 9, 9, 10, 10, 11, 11, 12, 12, 13, 13])
    );
    var extra_blbits = (
      /* extra bits for each bit length code */
      new Uint8Array([0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 2, 3, 7])
    );
    var bl_order = new Uint8Array([16, 17, 18, 0, 8, 7, 9, 6, 10, 5, 11, 4, 12, 3, 13, 2, 14, 1, 15]);
    var DIST_CODE_LEN = 512;
    var static_ltree = new Array((L_CODES + 2) * 2);
    zero(static_ltree);
    var static_dtree = new Array(D_CODES * 2);
    zero(static_dtree);
    var _dist_code = new Array(DIST_CODE_LEN);
    zero(_dist_code);
    var _length_code = new Array(MAX_MATCH - MIN_MATCH + 1);
    zero(_length_code);
    var base_length = new Array(LENGTH_CODES);
    zero(base_length);
    var base_dist = new Array(D_CODES);
    zero(base_dist);
    function StaticTreeDesc(static_tree, extra_bits, extra_base, elems, max_length) {
      this.static_tree = static_tree;
      this.extra_bits = extra_bits;
      this.extra_base = extra_base;
      this.elems = elems;
      this.max_length = max_length;
      this.has_stree = static_tree && static_tree.length;
    }
    var static_l_desc;
    var static_d_desc;
    var static_bl_desc;
    function TreeDesc(dyn_tree, stat_desc) {
      this.dyn_tree = dyn_tree;
      this.max_code = 0;
      this.stat_desc = stat_desc;
    }
    var d_code = (dist) => {
      return dist < 256 ? _dist_code[dist] : _dist_code[256 + (dist >>> 7)];
    };
    var put_short = (s, w) => {
      s.pending_buf[s.pending++] = w & 255;
      s.pending_buf[s.pending++] = w >>> 8 & 255;
    };
    var send_bits = (s, value, length) => {
      if (s.bi_valid > Buf_size - length) {
        s.bi_buf |= value << s.bi_valid & 65535;
        put_short(s, s.bi_buf);
        s.bi_buf = value >> Buf_size - s.bi_valid;
        s.bi_valid += length - Buf_size;
      } else {
        s.bi_buf |= value << s.bi_valid & 65535;
        s.bi_valid += length;
      }
    };
    var send_code = (s, c, tree) => {
      send_bits(
        s,
        tree[c * 2],
        tree[c * 2 + 1]
        /*.Len*/
      );
    };
    var bi_reverse = (code, len) => {
      let res = 0;
      do {
        res |= code & 1;
        code >>>= 1;
        res <<= 1;
      } while (--len > 0);
      return res >>> 1;
    };
    var bi_flush = (s) => {
      if (s.bi_valid === 16) {
        put_short(s, s.bi_buf);
        s.bi_buf = 0;
        s.bi_valid = 0;
      } else if (s.bi_valid >= 8) {
        s.pending_buf[s.pending++] = s.bi_buf & 255;
        s.bi_buf >>= 8;
        s.bi_valid -= 8;
      }
    };
    var gen_bitlen = (s, desc) => {
      const tree = desc.dyn_tree;
      const max_code = desc.max_code;
      const stree = desc.stat_desc.static_tree;
      const has_stree = desc.stat_desc.has_stree;
      const extra = desc.stat_desc.extra_bits;
      const base = desc.stat_desc.extra_base;
      const max_length = desc.stat_desc.max_length;
      let h;
      let n, m;
      let bits;
      let xbits;
      let f;
      let overflow = 0;
      for (bits = 0; bits <= MAX_BITS; bits++) {
        s.bl_count[bits] = 0;
      }
      tree[s.heap[s.heap_max] * 2 + 1] = 0;
      for (h = s.heap_max + 1; h < HEAP_SIZE; h++) {
        n = s.heap[h];
        bits = tree[tree[n * 2 + 1] * 2 + 1] + 1;
        if (bits > max_length) {
          bits = max_length;
          overflow++;
        }
        tree[n * 2 + 1] = bits;
        if (n > max_code) {
          continue;
        }
        s.bl_count[bits]++;
        xbits = 0;
        if (n >= base) {
          xbits = extra[n - base];
        }
        f = tree[n * 2];
        s.opt_len += f * (bits + xbits);
        if (has_stree) {
          s.static_len += f * (stree[n * 2 + 1] + xbits);
        }
      }
      if (overflow === 0) {
        return;
      }
      do {
        bits = max_length - 1;
        while (s.bl_count[bits] === 0) {
          bits--;
        }
        s.bl_count[bits]--;
        s.bl_count[bits + 1] += 2;
        s.bl_count[max_length]--;
        overflow -= 2;
      } while (overflow > 0);
      for (bits = max_length; bits !== 0; bits--) {
        n = s.bl_count[bits];
        while (n !== 0) {
          m = s.heap[--h];
          if (m > max_code) {
            continue;
          }
          if (tree[m * 2 + 1] !== bits) {
            s.opt_len += (bits - tree[m * 2 + 1]) * tree[m * 2];
            tree[m * 2 + 1] = bits;
          }
          n--;
        }
      }
    };
    var gen_codes = (tree, max_code, bl_count) => {
      const next_code = new Array(MAX_BITS + 1);
      let code = 0;
      let bits;
      let n;
      for (bits = 1; bits <= MAX_BITS; bits++) {
        code = code + bl_count[bits - 1] << 1;
        next_code[bits] = code;
      }
      for (n = 0; n <= max_code; n++) {
        let len = tree[n * 2 + 1];
        if (len === 0) {
          continue;
        }
        tree[n * 2] = bi_reverse(next_code[len]++, len);
      }
    };
    var tr_static_init = () => {
      let n;
      let bits;
      let length;
      let code;
      let dist;
      const bl_count = new Array(MAX_BITS + 1);
      length = 0;
      for (code = 0; code < LENGTH_CODES - 1; code++) {
        base_length[code] = length;
        for (n = 0; n < 1 << extra_lbits[code]; n++) {
          _length_code[length++] = code;
        }
      }
      _length_code[length - 1] = code;
      dist = 0;
      for (code = 0; code < 16; code++) {
        base_dist[code] = dist;
        for (n = 0; n < 1 << extra_dbits[code]; n++) {
          _dist_code[dist++] = code;
        }
      }
      dist >>= 7;
      for (; code < D_CODES; code++) {
        base_dist[code] = dist << 7;
        for (n = 0; n < 1 << extra_dbits[code] - 7; n++) {
          _dist_code[256 + dist++] = code;
        }
      }
      for (bits = 0; bits <= MAX_BITS; bits++) {
        bl_count[bits] = 0;
      }
      n = 0;
      while (n <= 143) {
        static_ltree[n * 2 + 1] = 8;
        n++;
        bl_count[8]++;
      }
      while (n <= 255) {
        static_ltree[n * 2 + 1] = 9;
        n++;
        bl_count[9]++;
      }
      while (n <= 279) {
        static_ltree[n * 2 + 1] = 7;
        n++;
        bl_count[7]++;
      }
      while (n <= 287) {
        static_ltree[n * 2 + 1] = 8;
        n++;
        bl_count[8]++;
      }
      gen_codes(static_ltree, L_CODES + 1, bl_count);
      for (n = 0; n < D_CODES; n++) {
        static_dtree[n * 2 + 1] = 5;
        static_dtree[n * 2] = bi_reverse(n, 5);
      }
      static_l_desc = new StaticTreeDesc(static_ltree, extra_lbits, LITERALS + 1, L_CODES, MAX_BITS);
      static_d_desc = new StaticTreeDesc(static_dtree, extra_dbits, 0, D_CODES, MAX_BITS);
      static_bl_desc = new StaticTreeDesc(new Array(0), extra_blbits, 0, BL_CODES, MAX_BL_BITS);
    };
    var init_block = (s) => {
      let n;
      for (n = 0; n < L_CODES; n++) {
        s.dyn_ltree[n * 2] = 0;
      }
      for (n = 0; n < D_CODES; n++) {
        s.dyn_dtree[n * 2] = 0;
      }
      for (n = 0; n < BL_CODES; n++) {
        s.bl_tree[n * 2] = 0;
      }
      s.dyn_ltree[END_BLOCK * 2] = 1;
      s.opt_len = s.static_len = 0;
      s.sym_next = s.matches = 0;
    };
    var bi_windup = (s) => {
      if (s.bi_valid > 8) {
        put_short(s, s.bi_buf);
      } else if (s.bi_valid > 0) {
        s.pending_buf[s.pending++] = s.bi_buf;
      }
      s.bi_buf = 0;
      s.bi_valid = 0;
    };
    var smaller = (tree, n, m, depth) => {
      const _n2 = n * 2;
      const _m2 = m * 2;
      return tree[_n2] < tree[_m2] || tree[_n2] === tree[_m2] && depth[n] <= depth[m];
    };
    var pqdownheap = (s, tree, k) => {
      const v = s.heap[k];
      let j = k << 1;
      while (j <= s.heap_len) {
        if (j < s.heap_len && smaller(tree, s.heap[j + 1], s.heap[j], s.depth)) {
          j++;
        }
        if (smaller(tree, v, s.heap[j], s.depth)) {
          break;
        }
        s.heap[k] = s.heap[j];
        k = j;
        j <<= 1;
      }
      s.heap[k] = v;
    };
    var compress_block = (s, ltree, dtree) => {
      let dist;
      let lc;
      let sx = 0;
      let code;
      let extra;
      if (s.sym_next !== 0) {
        do {
          dist = s.pending_buf[s.sym_buf + sx++] & 255;
          dist += (s.pending_buf[s.sym_buf + sx++] & 255) << 8;
          lc = s.pending_buf[s.sym_buf + sx++];
          if (dist === 0) {
            send_code(s, lc, ltree);
          } else {
            code = _length_code[lc];
            send_code(s, code + LITERALS + 1, ltree);
            extra = extra_lbits[code];
            if (extra !== 0) {
              lc -= base_length[code];
              send_bits(s, lc, extra);
            }
            dist--;
            code = d_code(dist);
            send_code(s, code, dtree);
            extra = extra_dbits[code];
            if (extra !== 0) {
              dist -= base_dist[code];
              send_bits(s, dist, extra);
            }
          }
        } while (sx < s.sym_next);
      }
      send_code(s, END_BLOCK, ltree);
    };
    var build_tree = (s, desc) => {
      const tree = desc.dyn_tree;
      const stree = desc.stat_desc.static_tree;
      const has_stree = desc.stat_desc.has_stree;
      const elems = desc.stat_desc.elems;
      let n, m;
      let max_code = -1;
      let node;
      s.heap_len = 0;
      s.heap_max = HEAP_SIZE;
      for (n = 0; n < elems; n++) {
        if (tree[n * 2] !== 0) {
          s.heap[++s.heap_len] = max_code = n;
          s.depth[n] = 0;
        } else {
          tree[n * 2 + 1] = 0;
        }
      }
      while (s.heap_len < 2) {
        node = s.heap[++s.heap_len] = max_code < 2 ? ++max_code : 0;
        tree[node * 2] = 1;
        s.depth[node] = 0;
        s.opt_len--;
        if (has_stree) {
          s.static_len -= stree[node * 2 + 1];
        }
      }
      desc.max_code = max_code;
      for (n = s.heap_len >> 1; n >= 1; n--) {
        pqdownheap(s, tree, n);
      }
      node = elems;
      do {
        n = s.heap[
          1
          /*SMALLEST*/
        ];
        s.heap[
          1
          /*SMALLEST*/
        ] = s.heap[s.heap_len--];
        pqdownheap(
          s,
          tree,
          1
          /*SMALLEST*/
        );
        m = s.heap[
          1
          /*SMALLEST*/
        ];
        s.heap[--s.heap_max] = n;
        s.heap[--s.heap_max] = m;
        tree[node * 2] = tree[n * 2] + tree[m * 2];
        s.depth[node] = (s.depth[n] >= s.depth[m] ? s.depth[n] : s.depth[m]) + 1;
        tree[n * 2 + 1] = tree[m * 2 + 1] = node;
        s.heap[
          1
          /*SMALLEST*/
        ] = node++;
        pqdownheap(
          s,
          tree,
          1
          /*SMALLEST*/
        );
      } while (s.heap_len >= 2);
      s.heap[--s.heap_max] = s.heap[
        1
        /*SMALLEST*/
      ];
      gen_bitlen(s, desc);
      gen_codes(tree, max_code, s.bl_count);
    };
    var scan_tree = (s, tree, max_code) => {
      let n;
      let prevlen = -1;
      let curlen;
      let nextlen = tree[0 * 2 + 1];
      let count = 0;
      let max_count = 7;
      let min_count = 4;
      if (nextlen === 0) {
        max_count = 138;
        min_count = 3;
      }
      tree[(max_code + 1) * 2 + 1] = 65535;
      for (n = 0; n <= max_code; n++) {
        curlen = nextlen;
        nextlen = tree[(n + 1) * 2 + 1];
        if (++count < max_count && curlen === nextlen) {
          continue;
        } else if (count < min_count) {
          s.bl_tree[curlen * 2] += count;
        } else if (curlen !== 0) {
          if (curlen !== prevlen) {
            s.bl_tree[curlen * 2]++;
          }
          s.bl_tree[REP_3_6 * 2]++;
        } else if (count <= 10) {
          s.bl_tree[REPZ_3_10 * 2]++;
        } else {
          s.bl_tree[REPZ_11_138 * 2]++;
        }
        count = 0;
        prevlen = curlen;
        if (nextlen === 0) {
          max_count = 138;
          min_count = 3;
        } else if (curlen === nextlen) {
          max_count = 6;
          min_count = 3;
        } else {
          max_count = 7;
          min_count = 4;
        }
      }
    };
    var send_tree = (s, tree, max_code) => {
      let n;
      let prevlen = -1;
      let curlen;
      let nextlen = tree[0 * 2 + 1];
      let count = 0;
      let max_count = 7;
      let min_count = 4;
      if (nextlen === 0) {
        max_count = 138;
        min_count = 3;
      }
      for (n = 0; n <= max_code; n++) {
        curlen = nextlen;
        nextlen = tree[(n + 1) * 2 + 1];
        if (++count < max_count && curlen === nextlen) {
          continue;
        } else if (count < min_count) {
          do {
            send_code(s, curlen, s.bl_tree);
          } while (--count !== 0);
        } else if (curlen !== 0) {
          if (curlen !== prevlen) {
            send_code(s, curlen, s.bl_tree);
            count--;
          }
          send_code(s, REP_3_6, s.bl_tree);
          send_bits(s, count - 3, 2);
        } else if (count <= 10) {
          send_code(s, REPZ_3_10, s.bl_tree);
          send_bits(s, count - 3, 3);
        } else {
          send_code(s, REPZ_11_138, s.bl_tree);
          send_bits(s, count - 11, 7);
        }
        count = 0;
        prevlen = curlen;
        if (nextlen === 0) {
          max_count = 138;
          min_count = 3;
        } else if (curlen === nextlen) {
          max_count = 6;
          min_count = 3;
        } else {
          max_count = 7;
          min_count = 4;
        }
      }
    };
    var build_bl_tree = (s) => {
      let max_blindex;
      scan_tree(s, s.dyn_ltree, s.l_desc.max_code);
      scan_tree(s, s.dyn_dtree, s.d_desc.max_code);
      build_tree(s, s.bl_desc);
      for (max_blindex = BL_CODES - 1; max_blindex >= 3; max_blindex--) {
        if (s.bl_tree[bl_order[max_blindex] * 2 + 1] !== 0) {
          break;
        }
      }
      s.opt_len += 3 * (max_blindex + 1) + 5 + 5 + 4;
      return max_blindex;
    };
    var send_all_trees = (s, lcodes, dcodes, blcodes) => {
      let rank;
      send_bits(s, lcodes - 257, 5);
      send_bits(s, dcodes - 1, 5);
      send_bits(s, blcodes - 4, 4);
      for (rank = 0; rank < blcodes; rank++) {
        send_bits(s, s.bl_tree[bl_order[rank] * 2 + 1], 3);
      }
      send_tree(s, s.dyn_ltree, lcodes - 1);
      send_tree(s, s.dyn_dtree, dcodes - 1);
    };
    var detect_data_type = (s) => {
      let block_mask = 4093624447;
      let n;
      for (n = 0; n <= 31; n++, block_mask >>>= 1) {
        if (block_mask & 1 && s.dyn_ltree[n * 2] !== 0) {
          return Z_BINARY;
        }
      }
      if (s.dyn_ltree[9 * 2] !== 0 || s.dyn_ltree[10 * 2] !== 0 || s.dyn_ltree[13 * 2] !== 0) {
        return Z_TEXT;
      }
      for (n = 32; n < LITERALS; n++) {
        if (s.dyn_ltree[n * 2] !== 0) {
          return Z_TEXT;
        }
      }
      return Z_BINARY;
    };
    var static_init_done = false;
    var _tr_init = (s) => {
      if (!static_init_done) {
        tr_static_init();
        static_init_done = true;
      }
      s.l_desc = new TreeDesc(s.dyn_ltree, static_l_desc);
      s.d_desc = new TreeDesc(s.dyn_dtree, static_d_desc);
      s.bl_desc = new TreeDesc(s.bl_tree, static_bl_desc);
      s.bi_buf = 0;
      s.bi_valid = 0;
      init_block(s);
    };
    var _tr_stored_block = (s, buf, stored_len, last) => {
      send_bits(s, (STORED_BLOCK << 1) + (last ? 1 : 0), 3);
      bi_windup(s);
      put_short(s, stored_len);
      put_short(s, ~stored_len);
      if (stored_len) {
        s.pending_buf.set(s.window.subarray(buf, buf + stored_len), s.pending);
      }
      s.pending += stored_len;
    };
    var _tr_align = (s) => {
      send_bits(s, STATIC_TREES << 1, 3);
      send_code(s, END_BLOCK, static_ltree);
      bi_flush(s);
    };
    var _tr_flush_block = (s, buf, stored_len, last) => {
      let opt_lenb, static_lenb;
      let max_blindex = 0;
      if (s.level > 0) {
        if (s.strm.data_type === Z_UNKNOWN) {
          s.strm.data_type = detect_data_type(s);
        }
        build_tree(s, s.l_desc);
        build_tree(s, s.d_desc);
        max_blindex = build_bl_tree(s);
        opt_lenb = s.opt_len + 3 + 7 >>> 3;
        static_lenb = s.static_len + 3 + 7 >>> 3;
        if (static_lenb <= opt_lenb) {
          opt_lenb = static_lenb;
        }
      } else {
        opt_lenb = static_lenb = stored_len + 5;
      }
      if (stored_len + 4 <= opt_lenb && buf !== -1) {
        _tr_stored_block(s, buf, stored_len, last);
      } else if (s.strategy === Z_FIXED || static_lenb === opt_lenb) {
        send_bits(s, (STATIC_TREES << 1) + (last ? 1 : 0), 3);
        compress_block(s, static_ltree, static_dtree);
      } else {
        send_bits(s, (DYN_TREES << 1) + (last ? 1 : 0), 3);
        send_all_trees(s, s.l_desc.max_code + 1, s.d_desc.max_code + 1, max_blindex + 1);
        compress_block(s, s.dyn_ltree, s.dyn_dtree);
      }
      init_block(s);
      if (last) {
        bi_windup(s);
      }
    };
    var _tr_tally = (s, dist, lc) => {
      s.pending_buf[s.sym_buf + s.sym_next++] = dist;
      s.pending_buf[s.sym_buf + s.sym_next++] = dist >> 8;
      s.pending_buf[s.sym_buf + s.sym_next++] = lc;
      if (dist === 0) {
        s.dyn_ltree[lc * 2]++;
      } else {
        s.matches++;
        dist--;
        s.dyn_ltree[(_length_code[lc] + LITERALS + 1) * 2]++;
        s.dyn_dtree[d_code(dist) * 2]++;
      }
      return s.sym_next === s.sym_end;
    };
    module2.exports._tr_init = _tr_init;
    module2.exports._tr_stored_block = _tr_stored_block;
    module2.exports._tr_flush_block = _tr_flush_block;
    module2.exports._tr_tally = _tr_tally;
    module2.exports._tr_align = _tr_align;
  }
});

// node_modules/pako/lib/zlib/adler32.js
var require_adler32 = __commonJS({
  "node_modules/pako/lib/zlib/adler32.js"(exports2, module2) {
    "use strict";
    var adler32 = (adler, buf, len, pos) => {
      let s1 = adler & 65535 | 0, s2 = adler >>> 16 & 65535 | 0, n = 0;
      while (len !== 0) {
        n = len > 2e3 ? 2e3 : len;
        len -= n;
        do {
          s1 = s1 + buf[pos++] | 0;
          s2 = s2 + s1 | 0;
        } while (--n);
        s1 %= 65521;
        s2 %= 65521;
      }
      return s1 | s2 << 16 | 0;
    };
    module2.exports = adler32;
  }
});

// node_modules/pako/lib/zlib/crc32.js
var require_crc32 = __commonJS({
  "node_modules/pako/lib/zlib/crc32.js"(exports2, module2) {
    "use strict";
    var makeTable = () => {
      let c, table = [];
      for (var n = 0; n < 256; n++) {
        c = n;
        for (var k = 0; k < 8; k++) {
          c = c & 1 ? 3988292384 ^ c >>> 1 : c >>> 1;
        }
        table[n] = c;
      }
      return table;
    };
    var crcTable = new Uint32Array(makeTable());
    var crc32 = (crc, buf, len, pos) => {
      const t = crcTable;
      const end = pos + len;
      crc ^= -1;
      for (let i = pos; i < end; i++) {
        crc = crc >>> 8 ^ t[(crc ^ buf[i]) & 255];
      }
      return crc ^ -1;
    };
    modul…197152 tokens truncated… t2.prototype.parse = function(t3) {
        return t3.pos = this.offset, this.version = t3.readInt(), this.numGlyphs = t3.readUInt16(), this.maxPoints = t3.readUInt16(), this.maxContours = t3.readUInt16(), this.maxCompositePoints = t3.readUInt16(), this.maxComponentContours = t3.readUInt16(), this.maxZones = t3.readUInt16(), this.maxTwilightPoints = t3.readUInt16(), this.maxStorage = t3.readUInt16(), this.maxFunctionDefs = t3.readUInt16(), this.maxInstructionDefs = t3.readUInt16(), this.maxStackElements = t3.readUInt16(), this.maxSizeOfInstructions = t3.readUInt16(), this.maxComponentElements = t3.readUInt16(), this.maxComponentDepth = t3.readUInt16();
      }, t2;
    })();
    var be = (function() {
      function t2() {
        return t2.__super__.constructor.apply(this, arguments);
      }
      return ce(t2, ie), t2.prototype.tag = "hmtx", t2.prototype.parse = function(t3) {
        var e2, r2, n2, i2, a2, o2, s2;
        for (t3.pos = this.offset, this.metrics = [], e2 = 0, o2 = this.file.hhea.numberOfMetrics; 0 <= o2 ? e2 < o2 : e2 > o2; e2 = 0 <= o2 ? ++e2 : --e2) this.metrics.push({ advance: t3.readUInt16(), lsb: t3.readInt16() });
        for (n2 = this.file.maxp.numGlyphs - this.file.hhea.numberOfMetrics, this.leftSideBearings = (function() {
          var r3, i3;
          for (i3 = [], e2 = r3 = 0; 0 <= n2 ? r3 < n2 : r3 > n2; e2 = 0 <= n2 ? ++r3 : --r3) i3.push(t3.readInt16());
          return i3;
        })(), this.widths = function() {
          var t4, e3, r3, n3;
          for (n3 = [], t4 = 0, e3 = (r3 = this.metrics).length; t4 < e3; t4++) i2 = r3[t4], n3.push(i2.advance);
          return n3;
        }.call(this), r2 = this.widths[this.widths.length - 1], s2 = [], e2 = a2 = 0; 0 <= n2 ? a2 < n2 : a2 > n2; e2 = 0 <= n2 ? ++a2 : --a2) s2.push(this.widths.push(r2));
        return s2;
      }, t2.prototype.forGlyph = function(t3) {
        return t3 in this.metrics ? this.metrics[t3] : { advance: this.metrics[this.metrics.length - 1].advance, lsb: this.leftSideBearings[t3 - this.metrics.length] };
      }, t2;
    })();
    var ye = [].slice;
    var we = (function() {
      function t2() {
        return t2.__super__.constructor.apply(this, arguments);
      }
      return ce(t2, ie), t2.prototype.tag = "glyf", t2.prototype.parse = function() {
        return this.cache = {};
      }, t2.prototype.glyphFor = function(t3) {
        var e2, r2, n2, i2, a2, o2, s2, c2, u2, l2;
        return t3 in this.cache ? this.cache[t3] : (i2 = this.file.loca, e2 = this.file.contents, r2 = i2.indexOf(t3), 0 === (n2 = i2.lengthOf(t3)) ? this.cache[t3] = null : (e2.pos = this.offset + r2, a2 = (o2 = new ae(e2.read(n2))).readShort(), c2 = o2.readShort(), l2 = o2.readShort(), s2 = o2.readShort(), u2 = o2.readShort(), this.cache[t3] = -1 === a2 ? new Le(o2, c2, l2, s2, u2) : new Ne(o2, a2, c2, l2, s2, u2), this.cache[t3]));
      }, t2.prototype.encode = function(t3, e2, r2) {
        var n2, i2, a2, o2, s2;
        for (a2 = [], i2 = [], o2 = 0, s2 = e2.length; o2 < s2; o2++) n2 = t3[e2[o2]], i2.push(a2.length), n2 && (a2 = a2.concat(n2.encode(r2)));
        return i2.push(a2.length), { table: a2, offsets: i2 };
      }, t2;
    })();
    var Ne = (function() {
      function t2(t3, e2, r2, n2, i2, a2) {
        this.raw = t3, this.numberOfContours = e2, this.xMin = r2, this.yMin = n2, this.xMax = i2, this.yMax = a2, this.compound = false;
      }
      return t2.prototype.encode = function() {
        return this.raw.data;
      }, t2;
    })();
    var Le = (function() {
      function t2(t3, e2, r2, n2, i2) {
        var a2, o2;
        for (this.raw = t3, this.xMin = e2, this.yMin = r2, this.xMax = n2, this.yMax = i2, this.compound = true, this.glyphIDs = [], this.glyphOffsets = [], a2 = this.raw; o2 = a2.readShort(), this.glyphOffsets.push(a2.pos), this.glyphIDs.push(a2.readUInt16()), 32 & o2; ) a2.pos += 1 & o2 ? 4 : 2, 128 & o2 ? a2.pos += 8 : 64 & o2 ? a2.pos += 4 : 8 & o2 && (a2.pos += 2);
      }
      return t2.prototype.encode = function() {
        var t3, e2, r2;
        for (e2 = new ae(ye.call(this.raw.data)), t3 = 0, r2 = this.glyphIDs.length; t3 < r2; ++t3) e2.pos = this.glyphOffsets[t3];
        return e2.data;
      }, t2;
    })();
    var xe = (function() {
      function t2() {
        return t2.__super__.constructor.apply(this, arguments);
      }
      return ce(t2, ie), t2.prototype.tag = "loca", t2.prototype.parse = function(t3) {
        var e2, r2;
        return t3.pos = this.offset, e2 = this.file.head.indexToLocFormat, this.offsets = 0 === e2 ? function() {
          var e3, n2;
          for (n2 = [], r2 = 0, e3 = this.length; r2 < e3; r2 += 2) n2.push(2 * t3.readUInt16());
          return n2;
        }.call(this) : function() {
          var e3, n2;
          for (n2 = [], r2 = 0, e3 = this.length; r2 < e3; r2 += 4) n2.push(t3.readUInt32());
          return n2;
        }.call(this);
      }, t2.prototype.indexOf = function(t3) {
        return this.offsets[t3];
      }, t2.prototype.lengthOf = function(t3) {
        return this.offsets[t3 + 1] - this.offsets[t3];
      }, t2.prototype.encode = function(t3, e2) {
        for (var r2 = new Uint32Array(this.offsets.length), n2 = 0, i2 = 0, a2 = 0; a2 < r2.length; ++a2) if (r2[a2] = n2, i2 < e2.length && e2[i2] == a2) {
          ++i2, r2[a2] = n2;
          var o2 = this.offsets[a2], s2 = this.offsets[a2 + 1] - o2;
          s2 > 0 && (n2 += s2);
        }
        for (var c2 = new Array(4 * r2.length), u2 = 0; u2 < r2.length; ++u2) c2[4 * u2 + 3] = 255 & r2[u2], c2[4 * u2 + 2] = (65280 & r2[u2]) >> 8, c2[4 * u2 + 1] = (16711680 & r2[u2]) >> 16, c2[4 * u2] = (4278190080 & r2[u2]) >> 24;
        return c2;
      }, t2;
    })();
    var Ae = (function() {
      function t2(t3) {
        this.font = t3, this.subset = {}, this.unicodes = {}, this.next = 33;
      }
      return t2.prototype.generateCmap = function() {
        var t3, e2, r2, n2, i2;
        for (e2 in n2 = this.font.cmap.tables[0].codeMap, t3 = {}, i2 = this.subset) r2 = i2[e2], t3[e2] = n2[r2];
        return t3;
      }, t2.prototype.glyphsFor = function(t3) {
        var e2, r2, n2, i2, a2, o2, s2;
        for (n2 = {}, a2 = 0, o2 = t3.length; a2 < o2; a2++) n2[i2 = t3[a2]] = this.font.glyf.glyphFor(i2);
        for (i2 in e2 = [], n2) (null != (r2 = n2[i2]) ? r2.compound : void 0) && e2.push.apply(e2, r2.glyphIDs);
        if (e2.length > 0) for (i2 in s2 = this.glyphsFor(e2)) r2 = s2[i2], n2[i2] = r2;
        return n2;
      }, t2.prototype.encode = function(t3, e2) {
        var r2, n2, i2, a2, o2, s2, c2, u2, l2, h2, f2, d2, p2, g2, m2;
        for (n2 in r2 = he.encode(this.generateCmap(), "unicode"), a2 = this.glyphsFor(t3), f2 = { 0: 0 }, m2 = r2.charMap) f2[(s2 = m2[n2]).old] = s2.new;
        for (d2 in h2 = r2.maxGlyphID, a2) d2 in f2 || (f2[d2] = h2++);
        return u2 = (function(t4) {
          var e3, r3;
          for (e3 in r3 = {}, t4) r3[t4[e3]] = e3;
          return r3;
        })(f2), l2 = Object.keys(u2).sort(function(t4, e3) {
          return t4 - e3;
        }), p2 = (function() {
          var t4, e3, r3;
          for (r3 = [], t4 = 0, e3 = l2.length; t4 < e3; t4++) o2 = l2[t4], r3.push(u2[o2]);
          return r3;
        })(), i2 = this.font.glyf.encode(a2, p2, f2), c2 = this.font.loca.encode(i2.offsets, p2), g2 = { cmap: this.font.cmap.raw(), glyf: i2.table, loca: c2, hmtx: this.font.hmtx.raw(), hhea: this.font.hhea.raw(), maxp: this.font.maxp.raw(), post: this.font.post.raw(), name: this.font.name.raw(), head: this.font.head.encode(e2) }, this.font.os2.exists && (g2["OS/2"] = this.font.os2.raw()), this.font.directory.encode(g2);
      }, t2;
    })();
    C.API.PDFObject = (function() {
      var t2;
      function e2() {
      }
      return t2 = function(t3, e3) {
        return (Array(e3 + 1).join("0") + t3).slice(-e3);
      }, e2.convert = function(r2) {
        var n2, i2, a2, o2;
        if (Array.isArray(r2)) return "[" + (function() {
          var t3, i3, a3;
          for (a3 = [], t3 = 0, i3 = r2.length; t3 < i3; t3++) n2 = r2[t3], a3.push(e2.convert(n2));
          return a3;
        })().join(" ") + "]";
        if ("string" == typeof r2) return "/" + r2;
        if (null != r2 ? r2.isString : void 0) return "(" + r2 + ")";
        if (r2 instanceof Date) return "(D:" + t2(r2.getUTCFullYear(), 4) + t2(r2.getUTCMonth(), 2) + t2(r2.getUTCDate(), 2) + t2(r2.getUTCHours(), 2) + t2(r2.getUTCMinutes(), 2) + t2(r2.getUTCSeconds(), 2) + "Z)";
        if ("[object Object]" === {}.toString.call(r2)) {
          for (i2 in a2 = ["<<"], r2) o2 = r2[i2], a2.push("/" + i2 + " " + e2.convert(o2));
          return a2.push(">>"), a2.join("\n");
        }
        return "" + r2;
      }, e2;
    })(), exports2.AcroForm = yt, exports2.AcroFormAppearance = vt, exports2.AcroFormButton = lt, exports2.AcroFormCheckBox = pt, exports2.AcroFormChoiceField = ot, exports2.AcroFormComboBox = ct, exports2.AcroFormEditBox = ut, exports2.AcroFormListBox = st, exports2.AcroFormPasswordField = mt, exports2.AcroFormPushButton = ht, exports2.AcroFormRadioButton = ft, exports2.AcroFormTextField = gt, exports2.GState = P, exports2.ShadingPattern = F, exports2.TilingPattern = I, exports2.default = C, exports2.jsPDF = C;
  }
});

// src/portal/crm-sales.tsx
var crm_sales_exports = {};
__export(crm_sales_exports, {
  CrmSales: () => CrmSales
});
module.exports = __toCommonJS(crm_sales_exports);
var import_react15 = require("/workspace/scratch/76b8a24bf15c/imanservice/node_modules/react/index.js");

// mock:client
var db = globalThis.__db;
function check(r) {
  if (r.error) throw r.error;
  return r.data;
}

// mock:workspace
async function workspaceRows(t) {
  return (await globalThis.__db.from(t)).data;
}

// src/portal/business-utils.ts
function csvText(rows) {
  return "\uFEFF" + rows.map((row) => row.map((value) => {
    let s = String(value ?? "");
    if (/^[\s]*[=+\-@]/.test(s)) s = "'" + s;
    return '"' + s.replace(/"/g, '""') + '"';
  }).join(",")).join("\r\n");
}
function downloadText(name, text, type = "text/csv;charset=utf-8") {
  const url = URL.createObjectURL(new Blob([text], { type }));
  const a = document.createElement("a");
  a.href = url;
  a.download = name;
  a.click();
  setTimeout(() => URL.revokeObjectURL(url), 1e3);
}
function parseCSV(text) {
  text = text.replace(/^\ufeff/, "");
  const rows = [];
  let row = [], cell = "", quoted = false, closed = false;
  for (let i = 0; i < text.length; i++) {
    const c = text[i];
    if (quoted) {
      if (c === '"') {
        if (text[i + 1] === '"') {
          cell += '"';
          i++;
        } else {
          quoted = false;
          closed = true;
        }
      } else cell += c;
    } else if (c === '"') {
      if (cell || closed) throw new Error("Unexpected quote in CSV");
      quoted = true;
    } else if (c === "," || c === "\n" || c === "\r") {
      row.push(cell);
      cell = "";
      closed = false;
      if (c !== ",") {
        if (c === "\r" && text[i + 1] === "\n") i++;
        rows.push(row);
        row = [];
      }
    } else {
      if (closed) throw new Error("Unexpected text after closing quote");
      cell += c;
    }
  }
  if (quoted) throw new Error("Unclosed CSV quote");
  if (cell || row.length || closed) {
    row.push(cell);
    rows.push(row);
  }
  return rows.filter((r) => r.some((c) => c.trim()));
}
async function readXLSX(buffer) {
  const view = new DataView(buffer), bytes = new Uint8Array(buffer), decode = new TextDecoder();
  let eocd = -1;
  for (let i = bytes.length - 22; i >= Math.max(0, bytes.length - 65557); i--) if (view.getUint32(i, true) === 101010256) {
    eocd = i;
    break;
  }
  if (eocd < 0) throw new Error("Invalid XLSX archive");
  const count = view.getUint16(eocd + 10, true);
  let cursor = view.getUint32(eocd + 16, true), total = 0;
  if (count > 2e3) throw new Error("Workbook has too many entries");
  const entries = /* @__PURE__ */ new Map();
  for (let n = 0; n < count; n++) {
    if (cursor + 46 > bytes.length || view.getUint32(cursor, true) !== 33639248) throw new Error("Invalid ZIP index");
    const flags = view.getUint16(cursor + 8, true), method = view.getUint16(cursor + 10, true), size = view.getUint32(cursor + 20, true), raw = view.getUint32(cursor + 24, true), len = view.getUint16(cursor + 28, true), extra = view.getUint16(cursor + 30, true), comment = view.getUint16(cursor + 32, true), start = view.getUint32(cursor + 42, true);
    const name = decode.decode(bytes.slice(cursor + 46, cursor + 46 + len));
    total += raw;
    if (flags & 1 || total > 20 * 1024 * 1024 || raw > 10 * 1024 * 1024 || entries.has(name)) throw new Error("Encrypted, duplicate or oversized workbook entries are not supported");
    entries.set(name, { start, size, method, raw });
    cursor += 46 + len + extra + comment;
  }
  if ([...entries.keys()].some((n) => /vbaProject/i.test(n))) throw new Error("Macro workbooks are not supported");
  async function xml(name) {
    const e = entries.get(name);
    if (!e) throw new Error("Missing workbook component: " + name);
    if (e.start + 30 > bytes.length || view.getUint32(e.start, true) !== 67324752) throw new Error("Invalid ZIP entry");
    const start = e.start + 30 + view.getUint16(e.start + 26, true) + view.getUint16(e.start + 28, true);
    if (start + e.size > bytes.length) throw new Error("Truncated workbook");
    let data = bytes.slice(start, start + e.size);
    if (e.method === 8) {
      const reader = new Blob([data]).stream().pipeThrough(new DecompressionStream("deflate-raw")).getReader();
      const chunks = [];
      let size = 0;
      for (; ; ) {
        const r = await reader.read();
        if (r.done) break;
        size += r.value.length;
        if (size > e.raw || size > 10 * 1024 * 1024) {
          await reader.cancel();
          throw new Error("Workbook expands beyond limits");
        }
        chunks.push(r.value);
      }
      data = new Uint8Array(size);
      let offset = 0;
      for (const chunk of chunks) {
        data.set(chunk, offset);
        offset += chunk.length;
      }
    } else if (e.method !== 0) throw new Error("Unsupported workbook compression");
    if (data.length !== e.raw) throw new Error("Invalid workbook size");
    const text = decode.decode(data);
    if (/<!DOCTYPE|<!ENTITY/i.test(text)) throw new Error("Unsafe XML");
    const doc = new DOMParser().parseFromString(text, "application/xml");
    if (doc.querySelector("parsererror")) throw new Error("Invalid workbook XML");
    return doc;
  }
  const workbook = await xml("xl/workbook.xml"), rels = await xml("xl/_rels/workbook.xml.rels");
  const sheet = workbook.getElementsByTagName("sheet")[0];
  if (!sheet) throw new Error("No worksheets");
  const rid = sheet.getAttribute("r:id");
  const rel = Array.from(rels.getElementsByTagName("Relationship")).find((r) => r.getAttribute("Id") === rid);
  const target = rel?.getAttribute("Target") || "";
  if (rel?.getAttribute("TargetMode") === "External" || target.includes("..")) throw new Error("External workbook links are not supported");
  const path = target.startsWith("/") ? target.slice(1) : "xl/" + target;
  const sheetDoc = await xml(path);
  if (sheetDoc.getElementsByTagName("f").length) throw new Error("Replace formulas with values before importing");
  const shared = entries.has("xl/sharedStrings.xml") ? Array.from((await xml("xl/sharedStrings.xml")).getElementsByTagName("si")).map((s) => Array.from(s.getElementsByTagName("t")).map((t) => t.textContent || "").join("")) : [];
  const rows = [];
  for (const row of Array.from(sheetDoc.getElementsByTagName("row"))) {
    const values = [];
    for (const cell of Array.from(row.getElementsByTagName("c"))) {
      const ref = cell.getAttribute("r") || "";
      const letters = ref.match(/^[A-Z]+/)?.[0];
      if (!letters) throw new Error("Invalid cell reference");
      let column = 0;
      for (const c of letters) column = column * 26 + c.charCodeAt(0) - 64;
      if (column > 20) throw new Error("Use the six template columns only");
      let value = cell.getElementsByTagName("v")[0]?.textContent || "";
      if (cell.getAttribute("t") === "s") value = shared[Number(value)] ?? "";
      if (cell.getAttribute("t") === "inlineStr") value = Array.from(cell.getElementsByTagName("t")).map((t) => t.textContent || "").join("");
      if (cell.getAttribute("t") === "e") throw new Error("Workbook contains an error cell");
      values[column - 1] = value;
    }
    if (values.some((v) => v?.trim())) rows.push(Array.from({ length: values.length }, (_, i) => values[i] || ""));
    if (rows.length > 501) throw new Error("Maximum 500 tasks");
  }
  return rows;
}

// src/portal/crm-project-planning.tsx
var import_react13 = require("/workspace/scratch/76b8a24bf15c/imanservice/node_modules/react/index.js");

// src/portal/project-charters.tsx
var import_react = require("/workspace/scratch/76b8a24bf15c/imanservice/node_modules/react/index.js");
var import_jsx_runtime = __toESM(require_jsx_runtime(), 1);

// src/portal/project-lessons.tsx
var import_react2 = require("/workspace/scratch/76b8a24bf15c/imanservice/node_modules/react/index.js");
var import_jsx_runtime2 = __toESM(require_jsx_runtime(), 1);

// src/portal/project-risks.tsx
var import_react3 = require("/workspace/scratch/76b8a24bf15c/imanservice/node_modules/react/index.js");
var import_jsx_runtime3 = __toESM(require_jsx_runtime(), 1);

// src/portal/project-tool-bookings.tsx
var import_react4 = require("/workspace/scratch/76b8a24bf15c/imanservice/node_modules/react/index.js");

// src/portal/project-tool-availability.tsx
var import_jsx_runtime4 = __toESM(require_jsx_runtime(), 1);

// src/portal/project-tool-bookings.tsx
var import_jsx_runtime5 = __toESM(require_jsx_runtime(), 1);

// src/portal/project-tool-requests.tsx
var import_react5 = require("/workspace/scratch/76b8a24bf15c/imanservice/node_modules/react/index.js");
var import_jsx_runtime6 = __toESM(require_jsx_runtime(), 1);

// src/portal/project-task-learning.tsx
var import_react6 = require("/workspace/scratch/76b8a24bf15c/imanservice/node_modules/react/index.js");
var import_jsx_runtime7 = __toESM(require_jsx_runtime(), 1);

// src/portal/project-resource-allocation.tsx
var import_react9 = require("/workspace/scratch/76b8a24bf15c/imanservice/node_modules/react/index.js");

// src/portal/work-schedules.tsx
var import_react8 = require("/workspace/scratch/76b8a24bf15c/imanservice/node_modules/react/index.js");

// src/portal/activity-location.tsx
var import_react7 = require("/workspace/scratch/76b8a24bf15c/imanservice/node_modules/react/index.js");
var import_jsx_runtime8 = __toESM(require_jsx_runtime(), 1);

// src/portal/work-schedules.tsx
var import_jsx_runtime9 = __toESM(require_jsx_runtime(), 1);

// src/portal/project-resource-allocation.tsx
var import_jsx_runtime10 = __toESM(require_jsx_runtime(), 1);

// src/portal/project-task-adjustments.tsx
var import_react10 = require("/workspace/scratch/76b8a24bf15c/imanservice/node_modules/react/index.js");
var import_jsx_runtime11 = __toESM(require_jsx_runtime(), 1);

// src/portal/task-library.tsx
var import_react12 = require("/workspace/scratch/76b8a24bf15c/imanservice/node_modules/react/index.js");

// src/portal/task-library-import.tsx
var import_react11 = require("/workspace/scratch/76b8a24bf15c/imanservice/node_modules/react/index.js");
var import_jsx_runtime12 = __toESM(require_jsx_runtime(), 1);

// src/portal/task-library.tsx
var import_jsx_runtime13 = __toESM(require_jsx_runtime(), 1);

// src/portal/crm-project-planning.tsx
var import_jsx_runtime14 = __toESM(require_jsx_runtime(), 1);
var today = () => (/* @__PURE__ */ new Date()).toLocaleDateString("en-CA", { timeZone: "Asia/Karachi" });
var phases = ["Mobilization", "Civil & containment", "Cable deployment", "Termination & installation", "Testing & commissioning", "QA-QC & handover"];
function Input({ label, value, onChange, type = "text" }) {
  return /* @__PURE__ */ (0, import_jsx_runtime14.jsxs)("label", { className: "p-field", children: [
    label,
    /* @__PURE__ */ (0, import_jsx_runtime14.jsx)("input", { type, value: value ?? "", onChange: (e) => onChange(type === "number" ? Number(e.target.value) : e.target.value), step: type === "number" ? "0.01" : void 0 })
  ] });
}
function Plan({ plan }) {
  return /* @__PURE__ */ (0, import_jsx_runtime14.jsxs)(import_jsx_runtime14.Fragment, { children: [
    /* @__PURE__ */ (0, import_jsx_runtime14.jsxs)("p", { children: [
      plan.man_hours,
      " man-hours \xB7 ",
      plan.man_days,
      " man-days \xB7 Template revision ",
      plan.revision
    ] }),
    /* @__PURE__ */ (0, import_jsx_runtime14.jsx)("div", { className: "p-table-scroll", children: /* @__PURE__ */ (0, import_jsx_runtime14.jsxs)("table", { className: "p-table", children: [
      /* @__PURE__ */ (0, import_jsx_runtime14.jsx)("thead", { children: /* @__PURE__ */ (0, import_jsx_runtime14.jsxs)("tr", { children: [
        /* @__PURE__ */ (0, import_jsx_runtime14.jsx)("th", { children: "Phase" }),
        /* @__PURE__ */ (0, import_jsx_runtime14.jsx)("th", { children: "Task" }),
        /* @__PURE__ */ (0, import_jsx_runtime14.jsx)("th", { children: "Quantity" }),
        /* @__PURE__ */ (0, import_jsx_runtime14.jsx)("th", { children: "Duration hours" }),
        /* @__PURE__ */ (0, import_jsx_runtime14.jsx)("th", { children: "Crew" }),
        /* @__PURE__ */ (0, import_jsx_runtime14.jsx)("th", { children: "Tools / readiness" })
      ] }) }),
      /* @__PURE__ */ (0, import_jsx_runtime14.jsx)("tbody", { children: plan.tasks.map((t) => /* @__PURE__ */ (0, import_jsx_runtime14.jsxs)("tr", { children: [
        /* @__PURE__ */ (0, import_jsx_runtime14.jsxs)("td", { children: [
          t.phase,
          " \xB7 ",
          phases[t.phase]
        ] }),
        /* @__PURE__ */ (0, import_jsx_runtime14.jsx)("td", { children: t.title }),
        /* @__PURE__ */ (0, import_jsx_runtime14.jsxs)("td", { children: [
          t.quantity,
          " ",
          t.unit
        ] }),
        /* @__PURE__ */ (0, import_jsx_runtime14.jsx)("td", { children: Number(t.duration_minutes) / 60 }),
        /* @__PURE__ */ (0, import_jsx_runtime14.jsxs)("td", { children: [
          t.crew,
          " ",
          t.crew_role
        ] }),
        /* @__PURE__ */ (0, import_jsx_runtime14.jsxs)("td", { children: [
          t.tools,
          /* @__PURE__ */ (0, import_jsx_runtime14.jsx)("p", { children: t.preconditions })
        ] })
      ] }, t.key)) })
    ] }) })
  ] });
}
function WonConversion({ profile, deal, products, boards, onChanged }) {
  const [standard, setStandard] = (0, import_react13.useState)(""), [templates, setTemplates] = (0, import_react13.useState)([]), [versions, setVersions] = (0, import_react13.useState)([]), [accepted, setAccepted] = (0, import_react13.useState)(null), [sale, setSale] = (0, import_react13.useState)(null), [managers, setManagers] = (0, import_react13.useState)([]), [selection, setSelection] = (0, import_react13.useState)({}), [values, setValues] = (0, import_react13.useState)({}), [plans, setPlans] = (0, import_react13.useState)({}), [kind, setKind] = (0, import_react13.useState)("Full"), [percent, setPercent] = (0, import_react13.useState)(100), [months, setMonths] = (0, import_react13.useState)(12), [schedule, setSchedule] = (0, import_react13.useState)([{ title: "Advance", percent: 25 }, { title: "Handover", percent: 75 }]), [busy, setBusy] = (0, import_react13.useState)(false), [error, setError] = (0, import_react13.useState)("");
  const editor = profile.role === "admin" || profile.crm_permissions?.includes("sales.manage") || profile.crm_permissions?.includes("sales.own") && deal.owner_id === profile.id;
  const load = async () => {
    const [t, v, p, s, m] = await Promise.all([workspaceRows("crm_project_templates"), workspaceRows("crm_template_versions"), workspaceRows("crm_quote_publications"), workspaceRows("crm_sales"), Promise.resolve(db.rpc("crm_project_managers")).then(check)]);
    setTemplates(t);
    setVersions(v);
    setAccepted(p.find((p2) => p2.deal_id === deal.id && p2.status === "Accepted") || null);
    setSale(s.find((s2) => s2.deal_id === deal.id) || null);
    setManagers(m);
  };
  (0, import_react13.useEffect)(() => {
    if (editor) load().catch((e) => setError(e.message));
  }, [deal.id, deal.version]);
  if (!editor) return null;
  const activeProducts = products.filter((p) => p.status === "Active"), projectProducts = activeProducts.filter((p) => boards.find((b) => b.id === p.board_id)?.outcome !== "Contract"), contract = activeProducts.some((p) => boards.find((b) => b.id === p.board_id)?.outcome === "Contract");
  if (sale) return /* @__PURE__ */ (0, import_jsx_runtime14.jsxs)("section", { className: "p-panel", children: [
    /* @__PURE__ */ (0, import_jsx_runtime14.jsx)("h3", { children: "Won conversion complete" }),
    /* @__PURE__ */ (0, import_jsx_runtime14.jsxs)("p", { children: [
      "One sale \xB7 ",
      sale.currency,
      " ",
      sale.total,
      " \xB7 Accepted quotation preserved \xB7 First invoice draft created."
    ] }),
    /* @__PURE__ */ (0, import_jsx_runtime14.jsxs)("p", { children: [
      sale.project_id ? "Project and workstreams created. " : "",
      sale.contract_id ? "Support contract created." : ""
    ] })
  ] });
  return /* @__PURE__ */ (0, import_jsx_runtime14.jsxs)("section", { className: "p-panel", children: [
    /* @__PURE__ */ (0, import_jsx_runtime14.jsx)("h3", { children: "Convert accepted quotation to Won" }),
    error && /* @__PURE__ */ (0, import_jsx_runtime14.jsx)("p", { role: "alert", className: "p-error", children: error }),
    !accepted ? /* @__PURE__ */ (0, import_jsx_runtime14.jsx)("p", { children: "The customer must accept a quotation solution before conversion." }) : /* @__PURE__ */ (0, import_jsx_runtime14.jsxs)("form", { className: "p-form", onSubmit: async (e) => {
      e.preventDefault();
      const data = new FormData(e.currentTarget);
      setBusy(true);
      setError("");
      try {
        const payment = { kind, first_percent: kind === "Full" ? 100 : kind === "Monthly" ? Number((100 / months).toFixed(4)) : kind === "Milestones" ? schedule[0]?.percent : percent, ...kind === "Monthly" ? { months } : {}, ...kind === "Milestones" ? { schedule } : {} };
        const sla = contract ? { end_date: data.get("contract_end"), services: data.get("services"), targets: Object.fromEntries(["Low", "Normal", "High", "Urgent"].map((p) => [p, { response: Number(data.get(p + "_response")), resolution: Number(data.get(p + "_resolution")) }])) } : null;
        check(await db.rpc("convert_crm_won", { p_deal: deal.id, p_version: deal.version, p_publication: accepted.id, p_manager: data.get("manager") || null, p_start: data.get("start"), p_workstreams: projectProducts.map((p) => ({ product_line_id: p.id, template_version_id: selection[p.id], parameters: values[p.id] || {} })), p_payment: payment, p_contract: sla }));
        await load();
        onChanged();
      } catch (e2) {
        setError(e2.message);
      } finally {
        setBusy(false);
      }
    }, children: [
      /* @__PURE__ */ (0, import_jsx_runtime14.jsxs)("p", { children: [
        accepted.number,
        " v",
        accepted.revision,
        " \xB7 ",
        accepted.option_name,
        " \xB7 ",
        accepted.currency,
        " ",
        accepted.total
      ] }),
      projectProducts.length > 0 && /* @__PURE__ */ (0, import_jsx_runtime14.jsxs)("label", { className: "p-field", children: [
        "Project manager",
        /* @__PURE__ */ (0, import_jsx_runtime14.jsxs)("select", { name: "manager", required: true, children: [
          /* @__PURE__ */ (0, import_jsx_runtime14.jsx)("option", { value: "", children: "Choose manager" }),
          managers.map((m) => /* @__PURE__ */ (0, import_jsx_runtime14.jsx)("option", { value: m.id, children: m.name }, m.id))
        ] })
      ] }),
      /* @__PURE__ */ (0, import_jsx_runtime14.jsxs)("label", { className: "p-field", children: [
        "Start date",
        /* @__PURE__ */ (0, import_jsx_runtime14.jsx)("input", { name: "start", type: "date", defaultValue: today(), required: true })
      ] }),
      projectProducts.map((p) => {
        const version = versions.find((v) => v.id === selection[p.id]);
        return /* @__PURE__ */ (0, import_jsx_runtime14.jsxs)("fieldset", { children: [
          /* @__PURE__ */ (0, import_jsx_runtime14.jsx)("legend", { children: boards.find((b) => b.id === p.board_id)?.name }),
          /* @__PURE__ */ (0, import_jsx_runtime14.jsxs)("label", { className: "p-field", children: [
            "Current project template",
            /* @__PURE__ */ (0, import_jsx_runtime14.jsxs)("select", { required: true, value: selection[p.id] || "", onChange: (e) => {
              setSelection({ ...selection, [p.id]: e.target.value });
              setValues({ ...values, [p.id]: {} });
              setPlans(Object.fromEntries(Object.entries(plans).filter(([id]) => id !== p.id)));
            }, children: [
              /* @__PURE__ */ (0, import_jsx_runtime14.jsx)("option", { value: "", children: "Choose template" }),
              templates.filter((t) => t.active && t.board_id === p.board_id).map((t) => {
                const v = versions.find((v2) => v2.template_id === t.id && v2.revision === t.version);
                return v ? /* @__PURE__ */ (0, import_jsx_runtime14.jsxs)("option", { value: v.id, children: [
                  t.name,
                  " \xB7 v",
                  v.revision
                ] }, t.id) : null;
              })
            ] })
          ] }),
          version?.parameters.map((parameter) => /* @__PURE__ */ (0, import_jsx_runtime14.jsx)(Input, { type: "number", label: parameter.label, value: values[p.id]?.[parameter.key] ?? parameter.default, onChange: (n) => {
            setValues({ ...values, [p.id]: { ...values[p.id], [parameter.key]: n } });
            setPlans(Object.fromEntries(Object.entries(plans).filter(([id]) => id !== p.id)));
          } }, parameter.key)),
          /* @__PURE__ */ (0, import_jsx_runtime14.jsx)("button", { type: "button", disabled: busy || !version, onClick: async () => {
            setError("");
            try {
              const plan = check(await db.rpc("preview_crm_project_plan", { p_version: version.id, p_values: values[p.id] || {} }));
              setPlans({ ...plans, [p.id]: plan });
            } catch (e) {
              setError(e.message);
            }
          }, children: "Review calculated workstream" }),
          plans[p.id] && /* @__PURE__ */ (0, import_jsx_runtime14.jsx)(Plan, { plan: plans[p.id] })
        ] }, p.id);
      }),
      /* @__PURE__ */ (0, import_jsx_runtime14.jsxs)("label", { className: "p-field", children: [
        "Payment terms",
        /* @__PURE__ */ (0, import_jsx_runtime14.jsx)("select", { value: kind, onChange: (e) => setKind(e.target.value), children: ["Full", "Advance", "Milestones", "Monthly"].map((k) => /* @__PURE__ */ (0, import_jsx_runtime14.jsx)("option", { children: k }, k)) })
      ] }),
      kind === "Advance" && /* @__PURE__ */ (0, import_jsx_runtime14.jsx)(Input, { type: "number", label: "First invoice percentage", value: percent, onChange: setPercent }),
      " ",
      kind === "Monthly" && /* @__PURE__ */ (0, import_jsx_runtime14.jsx)(Input, { type: "number", label: "Number of monthly periods", value: months, onChange: setMonths }),
      " ",
      kind === "Milestones" && /* @__PURE__ */ (0, import_jsx_runtime14.jsxs)(import_jsx_runtime14.Fragment, { children: [
        /* @__PURE__ */ (0, import_jsx_runtime14.jsx)("p", { children: "Milestone percentages must total 100. The first milestone creates the first draft invoice." }),
        schedule.map((s, i) => /* @__PURE__ */ (0, import_jsx_runtime14.jsxs)("div", { children: [
          /* @__PURE__ */ (0, import_jsx_runtime14.jsx)(Input, { label: "Payment milestone", value: s.title, onChange: (title) => setSchedule(schedule.map((s2, n) => i === n ? { ...s2, title } : s2)) }),
          /* @__PURE__ */ (0, import_jsx_runtime14.jsx)(Input, { label: "Percentage", type: "number", value: s.percent, onChange: (percent2) => setSchedule(schedule.map((s2, n) => i === n ? { ...s2, percent: percent2 } : s2)) })
        ] }, i)),
        /* @__PURE__ */ (0, import_jsx_runtime14.jsx)("button", { type: "button", onClick: () => setSchedule([...schedule, { title: "", percent: 0 }]), children: "Add payment milestone" })
      ] }),
      contract && /* @__PURE__ */ (0, import_jsx_runtime14.jsxs)("fieldset", { children: [
        /* @__PURE__ */ (0, import_jsx_runtime14.jsx)("legend", { children: "Support SLA contract" }),
        /* @__PURE__ */ (0, import_jsx_runtime14.jsxs)("label", { className: "p-field", children: [
          "Contract end",
          /* @__PURE__ */ (0, import_jsx_runtime14.jsx)("input", { name: "contract_end", type: "date", required: true })
        ] }),
        /* @__PURE__ */ (0, import_jsx_runtime14.jsxs)("label", { className: "p-field", children: [
          "Covered services",
          /* @__PURE__ */ (0, import_jsx_runtime14.jsx)("textarea", { name: "services", required: true, maxLength: 1e4 })
        ] }),
        ["Low", "Normal", "High", "Urgent"].map((p) => /* @__PURE__ */ (0, import_jsx_runtime14.jsxs)("div", { children: [
          /* @__PURE__ */ (0, import_jsx_runtime14.jsxs)("label", { className: "p-field", children: [
            p,
            " response minutes",
            /* @__PURE__ */ (0, import_jsx_runtime14.jsx)("input", { type: "number", min: "1", name: p + "_response", required: true })
          ] }),
          /* @__PURE__ */ (0, import_jsx_runtime14.jsxs)("label", { className: "p-field", children: [
            p,
            " resolution minutes",
            /* @__PURE__ */ (0, import_jsx_runtime14.jsx)("input", { type: "number", min: "1", name: p + "_resolution", required: true })
          ] })
        ] }, p))
      ] }),
      /* @__PURE__ */ (0, import_jsx_runtime14.jsxs)("p", { children: [
        "Conversion creates the sale, saved budget, ",
        projectProducts.length ? "project and workstreams, " : "",
        contract ? "support contract, " : "",
        "and first invoice draft together. Generated task dates form an initial sequential schedule for manager review."
      ] }),
      /* @__PURE__ */ (0, import_jsx_runtime14.jsx)("button", { disabled: busy, children: "Create sale and mark Won" })
    ] })
  ] });
}

// src/portal/crm-quotes.tsx
var import_react14 = require("/workspace/scratch/76b8a24bf15c/imanservice/node_modules/react/index.js");

// src/portal/report-export.ts
async function createReportPDF(title, context, sections) {
  const { jsPDF } = await Promise.resolve().then(() => __toESM(require_jspdf_node_min(), 1));
  const doc = new jsPDF({ orientation: "landscape", unit: "mm", format: "a4" });
  const width = doc.internal.pageSize.getWidth(), height = doc.internal.pageSize.getHeight(), margin = 14;
  let y = 20;
  const line = (value, size = 9, bold = false) => {
    doc.setFont("helvetica", bold ? "bold" : "normal");
    doc.setFontSize(size);
    const lines = doc.splitTextToSize(value, width - 2 * margin);
    for (const l of lines) {
      if (y > height - 20) {
        doc.addPage();
        y = 20;
      }
      doc.text(l, margin, y);
      y += size * 0.45 + 1.5;
    }
  };
  line("i Man Service", 12, true);
  line(title, 18, true);
  line(context);
  line(`Generated UTC: ${(/* @__PURE__ */ new Date()).toISOString()}`);
  y += 5;
  for (const section of sections) {
    if (y > height - 35) {
      doc.addPage();
      y = 20;
    }
    line(section.title, 12, true);
    if (!section.rows.length) {
      line("No records in this scope.");
      continue;
    }
    const columnWidth = (width - 2 * margin) / section.headers.length;
    const drawRow = (values, heading = false) => {
      doc.setFont("helvetica", heading ? "bold" : "normal");
      doc.setFontSize(8);
      const cells = values.map((v) => doc.splitTextToSize(String(v ?? "\u2014"), columnWidth - 4));
      const rowHeight = Math.max(...cells.map((c) => c.length)) * 4 + 5;
      if (rowHeight > height - 40) {
        values.forEach((v, i) => line(`${section.headers[i]}: ${String(v ?? "\u2014")}`, 8));
        y += 3;
        return;
      }
      if (y + rowHeight > height - 18) {
        doc.addPage();
        y = 20;
        if (!heading) {
          drawRow(section.headers, true);
          doc.setFont("helvetica", "normal");
          doc.setFontSize(8);
        }
      }
      if (heading) {
        doc.setFillColor(235, 240, 247);
        doc.rect(margin, y - 3, width - 2 * margin, rowHeight, "F");
      }
      cells.forEach((cell, i) => doc.text(cell, margin + i * columnWidth + 2, y + 1));
      y += rowHeight;
      doc.setDrawColor(220);
      doc.line(margin, y - 3, width - margin, y - 3);
    };
    drawRow(section.headers, true);
    section.rows.forEach((r) => drawRow(r));
    y += 6;
  }
  const pages = doc.getNumberOfPages();
  for (let p = 1; p <= pages; p++) {
    doc.setPage(p);
    doc.setFontSize(8);
    doc.setFont("helvetica", "normal");
    doc.text(`i Man Service \xB7 ${p} / ${pages}`, margin, height - 8);
  }
  return doc;
}
async function downloadReportPDF(filename, title, context, sections) {
  (await createReportPDF(title, context, sections)).save(filename.replace(/[^a-zA-Z0-9._-]/g, "_"));
}

// src/portal/crm-quotes.tsx
var import_jsx_runtime15 = __toESM(require_jsx_runtime(), 1);
var day = () => (/* @__PURE__ */ new Date()).toLocaleDateString("en-CA", { timeZone: "Asia/Karachi" });
var money = (n) => Number(n || 0).toLocaleString(void 0, { minimumFractionDigits: 2, maximumFractionDigits: 2 });
var slabs = Array.from({ length: 17 }, (_, i) => (i + 1) * 5);
function Field({ name, label, value = "", type = "text", required = false }) {
  return /* @__PURE__ */ (0, import_jsx_runtime15.jsxs)("label", { className: "p-field", children: [
    label,
    type === "textarea" ? /* @__PURE__ */ (0, import_jsx_runtime15.jsx)("textarea", { name, defaultValue: value, maxLength: 1e4 }) : /* @__PURE__ */ (0, import_jsx_runtime15.jsx)("input", { name, type, defaultValue: value, required, step: type === "number" ? "0.001" : void 0, min: type === "number" ? 0 : void 0 })
  ] });
}
function Margin({ name = "margin", value = "", inherit = false, choices = slabs }) {
  return /* @__PURE__ */ (0, import_jsx_runtime15.jsxs)("label", { className: "p-field", children: [
    "Gross margin %",
    /* @__PURE__ */ (0, import_jsx_runtime15.jsxs)("select", { name, defaultValue: value, children: [
      inherit && /* @__PURE__ */ (0, import_jsx_runtime15.jsx)("option", { value: "", children: "Quotation default" }),
      choices.map((n) => /* @__PURE__ */ (0, import_jsx_runtime15.jsxs)("option", { value: n, children: [
        n,
        "%"
      ] }, n))
    ] })
  ] });
}
async function quotationPDF(p) {
  await downloadReportPDF(`${p.number}-v${p.revision}.pdf`, `${p.number} v${p.revision} \xB7 ${p.title}`, `${p.company_name} \xB7 ${p.option_name} \xB7 ${p.currency} \xB7 Valid until ${p.valid_until}`, [
    ...[...new Set(p.items.map((i) => i.product))].map((product) => ({ title: String(product), headers: ["Description", "Unit", "Quantity", "Unit price", "Total"], rows: p.items.filter((i) => i.product === product).map((i) => [i.description, i.unit, i.quantity, money(i.unit_price), money(i.total)]) })),
    { title: "Quotation totals", headers: ["Description", "Amount"], rows: [["Subtotal", money(p.subtotal)], ["PRA services tax", money(p.tax_total)], ["Total quotation", money(p.total)], ["Client WHT withholding", money(p.wht_total)], ["Net payment after withholding", money(p.receivable)]] },
    { title: "Terms & conditions", headers: ["Terms"], rows: [[p.terms || "No additional terms."]] }
  ]);
}
function CrmQuotes({ profile, deal, products = [], boards = [], editableBoardIds = [], companies = [], onChanged = () => {
} }) {
  const [marginSlabs, setMarginSlabs] = (0, import_react14.useState)(slabs), [quotes, setQuotes] = (0, import_react14.useState)([]), [lines, setLines] = (0, import_react14.useState)([]), [catalog, setCatalog] = (0, import_react14.useState)([]), [publications, setPublications] = (0, import_react14.useState)([]), [history, setHistory] = (0, import_react14.useState)([]), [id, setId] = (0, import_react14.useState)(""), [summary, setSummary] = (0, import_react14.useState)(null), [busy, setBusy] = (0, import_react14.useState)(false), [error, setError] = (0, import_react14.useState)(""), [notice, setNotice] = (0, import_react14.useState)(""), [editing, setEditing] = (0, import_react14.useState)(null);
  const client = profile.role === "client", admin = profile.role === "admin", sales = admin || profile.crm_permissions?.some((p) => ["sales.manage", "sales.own"].includes(p));
  const quote = quotes.find((q) => q.id === id), accepted = publications.some((p) => p.status === "Accepted"), locked = accepted || ["won", "lost"].includes(deal?.stage), canEdit = Boolean(deal && !locked && (admin || profile.crm_permissions?.includes("sales.manage") || profile.crm_permissions?.includes("sales.own") && deal.owner_id === profile.id));
  const load = async () => {
    const published = await workspaceRows("crm_quote_publications");
    setPublications(published.filter((p) => !deal || p.deal_id === deal.id));
    if (!client && deal) {
      const [q, l, c, h, settings] = await Promise.all(["crm_quotes", "crm_quote_lines", "crm_catalog", "crm_quote_history", "crm_settings"].map((t) => workspaceRows(t)));
      const configured = settings.find((r) => r.id === "margin_slabs");
      if (configured) setMarginSlabs(configured.value.map(Number));
      setQuotes(q.filter((r) => r.deal_id === deal.id));
      setLines(l);
      setCatalog(c);
      setHistory(h.filter((r) => r.deal_id === deal.id));
    }
  };
  (0, import_react14.useEffect)(() => {
    let live = true;
    load().catch((e) => {
      if (live) setError(e.message);
    });
    return () => {
      live = false;
    };
  }, [profile.id, deal?.id]);
  (0, import_react14.useEffect)(() => {
    let live = true;
    setSummary(null);
    if (!quote) return;
    Promise.resolve(db.rpc("crm_quote_summary", { p_quote: quote.id })).then((r) => {
      if (live) {
        try {
          setSummary(check(r));
        } catch (e) {
          setError(e.message);
        }
      }
    }).catch((e) => {
      if (live) setError(e.message);
    });
    return () => {
      live = false;
    };
  }, [quote?.id, quote?.version]);
  const run = async (name, args, message) => {
    setBusy(true);
    setError("");
    try {
      const result = check(await db.rpc(name, args));
      await load();
      onChanged();
      setNotice(message);
      return { ok: true, result };
    } catch (e) {
      setError(e.message);
      return { ok: false, result: null };
    } finally {
      setBusy(false);
    }
  };
  const pdf = async (p) => {
    setBusy(true);
    try {
      await quotationPDF(p);
    } catch (e) {
      setError(e.message);
    } finally {
      setBusy(false);
    }
  };
  const quoteForm = (q) => /* @__PURE__ */ (0, import_jsx_runtime15.jsxs)("form", { className: "p-form", onSubmit: async (e) => {
    e.preventDefault();
    const data = Object.fromEntries(new FormData(e.currentTarget));
    const r = await run("save_crm_quote", { p_id: q?.id || null, p_version: q?.version || null, p_deal: deal.id, p_data: data }, "Quotation draft saved.");
    if (r.ok) setId(r.result);
  }, children: [
    /* @__PURE__ */ (0, import_jsx_runtime15.jsx)(Field, { name: "title", label: "Quotation title", value: q?.title || deal?.title, required: true }),
    /* @__PURE__ */ (0, import_jsx_runtime15.jsx)(Field, { name: "option_name", label: "Solution name", value: q?.option_name || "Solution A", required: true }),
    /* @__PURE__ */ (0, import_jsx_runtime15.jsx)(Field, { name: "currency", label: "Currency", value: q?.currency || "PKR", required: true }),
    /* @__PURE__ */ (0, import_jsx_runtime15.jsx)(Field, { name: "valid_until", label: "Valid until", type: "date", value: q?.valid_until || day(), required: true }),
    /* @__PURE__ */ (0, import_jsx_runtime15.jsx)(Margin, { choices: marginSlabs, name: "default_margin", value: q?.default_margin || 20 }),
    /* @__PURE__ */ (0, import_jsx_runtime15.jsx)(Field, { name: "pra_percent", label: "PRA services tax %", type: "number", value: q?.pra_percent || 0, required: true }),
    /* @__PURE__ */ (0, import_jsx_runtime15.jsx)(Field, { name: "service_tax_base", label: "Taxable services amount", type: "number", value: q?.service_tax_base || 0, required: true }),
    /* @__PURE__ */ (0, import_jsx_runtime15.jsx)(Field, { name: "wht_percent", label: "Client WHT withholding %", type: "number", value: q?.wht_percent || 0, required: true }),
    /* @__PURE__ */ (0, import_jsx_runtime15.jsx)(Field, { name: "bank_charges", label: "Internal bank charges", type: "number", value: q?.bank_charges || 0, required: true }),
    /* @__PURE__ */ (0, import_jsx_runtime15.jsx)(Field, { name: "contingency_percent", label: "Internal contingency % of planned cost", type: "number", value: q?.contingency_percent || 0, required: true }),
    /* @__PURE__ */ (0, import_jsx_runtime15.jsx)(Field, { name: "override_total", label: "Final quoted total override, including tax (optional)", type: "number", value: q?.override_total ?? "" }),
    /* @__PURE__ */ (0, import_jsx_runtime15.jsx)(Field, { name: "terms", label: "Terms & conditions", type: "textarea", value: q?.terms }),
    /* @__PURE__ */ (0, import_jsx_runtime15.jsx)("p", { children: "Material price = unit cost \xF7 (1 \u2212 gross margin). Labour, inventory, travel and bank charges are internal costs. Set the selling prices or final override to cover the whole project." }),
    /* @__PURE__ */ (0, import_jsx_runtime15.jsx)("button", { disabled: busy, children: q ? "Save quotation settings" : "Create quotation option" })
  ] }, q ? `${q.id}:${q.version}` : "new-quote");
  return /* @__PURE__ */ (0, import_jsx_runtime15.jsxs)("section", { className: "p-panel", children: [
    /* @__PURE__ */ (0, import_jsx_runtime15.jsx)("h2", { children: client ? "My quotations" : "Quotation & BOQ" }),
    error && /* @__PURE__ */ (0, import_jsx_runtime15.jsx)("p", { role: "alert", className: "p-error", children: error }),
    notice && /* @__PURE__ */ (0, import_jsx_runtime15.jsx)("p", { role: "status", children: notice }),
    !client && deal && /* @__PURE__ */ (0, import_jsx_runtime15.jsxs)(import_jsx_runtime15.Fragment, { children: [
      /* @__PURE__ */ (0, import_jsx_runtime15.jsx)("p", { children: "Each solution has its own draft. Publishing creates a fixed revision; the client chooses one solution. Internal costs and margins stay private." }),
      locked && /* @__PURE__ */ (0, import_jsx_runtime15.jsx)("p", { children: "The accepted quotation or terminal deal is locked. Further changes require a change-order workflow." }),
      canEdit && /* @__PURE__ */ (0, import_jsx_runtime15.jsxs)("details", { children: [
        /* @__PURE__ */ (0, import_jsx_runtime15.jsx)("summary", { children: "New solution option" }),
        quoteForm()
      ] }),
      /* @__PURE__ */ (0, import_jsx_runtime15.jsxs)("label", { className: "p-field", children: [
        "Quotation option",
        /* @__PURE__ */ (0, import_jsx_runtime15.jsxs)("select", { value: id, onChange: (e) => {
          setId(e.target.value);
          setEditing(null);
        }, children: [
          /* @__PURE__ */ (0, import_jsx_runtime15.jsx)("option", { value: "", children: "Choose a quotation" }),
          quotes.map((q) => /* @__PURE__ */ (0, import_jsx_runtime15.jsxs)("option", { value: q.id, children: [
            q.number,
            " \xB7 ",
            q.option_name
          ] }, q.id))
        ] })
      ] }),
      quote && /* @__PURE__ */ (0, import_jsx_runtime15.jsxs)(import_jsx_runtime15.Fragment, { children: [
        /* @__PURE__ */ (0, import_jsx_runtime15.jsxs)("h3", { children: [
          quote.number,
          " \xB7 ",
          quote.option_name
        ] }),
        canEdit && /* @__PURE__ */ (0, import_jsx_runtime15.jsxs)("details", { children: [
          /* @__PURE__ */ (0, import_jsx_runtime15.jsx)("summary", { children: "Quotation settings, tax & charges" }),
          quoteForm(quote)
        ] }),
        products.filter((p) => p.status === "Active").map((product) => {
          const sectionLines = lines.filter((l) => l.quote_id === quote.id && l.product_line_id === product.id), sectionEditable = !locked && (canEdit || profile.crm_permissions?.includes("product.own") && editableBoardIds.includes(product.board_id));
          return /* @__PURE__ */ (0, import_jsx_runtime15.jsxs)("section", { className: "p-panel", children: [
            /* @__PURE__ */ (0, import_jsx_runtime15.jsx)("h3", { children: boards.find((b) => b.id === product.board_id)?.name || "Product section" }),
            !sectionEditable && /* @__PURE__ */ (0, import_jsx_runtime15.jsx)("p", { children: "Read-only BOQ section" }),
            /* @__PURE__ */ (0, import_jsx_runtime15.jsx)("div", { className: "p-table-scroll", children: /* @__PURE__ */ (0, import_jsx_runtime15.jsxs)("table", { className: "p-table", children: [
              /* @__PURE__ */ (0, import_jsx_runtime15.jsx)("thead", { children: /* @__PURE__ */ (0, import_jsx_runtime15.jsxs)("tr", { children: [
                /* @__PURE__ */ (0, import_jsx_runtime15.jsx)("th", { children: "Block" }),
                /* @__PURE__ */ (0, import_jsx_runtime15.jsx)("th", { children: "Description" }),
                /* @__PURE__ */ (0, import_jsx_runtime15.jsx)("th", { children: "Quantity" }),
                /* @__PURE__ */ (0, import_jsx_runtime15.jsx)("th", { children: "Unit cost" }),
                /* @__PURE__ */ (0, import_jsx_runtime15.jsx)("th", { children: "Margin" }),
                /* @__PURE__ */ (0, import_jsx_runtime15.jsx)("th", { children: "Vendor" }),
                /* @__PURE__ */ (0, import_jsx_runtime15.jsx)("th", { children: "Actions" })
              ] }) }),
              /* @__PURE__ */ (0, import_jsx_runtime15.jsx)("tbody", { children: sectionLines.map((l) => /* @__PURE__ */ (0, import_jsx_runtime15.jsxs)("tr", { children: [
                /* @__PURE__ */ (0, import_jsx_runtime15.jsx)("td", { children: l.block }),
                /* @__PURE__ */ (0, import_jsx_runtime15.jsx)("td", { children: l.description }),
                /* @__PURE__ */ (0, import_jsx_runtime15.jsxs)("td", { children: [
                  l.quantity,
                  " ",
                  l.unit
                ] }),
                /* @__PURE__ */ (0, import_jsx_runtime15.jsx)("td", { children: money(l.unit_cost) }),
                /* @__PURE__ */ (0, import_jsx_runtime15.jsx)("td", { children: l.margin ?? "Default" }),
                /* @__PURE__ */ (0, import_jsx_runtime15.jsx)("td", { children: l.vendor }),
                /* @__PURE__ */ (0, import_jsx_runtime15.jsx)("td", { children: sectionEditable && /* @__PURE__ */ (0, import_jsx_runtime15.jsxs)(import_jsx_runtime15.Fragment, { children: [
                  /* @__PURE__ */ (0, import_jsx_runtime15.jsx)("button", { disabled: busy, onClick: () => setEditing(l), children: "Edit BOQ line" }),
                  /* @__PURE__ */ (0, import_jsx_runtime15.jsx)("button", { disabled: busy || lines.some((x) => x.material_line_id === l.id), onClick: () => run("save_crm_quote_line", { p_id: l.id, p_version: l.version, p_quote: quote.id, p_quote_version: quote.version, p_product: product.id, p_data: {}, p_delete: true }, "BOQ line removed."), children: "Remove" })
                ] }) })
              ] }, l.id)) })
            ] }) }),
            sectionEditable && /* @__PURE__ */ (0, import_jsx_runtime15.jsx)(BoqLine, { line: editing?.product_line_id === product.id ? editing : null, product, quote, catalog, marginSlabs, materials: sectionLines.filter((l) => l.block === "Material"), busy, onSave: async (data) => {
              const current = editing?.product_line_id === product.id ? editing : null;
              const r = await run("save_crm_quote_line", { p_id: current?.id || null, p_version: current?.version || null, p_quote: quote.id, p_quote_version: quote.version, p_product: product.id, p_data: data, p_delete: false }, "BOQ line saved.");
              if (r.ok) setEditing(null);
            }, onCancel: () => setEditing(null) }, `${quote.id}:${quote.version}:${product.id}:${editing?.id || "new"}`)
          ] }, product.id);
        }),
        summary && /* @__PURE__ */ (0, import_jsx_runtime15.jsxs)("section", { children: [
          /* @__PURE__ */ (0, import_jsx_runtime15.jsx)("h3", { children: "Internal calculation" }),
          /* @__PURE__ */ (0, import_jsx_runtime15.jsxs)("p", { children: [
            "Planned cost ",
            money(summary.cost),
            " \xB7 Client subtotal ",
            money(summary.subtotal),
            " \xB7 Tax ",
            money(summary.tax_total),
            " \xB7 Total ",
            money(summary.total)
          ] }),
          /* @__PURE__ */ (0, import_jsx_runtime15.jsxs)("p", { children: [
            "Planned profit ",
            money(summary.profit),
            " \xB7 Gross margin ",
            money(summary.margin_percent),
            "% \xB7 Net payment after WHT ",
            money(summary.receivable)
          ] }),
          summary.warnings.map((w) => /* @__PURE__ */ (0, import_jsx_runtime15.jsx)("p", { className: "p-error", children: w }, w))
        ] }),
        canEdit && /* @__PURE__ */ (0, import_jsx_runtime15.jsxs)("form", { className: "p-form", onSubmit: (e) => {
          e.preventDefault();
          const f = new FormData(e.currentTarget);
          run("publish_crm_quote", { p_quote: quote.id, p_version: quote.version, p_company: deal.company_id || f.get("company"), p_acknowledge: f.get("acknowledge") === "on" }, "Quotation revision published in the client portal.");
        }, children: [
          !deal.company_id && (admin ? /* @__PURE__ */ (0, import_jsx_runtime15.jsxs)("label", { className: "p-field", children: [
            "Customer receiving this quotation",
            /* @__PURE__ */ (0, import_jsx_runtime15.jsxs)("select", { name: "company", required: true, children: [
              /* @__PURE__ */ (0, import_jsx_runtime15.jsx)("option", { value: "", children: "Select existing customer" }),
              companies.map((c) => /* @__PURE__ */ (0, import_jsx_runtime15.jsx)("option", { value: c.id, children: c.name }, c.id))
            ] })
          ] }) : /* @__PURE__ */ (0, import_jsx_runtime15.jsx)("p", { children: "An administrator must link the customer before publication." })),
          /* @__PURE__ */ (0, import_jsx_runtime15.jsxs)("label", { className: "p-check", children: [
            /* @__PURE__ */ (0, import_jsx_runtime15.jsx)("input", { name: "acknowledge", type: "checkbox" }),
            "I reviewed the cost and validation warnings"
          ] }),
          /* @__PURE__ */ (0, import_jsx_runtime15.jsx)("button", { disabled: busy || !admin && !deal.company_id, children: "Publish new revision" })
        ] })
      ] }),
      admin && /* @__PURE__ */ (0, import_jsx_runtime15.jsx)(CatalogEditor, { rows: catalog, marginSlabs, busy, run }),
      /* @__PURE__ */ (0, import_jsx_runtime15.jsxs)("details", { children: [
        /* @__PURE__ */ (0, import_jsx_runtime15.jsx)("summary", { children: "Quotation activity" }),
        history.slice().sort((a, b) => b.created_at.localeCompare(a.created_at)).map((h) => /* @__PURE__ */ (0, import_jsx_runtime15.jsxs)("p", { children: [
          h.action,
          " \xB7 ",
          new Date(h.created_at).toLocaleString()
        ] }, h.id))
      ] })
    ] }),
    /* @__PURE__ */ (0, import_jsx_runtime15.jsx)("h3", { children: "Published revisions" }),
    publications.length === 0 && /* @__PURE__ */ (0, import_jsx_runtime15.jsx)("p", { children: "No published quotations." }),
    publications.slice().sort((a, b) => b.published_at.localeCompare(a.published_at)).map((p) => /* @__PURE__ */ (0, import_jsx_runtime15.jsxs)("article", { className: "p-panel", children: [
      /* @__PURE__ */ (0, import_jsx_runtime15.jsxs)("h3", { children: [
        p.number,
        " v",
        p.revision,
        " \xB7 ",
        p.option_name
      ] }),
      /* @__PURE__ */ (0, import_jsx_runtime15.jsxs)("p", { children: [
        p.title,
        " \xB7 ",
        p.company_name,
        " \xB7 ",
        p.status,
        " \xB7 Valid until ",
        p.valid_until
      ] }),
      /* @__PURE__ */ (0, import_jsx_runtime15.jsx)("div", { className: "p-table-scroll", children: /* @__PURE__ */ (0, import_jsx_runtime15.jsxs)("table", { className: "p-table", children: [
        /* @__PURE__ */ (0, import_jsx_runtime15.jsx)("thead", { children: /* @__PURE__ */ (0, import_jsx_runtime15.jsxs)("tr", { children: [
          /* @__PURE__ */ (0, import_jsx_runtime15.jsx)("th", { children: "Product" }),
          /* @__PURE__ */ (0, import_jsx_runtime15.jsx)("th", { children: "Description" }),
          /* @__PURE__ */ (0, import_jsx_runtime15.jsx)("th", { children: "Quantity" }),
          /* @__PURE__ */ (0, import_jsx_runtime15.jsx)("th", { children: "Unit price" }),
          /* @__PURE__ */ (0, import_jsx_runtime15.jsx)("th", { children: "Total" })
        ] }) }),
        /* @__PURE__ */ (0, import_jsx_runtime15.jsx)("tbody", { children: p.items.map((i, n) => /* @__PURE__ */ (0, import_jsx_runtime15.jsxs)("tr", { children: [
          /* @__PURE__ */ (0, import_jsx_runtime15.jsx)("td", { children: i.product }),
          /* @__PURE__ */ (0, import_jsx_runtime15.jsx)("td", { children: i.description }),
          /* @__PURE__ */ (0, import_jsx_runtime15.jsxs)("td", { children: [
            i.quantity,
            " ",
            i.unit
          ] }),
          /* @__PURE__ */ (0, import_jsx_runtime15.jsx)("td", { children: money(i.unit_price) }),
          /* @__PURE__ */ (0, import_jsx_runtime15.jsx)("td", { children: money(i.total) })
        ] }, n)) })
      ] }) }),
      /* @__PURE__ */ (0, import_jsx_runtime15.jsxs)("p", { children: [
        p.currency,
        " ",
        money(p.total),
        " \xB7 Tax ",
        money(p.tax_total),
        " \xB7 WHT ",
        money(p.wht_total),
        " \xB7 Net payment ",
        money(p.receivable)
      ] }),
      /* @__PURE__ */ (0, import_jsx_runtime15.jsx)("p", { className: "p-pre", children: p.terms }),
      /* @__PURE__ */ (0, import_jsx_runtime15.jsx)("button", { disabled: busy, onClick: () => pdf(p), children: "Download quotation PDF" }),
      client && p.status === "Published" && p.valid_until >= day() && /* @__PURE__ */ (0, import_jsx_runtime15.jsxs)("form", { className: "p-form", onSubmit: (e) => {
        e.preventDefault();
        const f = new FormData(e.currentTarget);
        run("decide_crm_quote", { p_publication: p.id, p_version: p.version, p_action: f.get("action"), p_note: f.get("note") }, "Quotation decision recorded.");
      }, children: [
        /* @__PURE__ */ (0, import_jsx_runtime15.jsxs)("label", { className: "p-field", children: [
          "Your decision",
          /* @__PURE__ */ (0, import_jsx_runtime15.jsxs)("select", { name: "action", children: [
            /* @__PURE__ */ (0, import_jsx_runtime15.jsx)("option", { value: "accept", children: "Accept this solution" }),
            /* @__PURE__ */ (0, import_jsx_runtime15.jsx)("option", { value: "decline", children: "Decline this solution" })
          ] })
        ] }),
        /* @__PURE__ */ (0, import_jsx_runtime15.jsx)(Field, { name: "note", label: "Decision notes", type: "textarea" }),
        /* @__PURE__ */ (0, import_jsx_runtime15.jsx)("button", { disabled: busy, children: "Submit quotation decision" })
      ] }),
      canEdit && p.status === "Published" && /* @__PURE__ */ (0, import_jsx_runtime15.jsx)("button", { disabled: busy, onClick: () => run("decide_crm_quote", { p_publication: p.id, p_version: p.version, p_action: "withdraw", p_note: "" }, "Quotation withdrawn."), children: "Withdraw revision" })
    ] }, p.id))
  ] });
}
function BoqLine({ line, quote, product, catalog, marginSlabs, materials, busy, onSave, onCancel }) {
  const [selected, setSelected] = (0, import_react14.useState)(null), [block, setBlock] = (0, import_react14.useState)(line?.block || "Material");
  return /* @__PURE__ */ (0, import_jsx_runtime15.jsxs)("form", { className: "p-form", onSubmit: (e) => {
    e.preventDefault();
    onSave(Object.fromEntries(new FormData(e.currentTarget)));
  }, children: [
    /* @__PURE__ */ (0, import_jsx_runtime15.jsx)("h4", { children: line ? "Edit BOQ line" : "Add BOQ line" }),
    /* @__PURE__ */ (0, import_jsx_runtime15.jsxs)("label", { className: "p-field", children: [
      "Cost block",
      /* @__PURE__ */ (0, import_jsx_runtime15.jsx)("select", { name: "block", value: block, onChange: (e) => setBlock(e.target.value), children: ["Material", "Labour", "Inventory", "TADA"].map((b) => /* @__PURE__ */ (0, import_jsx_runtime15.jsx)("option", { children: b }, b)) })
    ] }),
    /* @__PURE__ */ (0, import_jsx_runtime15.jsxs)("label", { className: "p-field", children: [
      "Product catalogue",
      /* @__PURE__ */ (0, import_jsx_runtime15.jsxs)("select", { name: "catalog_id", defaultValue: line?.catalog_id || "", onChange: (e) => setSelected(catalog.find((c) => c.id === e.target.value) || null), children: [
        /* @__PURE__ */ (0, import_jsx_runtime15.jsx)("option", { value: "", children: "Custom item" }),
        catalog.filter((c) => c.active).map((c) => /* @__PURE__ */ (0, import_jsx_runtime15.jsxs)("option", { value: c.id, children: [
          c.name,
          " \xB7 ",
          c.brand,
          " ",
          c.model
        ] }, c.id))
      ] })
    ] }),
    /* @__PURE__ */ (0, import_jsx_runtime15.jsxs)("div", { children: [
      /* @__PURE__ */ (0, import_jsx_runtime15.jsx)(Field, { name: "description", label: "BOQ description", value: selected ? [selected.name, selected.brand, selected.model].filter(Boolean).join(" ") : line?.description, required: true }),
      /* @__PURE__ */ (0, import_jsx_runtime15.jsx)(Field, { name: "unit", label: "Unit", value: selected?.unit || line?.unit || "each", required: true }),
      /* @__PURE__ */ (0, import_jsx_runtime15.jsx)(Field, { name: "quantity", label: "Quantity", type: "number", value: line?.quantity || 1, required: true }),
      /* @__PURE__ */ (0, import_jsx_runtime15.jsx)(Field, { name: "unit_cost", label: "Estimated unit cost", type: "number", value: selected?.last_rate ?? line?.unit_cost ?? 0, required: true }),
      /* @__PURE__ */ (0, import_jsx_runtime15.jsx)(Margin, { choices: marginSlabs, value: selected?.margin ?? line?.margin ?? "", inherit: true })
    ] }, selected?.id || "custom"),
    /* @__PURE__ */ (0, import_jsx_runtime15.jsx)(Field, { name: "vendor", label: "Vendor (internal)", value: line?.vendor }),
    block === "Material" && /* @__PURE__ */ (0, import_jsx_runtime15.jsxs)("label", { className: "p-check", children: [
      /* @__PURE__ */ (0, import_jsx_runtime15.jsx)("input", { name: "labour_required", type: "checkbox", value: "true", defaultChecked: line?.labour_required }),
      "Matching labour required"
    ] }),
    block === "Labour" && /* @__PURE__ */ (0, import_jsx_runtime15.jsxs)("label", { className: "p-field", children: [
      "Matching material",
      /* @__PURE__ */ (0, import_jsx_runtime15.jsxs)("select", { name: "material_line_id", defaultValue: line?.material_line_id || "", children: [
        /* @__PURE__ */ (0, import_jsx_runtime15.jsx)("option", { value: "", children: "No matching material" }),
        materials.map((m) => /* @__PURE__ */ (0, import_jsx_runtime15.jsx)("option", { value: m.id, children: m.description }, m.id))
      ] })
    ] }),
    block === "Inventory" && /* @__PURE__ */ (0, import_jsx_runtime15.jsxs)("label", { className: "p-field", children: [
      "Inventory type",
      /* @__PURE__ */ (0, import_jsx_runtime15.jsxs)("select", { name: "inventory_kind", defaultValue: line?.inventory_kind || "Consumable", children: [
        /* @__PURE__ */ (0, import_jsx_runtime15.jsx)("option", { children: "Consumable" }),
        /* @__PURE__ */ (0, import_jsx_runtime15.jsx)("option", { children: "Returnable tool" })
      ] })
    ] }),
    block === "TADA" && /* @__PURE__ */ (0, import_jsx_runtime15.jsxs)("fieldset", { children: [
      /* @__PURE__ */ (0, import_jsx_runtime15.jsx)("legend", { children: "Fuel and crew planner" }),
      /* @__PURE__ */ (0, import_jsx_runtime15.jsxs)("label", { className: "p-check", children: [
        /* @__PURE__ */ (0, import_jsx_runtime15.jsx)("input", { type: "checkbox", name: "plan_enabled", value: "true", defaultChecked: Boolean(line?.planner?.km !== void 0) }),
        "Calculate cost from fuel and crew parameters"
      ] }),
      [["km", "Travel distance (km)", 0], ["trips", "Trips", 0], ["fuel_average", "Fuel average (km/litre)", 10], ["petrol_price", "Petrol price per litre", 0], ["crew", "Crew count", 0], ["days", "Man-days per person", 0], ["day_rate", "Cost per man-day", 0]].map(([name, label, value]) => /* @__PURE__ */ (0, import_jsx_runtime15.jsx)(Field, { name, label, type: "number", value: line?.planner?.[String(name)] ?? value }, String(name))),
      /* @__PURE__ */ (0, import_jsx_runtime15.jsx)("p", { children: "Fuel = km \xD7 trips \xF7 fuel average \xD7 petrol price. Crew = people \xD7 days \xD7 day rate. The server calculates one job cost." })
    ] }),
    /* @__PURE__ */ (0, import_jsx_runtime15.jsx)("button", { disabled: busy, children: "Save BOQ line" }),
    line && /* @__PURE__ */ (0, import_jsx_runtime15.jsx)("button", { type: "button", onClick: onCancel, children: "Cancel edit" })
  ] });
}
function CatalogEditor({ rows, marginSlabs, busy, run }) {
  const [editing, setEditing] = (0, import_react14.useState)(null);
  return /* @__PURE__ */ (0, import_jsx_runtime15.jsxs)("details", { children: [
    /* @__PURE__ */ (0, import_jsx_runtime15.jsx)("summary", { children: "Product catalogue administration" }),
    /* @__PURE__ */ (0, import_jsx_runtime15.jsxs)("label", { className: "p-field", children: [
      "Edit item",
      /* @__PURE__ */ (0, import_jsx_runtime15.jsxs)("select", { value: editing?.id || "", onChange: (e) => setEditing(rows.find((r) => r.id === e.target.value) || null), children: [
        /* @__PURE__ */ (0, import_jsx_runtime15.jsx)("option", { value: "", children: "New catalogue item" }),
        rows.map((r) => /* @__PURE__ */ (0, import_jsx_runtime15.jsx)("option", { value: r.id, children: r.name }, r.id))
      ] })
    ] }),
    /* @__PURE__ */ (0, import_jsx_runtime15.jsxs)("form", { className: "p-form", onSubmit: (e) => {
      e.preventDefault();
      const data = Object.fromEntries(new FormData(e.currentTarget));
      run("save_crm_catalog", { p_id: editing?.id || null, p_version: editing?.version || null, p_data: { ...data, active: data.active === "on" } }, "Catalogue item saved.");
      setEditing(null);
    }, children: [
      /* @__PURE__ */ (0, import_jsx_runtime15.jsx)(Field, { name: "name", label: "Item name", value: editing?.name, required: true }),
      ["category", "brand", "model"].map((name) => /* @__PURE__ */ (0, import_jsx_runtime15.jsx)(Field, { name, label: name, value: editing?.[name] }, name)),
      /* @__PURE__ */ (0, import_jsx_runtime15.jsx)(Field, { name: "unit", label: "Unit", value: editing?.unit || "each", required: true }),
      /* @__PURE__ */ (0, import_jsx_runtime15.jsx)(Field, { name: "last_rate", label: "Last purchase rate", type: "number", value: editing?.last_rate || 0, required: true }),
      /* @__PURE__ */ (0, import_jsx_runtime15.jsx)(Margin, { choices: marginSlabs, value: editing?.margin || 20 }),
      /* @__PURE__ */ (0, import_jsx_runtime15.jsxs)("label", { className: "p-check", children: [
        /* @__PURE__ */ (0, import_jsx_runtime15.jsx)("input", { type: "checkbox", name: "active", defaultChecked: editing?.active ?? true }),
        "Active catalogue item"
      ] }),
      /* @__PURE__ */ (0, import_jsx_runtime15.jsx)("button", { disabled: busy, children: "Save catalogue item" })
    ] }, editing ? editing.id + ":" + editing.version : "new")
  ] });
}

// src/portal/crm-sales.tsx
var import_jsx_runtime16 = __toESM(require_jsx_runtime(), 1);
var today2 = () => (/* @__PURE__ */ new Date()).toISOString().slice(0, 10);
var fields = ["name", "email", "phone", "company", "city", "country", "message", "campaign"];
var opts = (rows) => rows.map((r) => /* @__PURE__ */ (0, import_jsx_runtime16.jsx)("option", { value: r.id, children: r.name || r.title }, r.id));
function Input2({ name, label, type = "text", value = "", required = false }) {
  return /* @__PURE__ */ (0, import_jsx_runtime16.jsxs)("label", { className: "p-field", children: [
    label,
    type === "textarea" ? /* @__PURE__ */ (0, import_jsx_runtime16.jsx)("textarea", { name, defaultValue: value, required, maxLength: 9900 }) : /* @__PURE__ */ (0, import_jsx_runtime16.jsx)("input", { name, type, defaultValue: value, required, maxLength: type === "text" ? 200 : void 0 })
  ] });
}
function CrmSales({ view, profile, members, companies = [], initialDealId = "" }) {
  const [data, setData] = (0, import_react15.useState)({ boards: [], stages: [], leads: [], deals: [], lines: [], activity: [], views: [], memberships: [], settings: [], tasks: [] }), [busy, setBusy] = (0, import_react15.useState)(false), [loaded, setLoaded] = (0, import_react15.useState)(false), [error, setError] = (0, import_react15.useState)(""), [note, setNote] = (0, import_react15.useState)("");
  const [board, setBoard] = (0, import_react15.useState)(""), [mode, setMode] = (0, import_react15.useState)("list"), [search, setSearch] = (0, import_react15.useState)(""), [stage, setStage] = (0, import_react15.useState)(""), [owner, setOwner] = (0, import_react15.useState)(""), [source, setSource] = (0, import_react15.useState)(""), [attention, setAttention] = (0, import_react15.useState)(""), [selected, setSelected] = (0, import_react15.useState)([]), [leadId, setLeadId] = (0, import_react15.useState)(""), [dealId, setDealId] = (0, import_react15.useState)(initialDealId);
  const [upload, setUpload] = (0, import_react15.useState)([]), [mapping, setMapping] = (0, import_react15.useState)({}), [batch, setBatch] = (0, import_react15.useState)(""), [adding, setAdding] = (0, import_react15.useState)(false);
  const admin = profile.role === "admin", permissions = profile.crm_permissions || [], sales = admin || permissions.includes("sales.manage") || permissions.includes("sales.own"), specialist = permissions.includes("product.own");
  const load = async () => {
    const tables = ["crm_boards", "crm_board_stages", "crm_leads", "crm_deals", "crm_product_lines", "crm_sales_activity", "crm_saved_views", "crm_board_memberships", "crm_settings", "crm_sales_tasks"];
    const rows = await Promise.all(tables.map((t) => workspaceRows(t)));
    setData(Object.fromEntries(["boards", "stages", "leads", "deals", "lines", "activity", "views", "memberships", "settings", "tasks"].map((k, i) => [k, rows[i]])));
    setLoaded(true);
  };
  (0, import_react15.useEffect)(() => {
    let live = true;
    if (!sales && !specialist) return;
    load().catch((e) => {
      if (live) setError(e.message);
    });
    return () => {
      live = false;
    };
  }, [profile.id, view]);
  const run = async (name, args, message) => {
    setBusy(true);
    setError("");
    setNote("");
    try {
      const result = check(await db.rpc(name, args));
      await load();
      setNote(message);
      return { ok: true, result };
    } catch (e) {
      setError(e.message);
      return { ok: false, result: null };
    } finally {
      setBusy(false);
    }
  };
  if (!sales && !specialist) return /* @__PURE__ */ (0, import_jsx_runtime16.jsx)("p", { role: "alert", children: "Sales or product department access required." });
  if (view === "sales_configuration" && !admin) return /* @__PURE__ */ (0, import_jsx_runtime16.jsx)("p", { role: "alert", children: "Administrator access required." });
  const boards = data.boards, boardRow = boards.find((b) => b.id === board), stages = data.stages.filter((s) => s.board_id === board && s.active).sort((a, b) => a.position - b.position || a.code.localeCompare(b.code));
  const leads = data.leads.filter((l) => (l.status !== "Assigned" || stage === "Assigned") && (!search || [l.name, l.company_name, l.email, l.phone, ...l.tags].join(" ").toLowerCase().includes(search.toLowerCase())) && (!stage || l.status === stage) && (!owner || l.owner_id === owner) && (!source || l.source === source));
  const lines = data.lines, lead = data.leads.find((l) => l.id === leadId), deal = data.deals.find((d) => d.id === dealId), contact = data.leads.find((l) => l.id === deal?.lead_id);
  const deals = data.deals.filter((d) => (!board || lines.some((l) => l.deal_id === d.id && l.board_id === board)) && (!search || [d.title, ...data.leads.find((l) => l.id === d.lead_id)?.tags || []].join(" ").toLowerCase().includes(search.toLowerCase())) && (!stage || d.stage === stage) && (!owner || d.owner_id === owner) && (!source || data.leads.find((l) => l.id === d.lead_id)?.source === source) && (!attention || attention === "no_step" && !d.next_followup || attention === "due" && d.next_followup && d.next_followup <= today2() && !["won", "lost"].includes(d.stage) || attention === "rotting" && Date.now() - Date.parse(d.last_activity_at) > (boardRow?.rotting_days || 7) * 864e5));
  const allowedOwners = admin ? members.filter((u) => u.active && u.role !== "client") : [profile];
  const filters = { board, mode, search, stage, owner, source, attention };
  const apply = (f) => {
    for (const [k, set] of Object.entries({ board: setBoard, mode: setMode, search: setSearch, stage: setStage, owner: setOwner, source: setSource, attention: setAttention })) set(typeof f[k] === "string" ? f[k] : "");
  };
  const assignment = (ids) => /* @__PURE__ */ (0, import_jsx_runtime16.jsxs)("form", { className: "p-form", onSubmit: async (e) => {
    e.preventDefault();
    const d = new FormData(e.currentTarget);
    const r = await run("bulk_assign_crm_products", { p_leads: ids.map((l) => ({ id: l.id, version: l.version })), p_boards: d.getAll("board"), p_owner: d.get("owner"), p_followup: d.get("followup") }, "Products assigned to one deal per lead.");
    if (r.ok) {
      setSelected([]);
      setLeadId("");
    }
  }, children: [
    /* @__PURE__ */ (0, import_jsx_runtime16.jsxs)("fieldset", { children: [
      /* @__PURE__ */ (0, import_jsx_runtime16.jsx)("legend", { children: "Products \u2014 choose one or more" }),
      boards.filter((b) => b.active).map((b) => /* @__PURE__ */ (0, import_jsx_runtime16.jsxs)("label", { className: "p-check", children: [
        /* @__PURE__ */ (0, import_jsx_runtime16.jsx)("input", { name: "board", value: b.id, type: "checkbox" }),
        b.name
      ] }, b.id))
    ] }),
    /* @__PURE__ */ (0, import_jsx_runtime16.jsxs)("label", { className: "p-field", children: [
      "Sales owner",
      /* @__PURE__ */ (0, import_jsx_runtime16.jsx)("select", { name: "owner", required: true, defaultValue: profile.id, children: opts(allowedOwners) })
    ] }),
    /* @__PURE__ */ (0, import_jsx_runtime16.jsx)(Input2, { name: "followup", label: "Next follow-up UTC", type: "date", required: true, value: today2() }),
    /* @__PURE__ */ (0, import_jsx_runtime16.jsx)("button", { disabled: busy || !ids.length, children: "Assign selected products" })
  ] });
  const dealCard = (d) => {
    const productLines = lines.filter((l) => l.deal_id === d.id);
    return /* @__PURE__ */ (0, import_jsx_runtime16.jsxs)("button", { className: "p-panel sales-card", draggable: sales, onDragStart: (e) => e.dataTransfer.setData("text/plain", d.id), onClick: () => setDealId(d.id), children: [
      /* @__PURE__ */ (0, import_jsx_runtime16.jsx)("strong", { children: d.title }),
      /* @__PURE__ */ (0, import_jsx_runtime16.jsxs)("span", { children: [
        d.currency,
        " ",
        Number(d.estimated_value).toLocaleString(),
        " \xB7 ",
        members.find((u) => u.id === d.owner_id)?.name || "Sales owner"
      ] }),
      /* @__PURE__ */ (0, import_jsx_runtime16.jsxs)("span", { children: [
        "Follow-up: ",
        d.next_followup || "No next step",
        " \xB7 ",
        Math.max(0, Math.floor((Date.now() - Date.parse(d.stage_changed_at)) / 864e5)),
        " days in stage"
      ] }),
      /* @__PURE__ */ (0, import_jsx_runtime16.jsx)("span", { children: productLines.map((l) => /* @__PURE__ */ (0, import_jsx_runtime16.jsxs)("span", { className: "p-badge", style: { color: boards.find((b) => b.id === l.board_id)?.color }, children: [
        boards.find((b) => b.id === l.board_id)?.name || "Other product",
        l.status === "Dropped" ? " \xB7 Dropped" : ""
      ] }, l.id)) })
    ] }, d.id);
  };
  return /* @__PURE__ */ (0, import_jsx_runtime16.jsxs)(import_jsx_runtime16.Fragment, { children: [
    /* @__PURE__ */ (0, import_jsx_runtime16.jsx)("h1", { children: view === "raw_leads" ? "Raw Lead Board" : view === "sales_configuration" ? "Sales board configuration" : "Product sales boards" }),
    /* @__PURE__ */ (0, import_jsx_runtime16.jsx)("p", { children: "One customer enquiry becomes one deal with multiple product lines. Board membership and department permissions control access." }),
    error && /* @__PURE__ */ (0, import_jsx_runtime16.jsx)("p", { role: "alert", className: "p-error", children: error }),
    note && /* @__PURE__ */ (0, import_jsx_runtime16.jsx)("p", { role: "status", className: "p-notice", children: note }),
    !loaded && /* @__PURE__ */ (0, import_jsx_runtime16.jsx)("p", { children: "Loading sales records\u2026" }),
    /* @__PURE__ */ (0, import_jsx_runtime16.jsx)("button", { disabled: busy, onClick: () => load().catch((e) => setError(e.message)), children: "Refresh sales" }),
    view === "sales_configuration" ? /* @__PURE__ */ (0, import_jsx_runtime16.jsx)(import_jsx_runtime16.Fragment, { children: boards.map((b) => /* @__PURE__ */ (0, import_jsx_runtime16.jsxs)("section", { className: "p-panel", children: [
      /* @__PURE__ */ (0, import_jsx_runtime16.jsx)("h2", { children: b.name }),
      /* @__PURE__ */ (0, import_jsx_runtime16.jsxs)("p", { children: [
        "Won outcome: ",
        b.outcome
      ] }),
      /* @__PURE__ */ (0, import_jsx_runtime16.jsxs)("form", { className: "p-form", onSubmit: (e) => {
        e.preventDefault();
        const d = new FormData(e.currentTarget);
        run("configure_sales_board", { p_id: b.id, p_version: b.version, p_name: d.get("name"), p_color: d.get("color"), p_rotting: Number(d.get("rotting")), p_active: d.get("active") === "on" }, "Board saved.");
      }, children: [
        /* @__PURE__ */ (0, import_jsx_runtime16.jsx)(Input2, { name: "name", label: "Board name", value: b.name, required: true }),
        /* @__PURE__ */ (0, import_jsx_runtime16.jsx)(Input2, { name: "color", label: "Badge colour", type: "color", value: b.color }),
        /* @__PURE__ */ (0, import_jsx_runtime16.jsx)(Input2, { name: "rotting", label: "Highlight after days without activity", type: "number", value: b.rotting_days, required: true }),
        /* @__PURE__ */ (0, import_jsx_runtime16.jsxs)("label", { className: "p-check", children: [
          /* @__PURE__ */ (0, import_jsx_runtime16.jsx)("input", { name: "active", type: "checkbox", defaultChecked: b.active }),
          "Active board"
        ] }),
        /* @__PURE__ */ (0, import_jsx_runtime16.jsx)("button", { disabled: busy, children: "Save board" })
      ] }, b.id + ":" + b.version),
      /* @__PURE__ */ (0, import_jsx_runtime16.jsx)("h3", { children: "Board members" }),
      /* @__PURE__ */ (0, import_jsx_runtime16.jsxs)("form", { className: "p-form", onSubmit: (e) => {
        e.preventDefault();
        const d = new FormData(e.currentTarget);
        run("set_sales_board_member", { p_board: b.id, p_user: d.get("user"), p_enabled: true }, "Board member added.");
      }, children: [
        /* @__PURE__ */ (0, import_jsx_runtime16.jsxs)("label", { className: "p-field", children: [
          "Staff",
          /* @__PURE__ */ (0, import_jsx_runtime16.jsx)("select", { name: "user", required: true, children: opts(members.filter((u) => u.role === "team" && u.active)) })
        ] }),
        /* @__PURE__ */ (0, import_jsx_runtime16.jsx)("button", { disabled: busy, children: "Add board member" })
      ] }),
      data.memberships.filter((m) => m.board_id === b.id).map((m) => /* @__PURE__ */ (0, import_jsx_runtime16.jsxs)("p", { children: [
        members.find((u) => u.id === m.user_id)?.name || "Staff",
        " ",
        /* @__PURE__ */ (0, import_jsx_runtime16.jsx)("button", { disabled: busy, onClick: () => run("set_sales_board_member", { p_board: b.id, p_user: m.user_id, p_enabled: false }, "Board member removed."), children: "Remove board member" })
      ] }, m.id)),
      /* @__PURE__ */ (0, import_jsx_runtime16.jsx)("h3", { children: "Stages" }),
      data.stages.filter((s) => s.board_id === b.id).sort((a, c) => a.position - c.position).map((s) => /* @__PURE__ */ (0, import_jsx_runtime16.jsxs)("details", { children: [
        /* @__PURE__ */ (0, import_jsx_runtime16.jsxs)("summary", { children: [
          s.name,
          " \xB7 ",
          s.probability,
          "%"
        ] }),
        /* @__PURE__ */ (0, import_jsx_runtime16.jsxs)("form", { className: "p-form", onSubmit: (e) => {
          e.preventDefault();
          const d = new FormData(e.currentTarget);
          run("configure_sales_stage", { p_board: b.id, p_code: s.code, p_version: s.version, p_name: d.get("name"), p_position: Number(d.get("position")), p_probability: Number(d.get("probability")), p_active: d.get("active") === "on" }, "Stage saved.");
        }, children: [
          /* @__PURE__ */ (0, import_jsx_runtime16.jsx)(Input2, { name: "name", label: "Stage name", value: s.name, required: true }),
          /* @__PURE__ */ (0, import_jsx_runtime16.jsx)(Input2, { name: "position", label: "Stage order", type: "number", value: s.position, required: true }),
          /* @__PURE__ */ (0, import_jsx_runtime16.jsx)(Input2, { name: "probability", label: "Win probability percent", type: "number", value: s.probability, required: true }),
          /* @__PURE__ */ (0, import_jsx_runtime16.jsxs)("label", { className: "p-check", children: [
            /* @__PURE__ */ (0, import_jsx_runtime16.jsx)("input", { name: "active", type: "checkbox", defaultChecked: s.active }),
            "Active stage"
          ] }),
          /* @__PURE__ */ (0, import_jsx_runtime16.jsx)("button", { disabled: busy, children: "Save stage" })
        ] })
      ] }, s.id + ":" + s.version)),
      /* @__PURE__ */ (0, import_jsx_runtime16.jsxs)("details", { children: [
        /* @__PURE__ */ (0, import_jsx_runtime16.jsx)("summary", { children: "Add a stage" }),
        /* @__PURE__ */ (0, import_jsx_runtime16.jsxs)("form", { className: "p-form", onSubmit: (e) => {
          e.preventDefault();
          const d = new FormData(e.currentTarget);
          run("configure_sales_stage", { p_board: b.id, p_code: d.get("code"), p_version: null, p_name: d.get("name"), p_position: Number(d.get("position")), p_probability: Number(d.get("probability")), p_active: true }, "Stage added.");
        }, children: [
          /* @__PURE__ */ (0, import_jsx_runtime16.jsx)(Input2, { name: "code", label: "Shared stage code (lowercase, underscores)", required: true }),
          /* @__PURE__ */ (0, import_jsx_runtime16.jsx)(Input2, { name: "name", label: "Stage name", required: true }),
          /* @__PURE__ */ (0, import_jsx_runtime16.jsx)(Input2, { name: "position", label: "Order", type: "number", required: true }),
          /* @__PURE__ */ (0, import_jsx_runtime16.jsx)(Input2, { name: "probability", label: "Probability percent", type: "number", required: true }),
          /* @__PURE__ */ (0, import_jsx_runtime16.jsx)("button", { disabled: busy, children: "Create stage" })
        ] })
      ] })
    ] }, b.id)) }) : /* @__PURE__ */ (0, import_jsx_runtime16.jsxs)(import_jsx_runtime16.Fragment, { children: [
      /* @__PURE__ */ (0, import_jsx_runtime16.jsxs)("div", { className: "p-toolbar", children: [
        view !== "raw_leads" && /* @__PURE__ */ (0, import_jsx_runtime16.jsxs)("label", { className: "p-field", children: [
          "Product board",
          /* @__PURE__ */ (0, import_jsx_runtime16.jsxs)("select", { value: board, onChange: (e) => {
            setBoard(e.target.value);
            setStage("");
          }, children: [
            /* @__PURE__ */ (0, import_jsx_runtime16.jsx)("option", { value: "", children: "All available boards" }),
            opts(boards)
          ] })
        ] }),
        /* @__PURE__ */ (0, import_jsx_runtime16.jsxs)("label", { className: "p-field", children: [
          "View",
          /* @__PURE__ */ (0, import_jsx_runtime16.jsxs)("select", { value: mode, onChange: (e) => setMode(e.target.value), children: [
            /* @__PURE__ */ (0, import_jsx_runtime16.jsx)("option", { value: "list", children: "List" }),
            /* @__PURE__ */ (0, import_jsx_runtime16.jsx)("option", { value: "kanban", children: "Kanban" })
          ] })
        ] }),
        /* @__PURE__ */ (0, import_jsx_runtime16.jsxs)("label", { className: "p-field", children: [
          "Search",
          /* @__PURE__ */ (0, import_jsx_runtime16.jsx)("input", { value: search, onChange: (e) => setSearch(e.target.value) })
        ] }),
        /* @__PURE__ */ (0, import_jsx_runtime16.jsxs)("label", { className: "p-field", children: [
          "Stage",
          /* @__PURE__ */ (0, import_jsx_runtime16.jsxs)("select", { value: stage, onChange: (e) => setStage(e.target.value), children: [
            /* @__PURE__ */ (0, import_jsx_runtime16.jsx)("option", { value: "", children: "All stages" }),
            view === "raw_leads" ? ["New", "Contacted", "Ready to assign", "Junk/Spam", "Duplicate", "Assigned"].map((s) => /* @__PURE__ */ (0, import_jsx_runtime16.jsx)("option", { children: s }, s)) : [...new Map(data.stages.filter((s) => !board || s.board_id === board).map((s) => [s.code, s])).values()].map((s) => /* @__PURE__ */ (0, import_jsx_runtime16.jsx)("option", { value: s.code, children: s.name }, s.code))
          ] })
        ] }),
        /* @__PURE__ */ (0, import_jsx_runtime16.jsxs)("label", { className: "p-field", children: [
          "Owner",
          /* @__PURE__ */ (0, import_jsx_runtime16.jsxs)("select", { value: owner, onChange: (e) => setOwner(e.target.value), children: [
            /* @__PURE__ */ (0, import_jsx_runtime16.jsx)("option", { value: "", children: "All visible owners" }),
            opts(members)
          ] })
        ] }),
        /* @__PURE__ */ (0, import_jsx_runtime16.jsxs)("label", { className: "p-field", children: [
          "Source",
          /* @__PURE__ */ (0, import_jsx_runtime16.jsxs)("select", { value: source, onChange: (e) => setSource(e.target.value), children: [
            /* @__PURE__ */ (0, import_jsx_runtime16.jsx)("option", { value: "", children: "All sources" }),
            [...new Set(data.leads.map((l) => l.source))].map((s) => /* @__PURE__ */ (0, import_jsx_runtime16.jsx)("option", { children: s }, s))
          ] })
        ] }),
        view !== "raw_leads" && /* @__PURE__ */ (0, import_jsx_runtime16.jsxs)("label", { className: "p-field", children: [
          "Attention",
          /* @__PURE__ */ (0, import_jsx_runtime16.jsxs)("select", { value: attention, onChange: (e) => setAttention(e.target.value), children: [
            /* @__PURE__ */ (0, import_jsx_runtime16.jsx)("option", { value: "", children: "All records" }),
            /* @__PURE__ */ (0, import_jsx_runtime16.jsx)("option", { value: "no_step", children: "No next step" }),
            /* @__PURE__ */ (0, import_jsx_runtime16.jsx)("option", { value: "due", children: "Follow-ups due" }),
            /* @__PURE__ */ (0, import_jsx_runtime16.jsx)("option", { value: "rotting", children: "No recent activity" })
          ] })
        ] }),
        /* @__PURE__ */ (0, import_jsx_runtime16.jsx)("button", { onClick: () => downloadText("sales-" + view + ".csv", csvText(view === "raw_leads" ? [["Lead", "Email", "Phone", "Source", "Status"], ...leads.map((l) => [l.name, l.email, l.phone, l.source, l.status])] : [["Deal", "Stage", "Currency", "Value", "Follow-up"], ...deals.map((d) => [d.title, d.stage, d.currency, d.estimated_value, d.next_followup])])), children: "Export filtered sales CSV" })
      ] }),
      sales && /* @__PURE__ */ (0, import_jsx_runtime16.jsxs)("details", { children: [
        /* @__PURE__ */ (0, import_jsx_runtime16.jsx)("summary", { children: "Saved views" }),
        /* @__PURE__ */ (0, import_jsx_runtime16.jsxs)("form", { className: "p-form", onSubmit: (e) => {
          e.preventDefault();
          const d = new FormData(e.currentTarget);
          run("save_crm_sales_view", { p_name: d.get("name"), p_filters: { ...filters, view } }, "View saved.");
        }, children: [
          /* @__PURE__ */ (0, import_jsx_runtime16.jsx)(Input2, { name: "name", label: "Saved view name", required: true }),
          /* @__PURE__ */ (0, import_jsx_runtime16.jsx)("button", { disabled: busy, children: "Save current filters" })
        ] }),
        data.views.filter((v) => v.filters.view === view).map((v) => /* @__PURE__ */ (0, import_jsx_runtime16.jsx)("button", { onClick: () => apply(v.filters), children: v.name }, v.id))
      ] }),
      view === "raw_leads" && sales ? /* @__PURE__ */ (0, import_jsx_runtime16.jsxs)(import_jsx_runtime16.Fragment, { children: [
        /* @__PURE__ */ (0, import_jsx_runtime16.jsx)("button", { onClick: () => setAdding(!adding), children: adding ? "Close lead form" : "Add lead" }),
        adding && /* @__PURE__ */ (0, import_jsx_runtime16.jsxs)("form", { className: "p-form p-panel", onSubmit: async (e) => {
          e.preventDefault();
          const f = e.currentTarget, d = new FormData(f);
          const r = await run("capture_crm_lead", { p_name: d.get("name"), p_email: d.get("email"), p_phone: d.get("phone"), p_company: d.get("company"), p_city: d.get("city"), p_country: d.get("country"), p_message: d.get("message"), p_source: "Manual", p_campaign: d.get("campaign"), p_tags: String(d.get("tags") || "").split(",").map((x) => x.trim()).filter(Boolean) }, "Enquiry recorded. Existing contacts are deduplicated and retain their owner.");
          if (r.ok) f.reset();
        }, children: [
          /* @__PURE__ */ (0, import_jsx_runtime16.jsx)(Input2, { name: "name", label: "Full name", required: true }),
          /* @__PURE__ */ (0, import_jsx_runtime16.jsx)(Input2, { name: "email", label: "Email", type: "email" }),
          /* @__PURE__ */ (0, import_jsx_runtime16.jsx)(Input2, { name: "phone", label: "International phone (+country code)" }),
          /* @__PURE__ */ (0, import_jsx_runtime16.jsx)(Input2, { name: "company", label: "Company" }),
          /* @__PURE__ */ (0, import_jsx_runtime16.jsx)(Input2, { name: "city", label: "City" }),
          /* @__PURE__ */ (0, import_jsx_runtime16.jsx)(Input2, { name: "country", label: "Country" }),
          /* @__PURE__ */ (0, import_jsx_runtime16.jsx)(Input2, { name: "message", label: "Original enquiry", type: "textarea" }),
          /* @__PURE__ */ (0, import_jsx_runtime16.jsx)(Input2, { name: "campaign", label: "Campaign" }),
          /* @__PURE__ */ (0, import_jsx_runtime16.jsx)(Input2, { name: "tags", label: "Tags separated by commas" }),
          /* @__PURE__ */ (0, import_jsx_runtime16.jsx)("button", { disabled: busy, children: "Record enquiry" })
        ] }),
        /* @__PURE__ */ (0, import_jsx_runtime16.jsxs)("details", { children: [
          /* @__PURE__ */ (0, import_jsx_runtime16.jsx)("summary", { children: "Import leads from CSV / Excel" }),
          /* @__PURE__ */ (0, import_jsx_runtime16.jsx)("p", { children: "Map columns before import. Maximum 500 rows and 5 MB; use international phone numbers. All rows save together or none do." }),
          /* @__PURE__ */ (0, import_jsx_runtime16.jsx)("button", { onClick: () => downloadText("lead-import-template.csv", csvText([fields, ["Example Customer", "customer@example.test", "+923001234567", "Example Company", "Lahore", "Pakistan", "Networking enquiry", "Referral"]])), children: "Download lead import template" }),
          /* @__PURE__ */ (0, import_jsx_runtime16.jsxs)("label", { className: "p-field", children: [
            "Choose CSV or XLSX",
            /* @__PURE__ */ (0, import_jsx_runtime16.jsx)("input", { type: "file", accept: ".csv,.xlsx", disabled: busy, onChange: async (e) => {
              setUpload([]);
              setError("");
              const f = e.target.files?.[0];
              if (!f) return;
              try {
                if (f.size > 5 * 1024 * 1024) throw new Error("Choose a file of 5 MB or less");
                const rows = /\.xlsx$/i.test(f.name) ? await readXLSX(await f.arrayBuffer()) : parseCSV(await f.text());
                if (rows.length < 2 || rows.length > 501) throw new Error("Use 1\u2013500 rows plus headers");
                setUpload(rows);
                setMapping(Object.fromEntries(fields.map((k) => [k, String(rows[0].findIndex((h) => h.trim().toLowerCase() === k))])));
                setBatch(crypto.randomUUID());
              } catch (e2) {
                setError(e2.message);
              }
            } })
          ] }),
          upload.length > 0 && /* @__PURE__ */ (0, import_jsx_runtime16.jsxs)(import_jsx_runtime16.Fragment, { children: [
            /* @__PURE__ */ (0, import_jsx_runtime16.jsxs)("p", { children: [
              upload.length - 1,
              " enquiries in preview"
            ] }),
            fields.map((k) => /* @__PURE__ */ (0, import_jsx_runtime16.jsxs)("label", { className: "p-field", children: [
              k,
              /* @__PURE__ */ (0, import_jsx_runtime16.jsxs)("select", { value: mapping[k] || "-1", onChange: (e) => setMapping({ ...mapping, [k]: e.target.value }), children: [
                /* @__PURE__ */ (0, import_jsx_runtime16.jsx)("option", { value: "-1", children: "Not mapped" }),
                upload[0].map((h, i) => /* @__PURE__ */ (0, import_jsx_runtime16.jsx)("option", { value: i, children: h }, i))
              ] })
            ] }, k)),
            /* @__PURE__ */ (0, import_jsx_runtime16.jsx)("div", { className: "p-table-scroll", children: /* @__PURE__ */ (0, import_jsx_runtime16.jsxs)("table", { className: "p-table", children: [
              /* @__PURE__ */ (0, import_jsx_runtime16.jsx)("thead", { children: /* @__PURE__ */ (0, import_jsx_runtime16.jsx)("tr", { children: fields.map((k) => /* @__PURE__ */ (0, import_jsx_runtime16.jsx)("th", { children: k }, k)) }) }),
              /* @__PURE__ */ (0, import_jsx_runtime16.jsx)("tbody", { children: upload.slice(1, 6).map((r, i) => /* @__PURE__ */ (0, import_jsx_runtime16.jsx)("tr", { children: fields.map((k) => /* @__PURE__ */ (0, import_jsx_runtime16.jsx)("td", { children: r[Number(mapping[k])] || "" }, k)) }, i)) })
            ] }) }),
            /* @__PURE__ */ (0, import_jsx_runtime16.jsx)("button", { disabled: busy || Number(mapping.name) < 0 || Number(mapping.email) < 0 && Number(mapping.phone) < 0, onClick: async () => {
              const rows = upload.slice(1).map((r) => Object.fromEntries(fields.map((k) => [k, r[Number(mapping[k])] || ""])));
              const result = await run("import_crm_leads", { p_batch: batch, p_rows: rows }, "Enquiries imported with duplicate handling.");
              if (result.ok) setUpload([]);
            }, children: "Import mapped enquiries" })
          ] })
        ] }),
        mode === "kanban" ? /* @__PURE__ */ (0, import_jsx_runtime16.jsx)("div", { className: "sales-kanban", children: ["New", "Contacted", "Ready to assign", "Junk/Spam", "Duplicate"].map((status) => /* @__PURE__ */ (0, import_jsx_runtime16.jsxs)("section", { className: "p-panel", children: [
          /* @__PURE__ */ (0, import_jsx_runtime16.jsxs)("h2", { children: [
            status,
            " \xB7 ",
            leads.filter((l) => l.status === status).length
          ] }),
          leads.filter((l) => l.status === status).map((l) => /* @__PURE__ */ (0, import_jsx_runtime16.jsxs)("button", { className: "sales-card", onClick: () => setLeadId(l.id), children: [
            l.name,
            " \xB7 ",
            l.company_name,
            " \xB7 ",
            l.source
          ] }, l.id))
        ] }, status)) }) : /* @__PURE__ */ (0, import_jsx_runtime16.jsx)("div", { className: "p-table-scroll", children: /* @__PURE__ */ (0, import_jsx_runtime16.jsxs)("table", { className: "p-table", children: [
          /* @__PURE__ */ (0, import_jsx_runtime16.jsx)("thead", { children: /* @__PURE__ */ (0, import_jsx_runtime16.jsxs)("tr", { children: [
            /* @__PURE__ */ (0, import_jsx_runtime16.jsx)("th", { children: "Select" }),
            /* @__PURE__ */ (0, import_jsx_runtime16.jsx)("th", { children: "Lead" }),
            /* @__PURE__ */ (0, import_jsx_runtime16.jsx)("th", { children: "Contact" }),
            /* @__PURE__ */ (0, import_jsx_runtime16.jsx)("th", { children: "Source" }),
            /* @__PURE__ */ (0, import_jsx_runtime16.jsx)("th", { children: "Status" })
          ] }) }),
          /* @__PURE__ */ (0, import_jsx_runtime16.jsx)("tbody", { children: leads.map((l) => /* @__PURE__ */ (0, import_jsx_runtime16.jsxs)("tr", { children: [
            /* @__PURE__ */ (0, import_jsx_runtime16.jsx)("td", { children: /* @__PURE__ */ (0, import_jsx_runtime16.jsx)("input", { type: "checkbox", "aria-label": "Select " + l.name, checked: selected.includes(l.id), disabled: l.status === "Assigned", onChange: (e) => setSelected(e.target.checked ? [...selected, l.id] : selected.filter((id) => id !== l.id)) }) }),
            /* @__PURE__ */ (0, import_jsx_runtime16.jsxs)("td", { children: [
              /* @__PURE__ */ (0, import_jsx_runtime16.jsx)("button", { onClick: () => setLeadId(l.id), children: l.name }),
              /* @__PURE__ */ (0, import_jsx_runtime16.jsx)("p", { children: l.company_name })
            ] }),
            /* @__PURE__ */ (0, import_jsx_runtime16.jsxs)("td", { children: [
              l.email,
              /* @__PURE__ */ (0, import_jsx_runtime16.jsx)("br", {}),
              l.phone
            ] }),
            /* @__PURE__ */ (0, import_jsx_runtime16.jsxs)("td", { children: [
              l.source,
              " \xB7 ",
              l.campaign
            ] }),
            /* @__PURE__ */ (0, import_jsx_runtime16.jsx)("td", { children: l.status })
          ] }, l.id)) })
        ] }) }),
        !leads.length && loaded && /* @__PURE__ */ (0, import_jsx_runtime16.jsx)("p", { children: "No leads match these filters." }),
        selected.length > 0 && /* @__PURE__ */ (0, import_jsx_runtime16.jsxs)("section", { className: "p-panel", children: [
          /* @__PURE__ */ (0, import_jsx_runtime16.jsxs)("h2", { children: [
            "Assign products to ",
            selected.length,
            " selected leads"
          ] }),
          /* @__PURE__ */ (0, import_jsx_runtime16.jsx)("button", { onClick: () => setSelected([]), children: "Clear selection" }),
          assignment(data.leads.filter((l) => selected.includes(l.id)))
        ] }),
        lead && /* @__PURE__ */ (0, import_jsx_runtime16.jsxs)("section", { className: "p-panel", children: [
          /* @__PURE__ */ (0, import_jsx_runtime16.jsx)("h2", { children: lead.name }),
          /* @__PURE__ */ (0, import_jsx_runtime16.jsxs)("p", { children: [
            lead.email,
            " \xB7 ",
            lead.phone,
            " \xB7 ",
            lead.source
          ] }),
          /* @__PURE__ */ (0, import_jsx_runtime16.jsx)("p", { className: "p-pre", children: lead.message }),
          lead.status !== "Assigned" && /* @__PURE__ */ (0, import_jsx_runtime16.jsxs)(import_jsx_runtime16.Fragment, { children: [
            /* @__PURE__ */ (0, import_jsx_runtime16.jsxs)("form", { className: "p-form", onSubmit: (e) => {
              e.preventDefault();
              const d = new FormData(e.currentTarget);
              run("triage_crm_lead", { p_id: lead.id, p_version: lead.version, p_status: d.get("status"), p_owner: d.get("owner") }, "Lead triage saved.");
            }, children: [
              /* @__PURE__ */ (0, import_jsx_runtime16.jsxs)("label", { className: "p-field", children: [
                "Triage status",
                /* @__PURE__ */ (0, import_jsx_runtime16.jsx)("select", { name: "status", defaultValue: lead.status, children: ["New", "Contacted", "Ready to assign", "Junk/Spam", "Duplicate"].map((s) => /* @__PURE__ */ (0, import_jsx_runtime16.jsx)("option", { children: s }, s)) })
              ] }),
              /* @__PURE__ */ (0, import_jsx_runtime16.jsxs)("label", { className: "p-field", children: [
                "Owner",
                /* @__PURE__ */ (0, import_jsx_runtime16.jsx)("select", { name: "owner", defaultValue: lead.owner_id, children: opts(allowedOwners) })
              ] }),
              /* @__PURE__ */ (0, import_jsx_runtime16.jsx)("button", { disabled: busy, children: "Save triage" })
            ] }, lead.id + ":" + lead.version),
            assignment([lead])
          ] }),
          /* @__PURE__ */ (0, import_jsx_runtime16.jsx)(ActivityForm, { lead: lead.id, run, busy }),
          /* @__PURE__ */ (0, import_jsx_runtime16.jsx)(ActivityRows, { rows: data.activity.filter((a) => a.lead_id === lead.id) }),
          /* @__PURE__ */ (0, import_jsx_runtime16.jsx)("button", { onClick: () => setLeadId(""), children: "Close lead" })
        ] })
      ] }) : /* @__PURE__ */ (0, import_jsx_runtime16.jsxs)(import_jsx_runtime16.Fragment, { children: [
        /* @__PURE__ */ (0, import_jsx_runtime16.jsxs)("p", { children: [
          deals.length,
          " visible deals \xB7 ",
          deals.reduce((n, d) => n + Number(d.estimated_value), 0).toLocaleString(),
          " PKR estimated pipeline"
        ] }),
        mode === "kanban" && board ? /* @__PURE__ */ (0, import_jsx_runtime16.jsx)("div", { className: "sales-kanban", children: stages.map((s) => /* @__PURE__ */ (0, import_jsx_runtime16.jsxs)("section", { className: "p-panel", onDragOver: (e) => e.preventDefault(), onDrop: (e) => {
          e.preventDefault();
          const id = e.dataTransfer.getData("text/plain"), d = deals.find((x) => x.id === id);
          if (d) run("save_crm_deal", { p_id: d.id, p_version: d.version, p_stage: s.code, p_value: Number(d.estimated_value), p_followup: d.next_followup, p_meeting: d.meeting_at, p_loss_reason: d.loss_reason, p_loss_note: d.loss_note, p_reengage: d.reengage_on }, "Deal stage saved.");
        }, children: [
          /* @__PURE__ */ (0, import_jsx_runtime16.jsxs)("h2", { children: [
            s.name,
            " \xB7 ",
            deals.filter((d) => d.stage === s.code).length
          ] }),
          /* @__PURE__ */ (0, import_jsx_runtime16.jsxs)("p", { children: [
            deals.filter((d) => d.stage === s.code).reduce((n, d) => n + Number(d.estimated_value), 0).toLocaleString(),
            " ",
            deals[0]?.currency || "PKR"
          ] }),
          deals.filter((d) => d.stage === s.code).map(dealCard)
        ] }, s.id)) }) : mode === "kanban" ? /* @__PURE__ */ (0, import_jsx_runtime16.jsx)("p", { children: "Choose a product board to see its configured Kanban columns." }) : /* @__PURE__ */ (0, import_jsx_runtime16.jsx)("div", { className: "p-table-scroll", children: /* @__PURE__ */ (0, import_jsx_runtime16.jsxs)("table", { className: "p-table", children: [
          /* @__PURE__ */ (0, import_jsx_runtime16.jsx)("thead", { children: /* @__PURE__ */ (0, import_jsx_runtime16.jsxs)("tr", { children: [
            /* @__PURE__ */ (0, import_jsx_runtime16.jsx)("th", { children: "Deal" }),
            /* @__PURE__ */ (0, import_jsx_runtime16.jsx)("th", { children: "Products" }),
            /* @__PURE__ */ (0, import_jsx_runtime16.jsx)("th", { children: "Stage" }),
            /* @__PURE__ */ (0, import_jsx_runtime16.jsx)("th", { children: "Estimated value" }),
            /* @__PURE__ */ (0, import_jsx_runtime16.jsx)("th", { children: "Next follow-up" })
          ] }) }),
          /* @__PURE__ */ (0, import_jsx_runtime16.jsx)("tbody", { children: deals.map((d) => /* @__PURE__ */ (0, import_jsx_runtime16.jsxs)("tr", { children: [
            /* @__PURE__ */ (0, import_jsx_runtime16.jsx)("td", { children: /* @__PURE__ */ (0, import_jsx_runtime16.jsx)("button", { onClick: () => setDealId(d.id), children: d.title }) }),
            /* @__PURE__ */ (0, import_jsx_runtime16.jsx)("td", { children: lines.filter((l) => l.deal_id === d.id).map((l) => boards.find((b) => b.id === l.board_id)?.name || "Other product").join(", ") }),
            /* @__PURE__ */ (0, import_jsx_runtime16.jsx)("td", { children: data.stages.find((s) => s.code === d.stage && (!board || s.board_id === board))?.name || d.stage }),
            /* @__PURE__ */ (0, import_jsx_runtime16.jsxs)("td", { children: [
              d.currency,
              " ",
              Number(d.estimated_value).toLocaleString()
            ] }),
            /* @__PURE__ */ (0, import_jsx_runtime16.jsx)("td", { children: d.next_followup || "No next step" })
          ] }, d.id)) })
        ] }) }),
        data.tasks.filter((t) => t.status === "Open").length > 0 && /* @__PURE__ */ (0, import_jsx_runtime16.jsxs)("section", { className: "p-panel", children: [
          /* @__PURE__ */ (0, import_jsx_runtime16.jsx)("h2", { children: "Sales follow-up tasks" }),
          data.tasks.filter((t) => t.status === "Open").map((t) => /* @__PURE__ */ (0, import_jsx_runtime16.jsxs)("div", { className: "p-list-row", children: [
            /* @__PURE__ */ (0, import_jsx_runtime16.jsxs)("button", { onClick: () => setDealId(t.deal_id), children: [
              t.title,
              " \xB7 ",
              t.due_on
            ] }),
            sales && /* @__PURE__ */ (0, import_jsx_runtime16.jsxs)("form", { className: "p-form", onSubmit: (e) => {
              e.preventDefault();
              const d = new FormData(e.currentTarget);
              run("complete_crm_sales_task", { p_id: t.id, p_version: t.version, p_note: d.get("note") }, "Follow-up task completed.");
            }, children: [
              /* @__PURE__ */ (0, import_jsx_runtime16.jsx)(Input2, { name: "note", label: "Re-engagement outcome", required: true }),
              /* @__PURE__ */ (0, import_jsx_runtime16.jsx)("button", { disabled: busy, children: "Complete follow-up task" })
            ] })
          ] }, t.id))
        ] }),
        deal && /* @__PURE__ */ (0, import_jsx_runtime16.jsxs)("section", { className: "p-panel", children: [
          /* @__PURE__ */ (0, import_jsx_runtime16.jsx)("h2", { children: deal.title }),
          /* @__PURE__ */ (0, import_jsx_runtime16.jsxs)("p", { children: [
            contact?.email,
            " \xB7 ",
            contact?.phone
          ] }),
          /* @__PURE__ */ (0, import_jsx_runtime16.jsxs)("p", { children: [
            "Shared stage: ",
            deal.stage,
            ". Every product board displays this same deal."
          ] }),
          /* @__PURE__ */ (0, import_jsx_runtime16.jsx)("p", { className: "p-muted", children: "Publish a current quotation before proposal or negotiation. Use the conversion form below to create a Won sale from the accepted quotation." }),
          sales && (admin || permissions.includes("sales.manage") || deal.owner_id === profile.id) && /* @__PURE__ */ (0, import_jsx_runtime16.jsxs)("form", { className: "p-form", onSubmit: (e) => {
            e.preventDefault();
            const d = new FormData(e.currentTarget);
            run("save_crm_deal", { p_id: deal.id, p_version: deal.version, p_stage: d.get("stage"), p_value: Number(d.get("value")), p_followup: d.get("followup") || null, p_meeting: d.get("meeting") ? new Date(String(d.get("meeting"))).toISOString() : null, p_loss_reason: d.get("reason") || "", p_loss_note: d.get("loss_note") || "", p_reengage: d.get("reengage") || null }, "Deal saved.");
          }, children: [
            /* @__PURE__ */ (0, import_jsx_runtime16.jsxs)("label", { className: "p-field", children: [
              "Deal stage",
              /* @__PURE__ */ (0, import_jsx_runtime16.jsx)("select", { name: "stage", defaultValue: deal.stage, children: [...new Map(data.stages.filter((s) => s.active && lines.filter((l) => l.deal_id === deal.id && l.status === "Active").every((l) => data.stages.some((x) => x.board_id === l.board_id && x.code === s.code && x.active))).map((s) => [s.code, s])).values()].map((s) => /* @__PURE__ */ (0, import_jsx_runtime16.jsx)("option", { value: s.code, disabled: s.code === "won", children: s.name }, s.code)) })
            ] }),
            /* @__PURE__ */ (0, import_jsx_runtime16.jsx)(Input2, { name: "value", label: "Estimated value PKR", type: "number", value: deal.estimated_value, required: true }),
            /* @__PURE__ */ (0, import_jsx_runtime16.jsx)(Input2, { name: "followup", label: "Next follow-up UTC", type: "date", value: deal.next_followup || "" }),
            /* @__PURE__ */ (0, import_jsx_runtime16.jsx)(Input2, { name: "meeting", label: "Meeting date and time (local)", type: "datetime-local", value: deal.meeting_at ? new Date(Date.parse(deal.meeting_at) - new Date(deal.meeting_at).getTimezoneOffset() * 6e4).toISOString().slice(0, 16) : "" }),
            /* @__PURE__ */ (0, import_jsx_runtime16.jsxs)("label", { className: "p-field", children: [
              "Lost reason",
              /* @__PURE__ */ (0, import_jsx_runtime16.jsxs)("select", { name: "reason", defaultValue: deal.loss_reason, children: [
                /* @__PURE__ */ (0, import_jsx_runtime16.jsx)("option", { value: "", children: "Choose if Lost\u2026" }),
                (data.settings.find((s) => s.id === "lost_reasons")?.value || []).map((r) => /* @__PURE__ */ (0, import_jsx_runtime16.jsx)("option", { children: r }, r))
              ] })
            ] }),
            /* @__PURE__ */ (0, import_jsx_runtime16.jsx)(Input2, { name: "loss_note", label: "Lost explanation", type: "textarea", value: deal.loss_note }),
            /* @__PURE__ */ (0, import_jsx_runtime16.jsx)(Input2, { name: "reengage", label: "Re-engage on UTC", type: "date", value: deal.reengage_on || "" }),
            /* @__PURE__ */ (0, import_jsx_runtime16.jsx)("button", { disabled: busy, children: "Save deal" })
          ] }, deal.id + ":" + deal.version),
          lines.filter((l) => l.deal_id === deal.id).map((l) => /* @__PURE__ */ (0, import_jsx_runtime16.jsx)(ProductLine, { line: l, board: boards.find((b) => b.id === l.board_id), editable: admin || sales && deal.owner_id === profile.id || permissions.includes("sales.manage") || specialist && data.memberships.some((m) => m.board_id === l.board_id && m.user_id === profile.id), owners: allowedOwners, run, busy }, l.id + ":" + l.version)),
          sales && (admin || permissions.includes("sales.manage") || deal.owner_id === profile.id) && /* @__PURE__ */ (0, import_jsx_runtime16.jsx)(ActivityForm, { lead: deal.lead_id, deal: deal.id, run, busy }),
          /* @__PURE__ */ (0, import_jsx_runtime16.jsx)(ActivityRows, { rows: data.activity.filter((a) => a.deal_id === deal.id || a.deal_id === null && a.lead_id === deal.lead_id) }),
          /* @__PURE__ */ (0, import_jsx_runtime16.jsx)(CrmQuotes, { profile, deal, products: lines.filter((l) => l.deal_id === deal.id), boards, editableBoardIds: data.memberships.filter((m) => m.user_id === profile.id).map((m) => m.board_id), companies, onChanged: () => load().catch((e) => setError(e.message)) }, deal.id),
          /* @__PURE__ */ (0, import_jsx_runtime16.jsx)(WonConversion, { profile, deal, products: lines.filter((l) => l.deal_id === deal.id), boards, onChanged: () => load().catch((e) => setError(e.message)) }, deal.id + ":conversion"),
          /* @__PURE__ */ (0, import_jsx_runtime16.jsx)("button", { onClick: () => setDealId(""), children: "Close deal" })
        ] })
      ] })
    ] })
  ] });
}
function ProductLine({ line: l, board, editable, owners, run, busy }) {
  return /* @__PURE__ */ (0, import_jsx_runtime16.jsxs)("details", { children: [
    /* @__PURE__ */ (0, import_jsx_runtime16.jsxs)("summary", { children: [
      board?.name || "Other product",
      " \xB7 ",
      l.status,
      " \xB7 Survey ",
      l.survey_done ? "\u2713" : "\u2014",
      " \xB7 Design ",
      l.design_done ? "\u2713" : "\u2014",
      " \xB7 BOQ ",
      l.boq_ready ? "\u2713" : "\u2014"
    ] }),
    editable ? /* @__PURE__ */ (0, import_jsx_runtime16.jsxs)("form", { className: "p-form", onSubmit: (e) => {
      e.preventDefault();
      const d = new FormData(e.currentTarget);
      run("save_crm_product_line", { p_id: l.id, p_version: l.version, p_owner: d.get("owner") || null, p_value: Number(d.get("value")), p_survey: d.get("survey") === "on", p_design: d.get("design") === "on", p_boq: d.get("boq") === "on", p_status: d.get("status"), p_reason: d.get("reason") || "" }, "Product section saved.");
    }, children: [
      /* @__PURE__ */ (0, import_jsx_runtime16.jsxs)("label", { className: "p-field", children: [
        "Product owner",
        /* @__PURE__ */ (0, import_jsx_runtime16.jsxs)("select", { name: "owner", defaultValue: l.owner_id || "", children: [
          /* @__PURE__ */ (0, import_jsx_runtime16.jsx)("option", { value: "", children: "Unassigned" }),
          !owners.some((u) => u.id === l.owner_id) && l.owner_id && /* @__PURE__ */ (0, import_jsx_runtime16.jsx)("option", { value: l.owner_id, children: "Current owner" }),
          opts(owners)
        ] })
      ] }),
      /* @__PURE__ */ (0, import_jsx_runtime16.jsx)(Input2, { name: "value", label: "Product estimated value PKR", type: "number", value: l.estimated_value, required: true }),
      ["survey", "design", "boq"].map((k) => /* @__PURE__ */ (0, import_jsx_runtime16.jsxs)("label", { className: "p-check", children: [
        /* @__PURE__ */ (0, import_jsx_runtime16.jsx)("input", { name: k, type: "checkbox", defaultChecked: l[k === "boq" ? "boq_ready" : k + "_done"] }),
        k === "boq" ? "BOQ ready" : k + " done"
      ] }, k)),
      /* @__PURE__ */ (0, import_jsx_runtime16.jsxs)("label", { className: "p-field", children: [
        "Product status",
        /* @__PURE__ */ (0, import_jsx_runtime16.jsxs)("select", { name: "status", defaultValue: l.status, children: [
          /* @__PURE__ */ (0, import_jsx_runtime16.jsx)("option", { children: "Active" }),
          /* @__PURE__ */ (0, import_jsx_runtime16.jsx)("option", { children: "Dropped" })
        ] })
      ] }),
      /* @__PURE__ */ (0, import_jsx_runtime16.jsx)(Input2, { name: "reason", label: "Dropped product reason", value: l.drop_reason }),
      /* @__PURE__ */ (0, import_jsx_runtime16.jsx)("button", { disabled: busy, children: "Save product section" })
    ] }) : /* @__PURE__ */ (0, import_jsx_runtime16.jsx)("p", { children: "Read-only product section." })
  ] });
}
function ActivityForm({ lead, deal = null, run, busy }) {
  return /* @__PURE__ */ (0, import_jsx_runtime16.jsxs)("form", { className: "p-form", onSubmit: async (e) => {
    e.preventDefault();
    const f = e.currentTarget, d = new FormData(f);
    const r = await run("log_crm_activity", { p_lead: lead, p_deal: deal, p_kind: d.get("kind"), p_body: d.get("body"), p_followup: d.get("followup") || null }, "Activity recorded.");
    if (r.ok) f.reset();
  }, children: [
    /* @__PURE__ */ (0, import_jsx_runtime16.jsx)("h3", { children: "Record activity" }),
    /* @__PURE__ */ (0, import_jsx_runtime16.jsxs)("label", { className: "p-field", children: [
      "Activity type",
      /* @__PURE__ */ (0, import_jsx_runtime16.jsxs)("select", { name: "kind", children: [
        /* @__PURE__ */ (0, import_jsx_runtime16.jsx)("option", { children: "Call" }),
        /* @__PURE__ */ (0, import_jsx_runtime16.jsx)("option", { children: "Meeting" }),
        /* @__PURE__ */ (0, import_jsx_runtime16.jsx)("option", { children: "Note" }),
        /* @__PURE__ */ (0, import_jsx_runtime16.jsx)("option", { children: "Follow-up" })
      ] })
    ] }),
    /* @__PURE__ */ (0, import_jsx_runtime16.jsx)(Input2, { name: "body", label: "Activity notes", type: "textarea", required: true }),
    deal && /* @__PURE__ */ (0, import_jsx_runtime16.jsx)(Input2, { name: "followup", label: "Next follow-up UTC", type: "date" }),
    /* @__PURE__ */ (0, import_jsx_runtime16.jsx)("button", { disabled: busy, children: "Log sales activity" })
  ] });
}
function ActivityRows({ rows }) {
  return /* @__PURE__ */ (0, import_jsx_runtime16.jsxs)(import_jsx_runtime16.Fragment, { children: [
    /* @__PURE__ */ (0, import_jsx_runtime16.jsx)("h3", { children: "Activity timeline" }),
    rows.slice().sort((a, b) => b.created_at.localeCompare(a.created_at)).map((a) => /* @__PURE__ */ (0, import_jsx_runtime16.jsx)("div", { className: "p-list-row", children: /* @__PURE__ */ (0, import_jsx_runtime16.jsxs)("div", { children: [
      /* @__PURE__ */ (0, import_jsx_runtime16.jsx)("strong", { children: a.kind }),
      /* @__PURE__ */ (0, import_jsx_runtime16.jsx)("p", { className: "p-pre", children: a.body }),
      /* @__PURE__ */ (0, import_jsx_runtime16.jsx)("small", { children: new Date(a.created_at).toLocaleString() })
    ] }) }, a.id))
  ] });
}
// Annotate the CommonJS export names for ESM import in node:
0 && (module.exports = {
  CrmSales
});
/*! Bundled license information:

react/cjs/react-jsx-runtime.production.js:
  (**
   * @license React
   * react-jsx-runtime.production.js
   *
   * Copyright (c) Meta Platforms, Inc. and affiliates.
   *
   * This source code is licensed under the MIT license found in the
   * LICENSE file in the root directory of this source tree.
   *)

react/cjs/react-jsx-runtime.development.js:
  (**
   * @license React
   * react-jsx-runtime.development.js
   *
   * Copyright (c) Meta Platforms, Inc. and affiliates.
   *
   * This source code is licensed under the MIT license found in the
   * LICENSE file in the root directory of this source tree.
   *)

html2canvas/dist/html2canvas.js:
  (*!
   * html2canvas 1.4.1 <https://html2canvas.hertzen.com>
   * Copyright (c) 2022 Niklas von Hertzen <https://hertzen.com>
   * Released under MIT License
   *)
  (*! *****************************************************************************
      Copyright (c) Microsoft Corporation.
  
      Permission to use, copy, modify, and/or distribute this software for any
      purpose with or without fee is hereby granted.
  
      THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES WITH
      REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY
      AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY SPECIAL, DIRECT,
      INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM
      LOSS OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR
      OTHER TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR
      PERFORMANCE OF THIS SOFTWARE.
      ***************************************************************************** *)

dompurify/dist/purify.cjs.js:
  (*! @license DOMPurify 3.4.16 | (c) Cure53 and other contributors | Released under the Apache license 2.0 and Mozilla Public License 2.0 | github.com/cure53/DOMPurify/blob/3.4.16/LICENSE *)
  (*! regenerator-runtime -- Copyright (c) 2014-present, Facebook, Inc. -- license (MIT): https://github.com/babel/babel/blob/main/packages/babel-helpers/LICENSE *)

@babel/runtime/helpers/regenerator.js:
  (*! regenerator-runtime -- Copyright (c) 2014-present, Facebook, Inc. -- license (MIT): https://github.com/babel/babel/blob/main/packages/babel-helpers/LICENSE *)

svg-pathdata/lib/SVGPathData.cjs:
  (*! *****************************************************************************
      Copyright (c) Microsoft Corporation.
  
      Permission to use, copy, modify, and/or distribute this software for any
      purpose with or without fee is hereby granted.
  
      THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES WITH
      REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY
      AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY SPECIAL, DIRECT,
      INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM
      LOSS OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR
      OTHER TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR
      PERFORMANCE OF THIS SOFTWARE.
      ***************************************************************************** *)

jspdf/dist/jspdf.node.min.js:
  (** @license
   *
   * jsPDF - PDF Document creation from JavaScript
   * Version 4.2.1 Built on 2026-03-17T11:11:27.057Z
   *                      CommitID 00000000
   *
   * Copyright (c) 2010-2025 James Hall <james@parall.ax>, https://github.com/MrRio/jsPDF
   *               2015-2025 yWorks GmbH, http://www.yworks.com
   *               2015-2025 Lukas Holländer <lukas.hollaender@yworks.com>, https://github.com/HackbrettXXX
   *               2016-2018 Aras Abbasi <aras.abbasi@gmail.com>
   *               2010 Aaron Spike, https://github.com/acspike
   *               2012 Willow Systems Corporation, https://github.com/willowsystems
   *               2012 Pablo Hess, https://github.com/pablohess
   *               2012 Florian Jenett, https://github.com/fjenett
   *               2013 Warren Weckesser, https://github.com/warrenweckesser
   *               2013 Youssef Beddad, https://github.com/lifof
   *               2013 Lee Driscoll, https://github.com/lsdriscoll
   *               2013 Stefan Slonevskiy, https://github.com/stefslon
   *               2013 Jeremy Morel, https://github.com/jmorel
   *               2013 Christoph Hartmann, https://github.com/chris-rock
   *               2014 Juan Pablo Gaviria, https://github.com/juanpgaviria
   *               2014 James Makes, https://github.com/dollaruw
   *               2014 Diego Casorran, https://github.com/diegocr
   *               2014 Steven Spungin, https://github.com/Flamenco
   *               2014 Kenneth Glassey, https://github.com/Gavvers
   *
   * Permission is hereby granted, free of charge, to any person obtaining
   * a copy of this software and associated documentation files (the
   * "Software"), to deal in the Software without restriction, including
   * without limitation the rights to use, copy, modify, merge, publish,
   * distribute, sublicense, and/or sell copies of the Software, and to
   * permit persons to whom the Software is furnished to do so, subject to
   * the following conditions:
   *
   * The above copyright notice and this permission notice shall be
   * included in all copies or substantial portions of the Software.
   *
   * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
   * EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
   * MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
   * NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
   * LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
   * OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
   * WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
   *
   * Contributor(s):
   *    siefkenj, ahwolf, rickygu, Midnith, saintclair, eaparango,
   *    kim3er, mfo, alnorth, Flamenco
   *)
  (**
   * A class to parse color values
   * @author Stoyan Stefanov <sstoo@gmail.com>
   * {@link   http://www.phpied.com/rgb-color-parser-in-javascript/}
   * @license Use it if you like it
   *)
  (**
   * @license
   * Joseph Myers does not specify a particular license for his work.
   *
   * Author: Joseph Myers
   * Accessed from: http://www.myersdaily.org/joseph/javascript/md5.js
   *
   * Modified by: Owen Leong
   *)
  (**
   * @license
   * FPDF is released under a permissive license: there is no usage restriction.
   * You may embed it freely in your application (commercial or not), with or
   * without modifications.
   *
   * Reference: http://www.fpdf.org/en/script/script37.php
   *)
  (**
   * @license
   * Licensed under the MIT License.
   * http://opensource.org/licenses/mit-license
   * Author: Owen Leong (@owenl131)
   * Date: 15 Oct 2020
   * References:
   * https://www.cs.cmu.edu/~dst/Adobe/Gallery/anon21jul01-pdf-encryption.txt
   * https://github.com/foliojs/pdfkit/blob/master/lib/security.js
   * http://www.fpdf.org/en/script/script37.php
   *)
  (** @license
   * jsPDF addImage plugin
   * Copyright (c) 2012 Jason Siefken, https://github.com/siefkenj/
   *               2013 Chris Dowling, https://github.com/gingerchris
   *               2013 Trinh Ho, https://github.com/ineedfat
   *               2013 Edwin Alejandro Perez, https://github.com/eaparango
   *               2013 Norah Smith, https://github.com/burnburnrocket
   *               2014 Diego Casorran, https://github.com/diegocr
   *               2014 James Robb, https://github.com/jamesbrobb
   *
   * Permission is hereby granted, free of charge, to any person obtaining
   * a copy of this software and associated documentation files (the
   * "Software"), to deal in the Software without restriction, including
   * without limitation the rights to use, copy, modify, merge, publish,
   * distribute, sublicense, and/or sell copies of the Software, and to
   * permit persons to whom the Software is furnished to do so, subject to
   * the following conditions:
   *
   * The above copyright notice and this permission notice shall be
   * included in all copies or substantial portions of the Software.
   *
   * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
   * EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
   * MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
   * NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
   * LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
   * OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
   * WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
   *)
  (**
   * @license
    Copyright (c) 2008, Adobe Systems Incorporated
    All rights reserved.
  
    Redistribution and use in source and binary forms, with or without 
    modification, are permitted provided that the following conditions are
    met:
  
    * Redistributions of source code must retain the above copyright notice, 
      this list of conditions and the following disclaimer.
    
    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the 
      documentation and/or other materials provided with the distribution.
    
    * Neither the name of Adobe Systems Incorporated nor the names of its 
      contributors may be used to endorse or promote products derived from 
      this software without specific prior written permission.
  
    THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS
    IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
    THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
    PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR 
    CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
    EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
    PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
    PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
    LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
    NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
    SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
  *)
  (**
   * @license
   * Copyright (c) 2017 Aras Abbasi
   *
   * Licensed under the MIT License.
   * http://opensource.org/licenses/mit-license
   *)
  (** ====================================================================
   * @license
   * jsPDF XMP metadata plugin
   * Copyright (c) 2016 Jussi Utunen, u-jussi@suomi24.fi
   *
   * Permission is hereby granted, free of charge, to any person obtaining
   * a copy of this software and associated documentation files (the
   * "Software"), to deal in the Software without restriction, including
   * without limitation the rights to use, copy, modify, merge, publish,
   * distribute, sublicense, and/or sell copies of the Software, and to
   * permit persons to whom the Software is furnished to do so, subject to
   * the following conditions:
   *
   * The above copyright notice and this permission notice shall be
   * included in all copies or substantial portions of the Software.
   *
   * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
   * EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
   * MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
   * NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
   * LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
   * OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
   * WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
   * ====================================================================
   *)
*/
