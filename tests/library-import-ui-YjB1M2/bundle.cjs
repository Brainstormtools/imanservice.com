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
      var React3 = require("/workspace/scratch/76b8a24bf15c/imanservice/node_modules/react/index.js"), REACT_ELEMENT_TYPE = /* @__PURE__ */ Symbol.for("react.transitional.element"), REACT_PORTAL_TYPE = /* @__PURE__ */ Symbol.for("react.portal"), REACT_FRAGMENT_TYPE = /* @__PURE__ */ Symbol.for("react.fragment"), REACT_STRICT_MODE_TYPE = /* @__PURE__ */ Symbol.for("react.strict_mode"), REACT_PROFILER_TYPE = /* @__PURE__ */ Symbol.for("react.profiler"), REACT_CONSUMER_TYPE = /* @__PURE__ */ Symbol.for("react.consumer"), REACT_CONTEXT_TYPE = /* @__PURE__ */ Symbol.for("react.context"), REACT_FORWARD_REF_TYPE = /* @__PURE__ */ Symbol.for("react.forward_ref"), REACT_SUSPENSE_TYPE = /* @__PURE__ */ Symbol.for("react.suspense"), REACT_SUSPENSE_LIST_TYPE = /* @__PURE__ */ Symbol.for("react.suspense_list"), REACT_MEMO_TYPE = /* @__PURE__ */ Symbol.for("react.memo"), REACT_LAZY_TYPE = /* @__PURE__ */ Symbol.for("react.lazy"), REACT_ACTIVITY_TYPE = /* @__PURE__ */ Symbol.for("react.activity"), REACT_VIEW_TRANSITION_TYPE = /* @__PURE__ */ Symbol.for("react.view_transition"), REACT_CLIENT_REFERENCE = /* @__PURE__ */ Symbol.for("react.client.reference"), ReactSharedInternals = React3.__CLIENT_INTERNALS_DO_NOT_USE_OR_WARN_USERS_THEY_CANNOT_UPGRADE, hasOwnProperty = Object.prototype.hasOwnProperty, isArrayImpl = Array.isArray, createTask = console.createTask ? console.createTask : function() {
        return null;
      };
      React3 = {
        react_stack_bottom_frame: function(callStackForError) {
          return callStackForError();
        }
      };
      var specialPropKeyWarningShown;
      var didWarnAboutElementRef = {};
      var unknownOwnerDebugStack = React3.react_stack_bottom_frame.bind(
        React3,
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

// src/portal/task-library.tsx
var task_library_exports = {};
__export(task_library_exports, {
  TaskLibrary: () => TaskLibrary
});
module.exports = __toCommonJS(task_library_exports);
var import_react2 = require("/workspace/scratch/76b8a24bf15c/imanservice/node_modules/react/index.js");

// mock:./client
var db = { rpc: globalThis.__rpc };
function check(r) {
  if (r.error) throw r.error;
  return r.data;
}

// src/portal/task-library-import.tsx
var import_react = require("/workspace/scratch/76b8a24bf15c/imanservice/node_modules/react/index.js");

// mock:./business-utils
var parseCSV = JSON.parse;
var readXLSX = globalThis.__xlsx;
var csvText = JSON.stringify;
var downloadText = globalThis.__download;

// src/portal/task-standard-import.ts
var standardImportFields = ["name", "key", "phase", "title", "process", "step", "unit", "minutes", "fixed_minutes", "fixed_quantity", "crew", "crew_role", "tools", "preconditions", "checklist"];
var requiredStandardFields = ["name", "key", "phase", "title", "unit", "minutes", "fixed_minutes", "fixed_quantity", "crew", "crew_role"];
function mapStandardRows(rows, mapping) {
  if (rows.length < 2 || rows.length > 101) throw new Error("Use 1\u2013100 standard rows plus headers");
  const used = standardImportFields.map((k) => Number(mapping[k] ?? -1)).filter((n) => n >= 0);
  if (new Set(used).size !== used.length || used.some((n) => !Number.isInteger(n) || n >= rows[0].length) || requiredStandardFields.some((k) => !used.includes(Number(mapping[k] ?? -1)))) throw new Error("Map required fields to distinct source columns");
  const names = /* @__PURE__ */ new Set(), keys = /* @__PURE__ */ new Set();
  return rows.slice(1).map((cells, i) => {
    const fail = (message) => {
      throw new Error(`Row ${i + 2}: ${message}`);
    };
    if (cells.length > rows[0].length) fail("Too many columns");
    const v = Object.fromEntries(standardImportFields.map((k) => [k, (cells[Number(mapping[k])] || "").trim()]));
    for (const [k, max] of [["name", 160], ["title", 200], ["unit", 30], ["crew_role", 100]]) if (!v[k] || v[k].length > max) fail(`${k} must contain 1\u2013${max} characters`);
    if (!/^[a-z][a-z0-9_]{0,39}$/.test(v.key)) fail("Use a lowercase task key");
    if (names.has(v.name.toLowerCase()) || keys.has(v.key)) fail("Duplicate standard name or task key");
    names.add(v.name.toLowerCase());
    keys.add(v.key);
    if (!/^[0-5]$/.test(v.phase)) fail("Phase must be an integer 0\u20135");
    if (!/^(?:[1-9][0-9]?|100)$/.test(v.crew)) fail("Crew must be an integer 1\u2013100");
    for (const k of ["minutes", "fixed_minutes", "fixed_quantity"]) if (!/^\d+(?:\.\d+)?$/.test(v[k]) || Number(v[k]) > 1e5) fail(`${k} requires explicit numeric values 0\u2013100000`);
    if (v.tools.length > 2e3 || v.preconditions.length > 2e3 || v.process.length > 2e3 || v.step.length > 2e3) fail("Text field exceeds 2000 characters");
    const checklist = v.checklist ? v.checklist.split(/\r?\n/).map((s) => s.trim()) : [];
    if (checklist.length > 30 || checklist.some((s) => !s || s.length > 200)) fail("Use up to 30 nonempty checklist lines, 200 characters each");
    return { name: v.name, task: { key: v.key, phase: Number(v.phase), title: v.title, process: v.process, step: v.step, unit: v.unit, minutes: Number(v.minutes), fixed_minutes: Number(v.fixed_minutes), fixed_quantity: Number(v.fixed_quantity), crew: Number(v.crew), crew_role: v.crew_role, tools: v.tools, preconditions: v.preconditions, checklist, quantity_parameters: [], factor_parameter: "", condition_parameter: "", depends_on: [] } };
  });
}

// src/portal/task-library-import.tsx
var import_jsx_runtime = __toESM(require_jsx_runtime(), 1);
function TaskLibraryImport({ onChanged }) {
  const [rows, setRows] = (0, import_react.useState)([]), [mapping, setMapping] = (0, import_react.useState)({}), [source, setSource] = (0, import_react.useState)(""), [batch, setBatch] = (0, import_react.useState)(""), [reason, setReason] = (0, import_react.useState)(""), [confirmed, setConfirmed] = (0, import_react.useState)(false), [busy, setBusy] = (0, import_react.useState)(false), [error, setError] = (0, import_react.useState)(""), [notice, setNotice] = (0, import_react.useState)("");
  let preview = [];
  let validation = "";
  if (rows.length) {
    try {
      preview = mapStandardRows(rows, mapping);
    } catch (e) {
      validation = e.message;
    }
  }
  const clear = () => {
    setRows([]);
    setConfirmed(false);
    setReason("");
    setError("");
  };
  return /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("details", { className: "p-panel", children: [
    /* @__PURE__ */ (0, import_jsx_runtime.jsx)("summary", { children: "Review task-library import" }),
    /* @__PURE__ */ (0, import_jsx_runtime.jsx)("p", { children: "Map a values-only CSV or XLSX file, up to 100 rows and 5 MB. XLSX reads the first worksheet and rejects formulas. Phase is 0\u20135, times are minutes and crew is a headcount. Enter explicit setup minutes and fixed quantity, including zero when applicable. Checklist items use separate lines in one cell. All rows save together as new inactive standards; existing standards and project plans are unchanged. Review and activate individual standards separately. Formula parameters and spreadsheet formulas require manual configuration." }),
    /* @__PURE__ */ (0, import_jsx_runtime.jsx)("button", { disabled: busy, onClick: () => downloadText("task-library-import-template.csv", csvText([standardImportFields])), children: "Download library import template" }),
    /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("label", { className: "p-field", children: [
      "Task-library CSV or XLSX",
      /* @__PURE__ */ (0, import_jsx_runtime.jsx)("input", { type: "file", accept: ".csv,.xlsx", disabled: busy, onChange: async (e) => {
        const f = e.target.files?.[0];
        clear();
        setNotice("");
        if (!f) return;
        setBusy(true);
        try {
          if (f.size > 5 * 1024 * 1024) throw new Error("Maximum file size is 5 MB");
          if (f.name.length > 180) throw new Error("Source filename must be 180 characters or less");
          const data = /\.xlsx$/i.test(f.name) ? await readXLSX(await f.arrayBuffer()) : /\.csv$/i.test(f.name) ? parseCSV(await f.text()) : null;
          if (!data) throw new Error("Choose CSV or XLSX");
          if (data.length < 2 || data.length > 101) throw new Error("Use 1\u2013100 standard rows plus headers");
          setRows(data);
          setMapping(Object.fromEntries(standardImportFields.map((k) => [k, String(data[0].findIndex((h) => h.trim().toLowerCase() === k))])));
          setSource(f.name);
          setBatch(crypto.randomUUID());
        } catch (e2) {
          setError(e2.message);
        } finally {
          setBusy(false);
        }
      } })
    ] }),
    rows.length > 0 && /* @__PURE__ */ (0, import_jsx_runtime.jsxs)(import_jsx_runtime.Fragment, { children: [
      /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("p", { children: [
        "Source: ",
        source,
        " \xB7 ",
        rows.length - 1,
        " proposed standards"
      ] }),
      standardImportFields.map((k) => /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("label", { className: "p-field", children: [
        k.replaceAll("_", " "),
        requiredStandardFields.includes(k) ? " (required)" : "",
        /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("select", { disabled: busy, value: mapping[k], onChange: (e) => {
          setMapping({ ...mapping, [k]: e.target.value });
          setConfirmed(false);
          setBatch(crypto.randomUUID());
          setError("");
        }, children: [
          /* @__PURE__ */ (0, import_jsx_runtime.jsx)("option", { value: "-1", children: "Not mapped" }),
          rows[0].map((h, i) => /* @__PURE__ */ (0, import_jsx_runtime.jsx)("option", { value: i, children: h || `Column ${i + 1}` }, i))
        ] })
      ] }, k)),
      validation ? /* @__PURE__ */ (0, import_jsx_runtime.jsx)("p", { role: "alert", children: validation }) : /* @__PURE__ */ (0, import_jsx_runtime.jsxs)(import_jsx_runtime.Fragment, { children: [
        /* @__PURE__ */ (0, import_jsx_runtime.jsx)("div", { className: "p-table-scroll", children: /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("table", { className: "p-table", children: [
          /* @__PURE__ */ (0, import_jsx_runtime.jsx)("thead", { children: /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("tr", { children: [
            /* @__PURE__ */ (0, import_jsx_runtime.jsx)("th", { children: "Name/key" }),
            /* @__PURE__ */ (0, import_jsx_runtime.jsx)("th", { children: "Phase/task" }),
            /* @__PURE__ */ (0, import_jsx_runtime.jsx)("th", { children: "Unit/time/setup" }),
            /* @__PURE__ */ (0, import_jsx_runtime.jsx)("th", { children: "Quantity/crew" }),
            /* @__PURE__ */ (0, import_jsx_runtime.jsx)("th", { children: "Process/step" }),
            /* @__PURE__ */ (0, import_jsx_runtime.jsx)("th", { children: "Tools/readiness/checklist" })
          ] }) }),
          /* @__PURE__ */ (0, import_jsx_runtime.jsx)("tbody", { children: preview.map((r, i) => /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("tr", { children: [
            /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("td", { children: [
              r.name,
              " \xB7 ",
              r.task.key
            ] }),
            /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("td", { children: [
              r.task.phase,
              " \xB7 ",
              r.task.title
            ] }),
            /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("td", { children: [
              r.task.unit,
              " \xB7 ",
              r.task.minutes,
              " min/unit \xB7 ",
              r.task.fixed_minutes,
              " setup min"
            ] }),
            /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("td", { children: [
              r.task.fixed_quantity,
              " fixed \xB7 ",
              r.task.crew,
              " ",
              r.task.crew_role
            ] }),
            /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("td", { children: [
              r.task.process,
              " \xB7 ",
              r.task.step
            ] }),
            /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("td", { children: [
              r.task.tools,
              " \xB7 ",
              r.task.preconditions,
              " \xB7 ",
              r.task.checklist.join("; ")
            ] })
          ] }, i)) })
        ] }) }),
        /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("label", { className: "p-field", children: [
          "Import review reason",
          /* @__PURE__ */ (0, import_jsx_runtime.jsx)("textarea", { disabled: busy, value: reason, minLength: 3, maxLength: 2e3, onChange: (e) => {
            setReason(e.target.value);
            setConfirmed(false);
            setBatch(crypto.randomUUID());
          } })
        ] }),
        /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("label", { className: "p-check", children: [
          /* @__PURE__ */ (0, import_jsx_runtime.jsx)("input", { type: "checkbox", disabled: busy, checked: confirmed, onChange: (e) => setConfirmed(e.target.checked) }),
          "I reviewed all mapped values, units, times and crew; save these as inactive standards."
        ] }),
        /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("button", { disabled: busy || !confirmed || reason.trim().length < 3 || reason.trim().length > 2e3, onClick: async () => {
          if (busy || !confirmed) return;
          setBusy(true);
          setError("");
          let saved = false;
          try {
            const ids = check(await db.rpc("import_crm_task_standards", { p_batch: batch, p_source: source, p_reason: reason, p_rows: preview }));
            saved = true;
            setRows([]);
            setConfirmed(false);
            setReason("");
            setNotice(`${ids.length} inactive library standards saved. Review and activate separately.`);
            await onChanged();
          } catch (e) {
            setError((saved ? "Import saved; library refresh failed: " : "") + e.message);
          } finally {
            setBusy(false);
          }
        }, children: [
          "Save ",
          preview.length,
          " inactive standards"
        ] })
      ] }),
      /* @__PURE__ */ (0, import_jsx_runtime.jsx)("button", { disabled: busy, onClick: clear, children: "Cancel library import" })
    ] }),
    error && /* @__PURE__ */ (0, import_jsx_runtime.jsx)("p", { role: "alert", children: error }),
    notice && /* @__PURE__ */ (0, import_jsx_runtime.jsx)("p", { role: "status", children: notice })
  ] });
}

// src/portal/task-library.tsx
var import_jsx_runtime2 = __toESM(require_jsx_runtime(), 1);
var phases = ["Mobilization", "Civil & containment", "Cable deployment", "Termination & installation", "Testing & commissioning", "QA-QC & handover"];
var fresh = () => ({ key: "", phase: 0, title: "", process: "", step: "", unit: "", minutes: "", fixed_minutes: "", fixed_quantity: "", quantity_parameters: [], factor_parameter: "", condition_parameter: "", crew: "", crew_role: "", tools: "", preconditions: "", depends_on: [], checklist: [] });
function Field({ label, value, onChange, numeric = false, required = false, integer = false }) {
  return /* @__PURE__ */ (0, import_jsx_runtime2.jsxs)("label", { className: "p-field", children: [
    label,
    /* @__PURE__ */ (0, import_jsx_runtime2.jsx)("input", { type: numeric ? "number" : "text", value: value ?? "", required, min: numeric ? integer ? 1 : 0 : void 0, step: numeric ? integer ? 1 : "any" : void 0, onChange: (e) => onChange(numeric ? e.target.value === "" ? "" : Number(e.target.value) : e.target.value) })
  ] });
}
function TaskLibrary({ admin, entries, versions, imports = [], onChanged }) {
  const [id, setId] = (0, import_react2.useState)(""), [base, setBase] = (0, import_react2.useState)(null), [name, setName] = (0, import_react2.useState)(""), [active, setActive] = (0, import_react2.useState)(true), [parameters, setParameters] = (0, import_react2.useState)([]), [task, setTask] = (0, import_react2.useState)(fresh), [reason, setReason] = (0, import_react2.useState)(""), [busy, setBusy] = (0, import_react2.useState)(false), [error, setError] = (0, import_react2.useState)(""), [notice, setNotice] = (0, import_react2.useState)("");
  const choose = (value) => {
    const entry = entries.find((s) => s.id === value), v = versions.find((v2) => v2.standard_id === value && v2.revision === entry?.version);
    setId(value);
    setBase(entry?.version ?? null);
    setName(entry?.name || "");
    setActive(entry?.active ?? true);
    setParameters(v ? JSON.parse(JSON.stringify(v.parameters)) : []);
    setTask(v ? JSON.parse(JSON.stringify(v.task)) : fresh());
    setReason("");
    setError("");
    setNotice("");
  };
  const patch = (key, value) => setTask({ ...task, [key]: value });
  return /* @__PURE__ */ (0, import_jsx_runtime2.jsxs)("section", { className: "p-panel", children: [
    /* @__PURE__ */ (0, import_jsx_runtime2.jsx)("h2", { children: "Task library" }),
    /* @__PURE__ */ (0, import_jsx_runtime2.jsx)("p", { children: "Independent reusable standards. Each administrator save records a reason, author and fixed revision. Deactivation removes a standard from new copies; previously saved templates and project plans retain their values. Enter approved business times and crew requirements." }),
    error && /* @__PURE__ */ (0, import_jsx_runtime2.jsx)("p", { role: "alert", className: "p-error", children: error }),
    notice && /* @__PURE__ */ (0, import_jsx_runtime2.jsx)("p", { role: "status", children: notice }),
    admin && /* @__PURE__ */ (0, import_jsx_runtime2.jsxs)(import_jsx_runtime2.Fragment, { children: [
      /* @__PURE__ */ (0, import_jsx_runtime2.jsx)(TaskLibraryImport, { onChanged }),
      imports.length > 0 && /* @__PURE__ */ (0, import_jsx_runtime2.jsxs)("details", { children: [
        /* @__PURE__ */ (0, import_jsx_runtime2.jsx)("summary", { children: "Saved library import receipts" }),
        imports.map((r) => /* @__PURE__ */ (0, import_jsx_runtime2.jsxs)("article", { children: [
          /* @__PURE__ */ (0, import_jsx_runtime2.jsx)("h3", { children: r.source_name }),
          /* @__PURE__ */ (0, import_jsx_runtime2.jsxs)("p", { children: [
            r.reason,
            " \xB7 Reviewer ",
            r.author_id,
            " \xB7 ",
            r.created_at
          ] }),
          /* @__PURE__ */ (0, import_jsx_runtime2.jsxs)("p", { children: [
            "Batch ",
            r.batch_id,
            " \xB7 Standards: ",
            r.standard_ids.join(", ")
          ] }),
          /* @__PURE__ */ (0, import_jsx_runtime2.jsx)("p", { children: "These records were imported inactive; check each standard's current revision for activation." })
        ] }, r.author_id + ":" + r.batch_id))
      ] }),
      /* @__PURE__ */ (0, import_jsx_runtime2.jsxs)("label", { className: "p-field", children: [
        "Library standard",
        /* @__PURE__ */ (0, import_jsx_runtime2.jsxs)("select", { disabled: busy, value: id, onChange: (e) => choose(e.target.value), children: [
          /* @__PURE__ */ (0, import_jsx_runtime2.jsx)("option", { value: "", children: "New independent standard" }),
          entries.map((s) => /* @__PURE__ */ (0, import_jsx_runtime2.jsxs)("option", { value: s.id, children: [
            s.name,
            " \xB7 v",
            s.version,
            s.active ? "" : " \xB7 Inactive"
          ] }, s.id))
        ] })
      ] }),
      /* @__PURE__ */ (0, import_jsx_runtime2.jsxs)("form", { className: "p-form", onSubmit: async (e) => {
        e.preventDefault();
        if (busy) return;
        setBusy(true);
        setError("");
        setNotice("");
        try {
          const saved = check(await db.rpc("save_crm_task_standard", { p_id: id || null, p_version: base, p_name: name, p_active: active, p_parameters: parameters, p_task: { ...task, checklist: task.checklist.map((s) => s.trim()).filter(Boolean) }, p_reason: reason }));
          setId(saved);
          setBase((base ?? 0) + 1);
          setReason("");
          setNotice("Task library revision saved. Existing project plans are unchanged.");
          await onChanged();
        } catch (e2) {
          setError(e2.message);
        } finally {
          setBusy(false);
        }
      }, children: [
        /* @__PURE__ */ (0, import_jsx_runtime2.jsx)(Field, { label: "Standard name", value: name, onChange: setName, required: true }),
        /* @__PURE__ */ (0, import_jsx_runtime2.jsxs)("label", { className: "p-check", children: [
          /* @__PURE__ */ (0, import_jsx_runtime2.jsx)("input", { type: "checkbox", checked: active, onChange: (e) => setActive(e.target.checked) }),
          "Active for new copies"
        ] }),
        /* @__PURE__ */ (0, import_jsx_runtime2.jsx)("h3", { children: "Formula parameters" }),
        parameters.map((p, i) => /* @__PURE__ */ (0, import_jsx_runtime2.jsxs)("div", { className: "p-panel", children: [
          ["key", "label", "min", "max", "default"].map((k) => /* @__PURE__ */ (0, import_jsx_runtime2.jsx)(Field, { label: "Library parameter " + k, value: p[k], numeric: ["min", "max", "default"].includes(k), required: true, onChange: (v) => setParameters(parameters.map((x, n) => n === i ? { ...x, [k]: v } : x)) }, k)),
          /* @__PURE__ */ (0, import_jsx_runtime2.jsx)("button", { type: "button", disabled: busy, onClick: () => setParameters(parameters.filter((_, n) => n !== i)), children: "Remove library parameter" })
        ] }, i)),
        /* @__PURE__ */ (0, import_jsx_runtime2.jsx)("button", { type: "button", disabled: busy || parameters.length >= 30, onClick: () => setParameters([...parameters, { key: "", label: "", min: "", max: "", default: "" }]), children: "Add library parameter" }),
        /* @__PURE__ */ (0, import_jsx_runtime2.jsx)("h3", { children: "Standard task" }),
        ["key", "title", "process", "step", "unit", "crew_role", "tools", "preconditions"].map((k) => /* @__PURE__ */ (0, import_jsx_runtime2.jsx)(Field, { label: "Library task " + k.replaceAll("_", " "), value: task[k], required: ["key", "title", "unit", "crew_role"].includes(k), onChange: (v) => patch(k, v) }, k)),
        /* @__PURE__ */ (0, import_jsx_runtime2.jsxs)("label", { className: "p-field", children: [
          "Library task phase",
          /* @__PURE__ */ (0, import_jsx_runtime2.jsx)("select", { value: task.phase, onChange: (e) => patch("phase", Number(e.target.value)), children: phases.map((p, i) => /* @__PURE__ */ (0, import_jsx_runtime2.jsxs)("option", { value: i, children: [
            i,
            " \xB7 ",
            p
          ] }, i)) })
        ] }),
        [["minutes", "Minutes per unit"], ["fixed_minutes", "Setup minutes"], ["fixed_quantity", "Fixed quantity"], ["crew", "Crew count"]].map(([k, label]) => /* @__PURE__ */ (0, import_jsx_runtime2.jsx)(Field, { label: "Library " + label, numeric: true, integer: k === "crew", required: true, value: task[k], onChange: (v) => patch(k, v) }, k)),
        /* @__PURE__ */ (0, import_jsx_runtime2.jsxs)("fieldset", { children: [
          /* @__PURE__ */ (0, import_jsx_runtime2.jsx)("legend", { children: "Library quantity parameters" }),
          parameters.filter((p) => p.key).map((p) => /* @__PURE__ */ (0, import_jsx_runtime2.jsxs)("label", { className: "p-check", children: [
            /* @__PURE__ */ (0, import_jsx_runtime2.jsx)("input", { type: "checkbox", checked: task.quantity_parameters.includes(p.key), onChange: (e) => patch("quantity_parameters", e.target.checked ? [...task.quantity_parameters, p.key] : task.quantity_parameters.filter((k) => k !== p.key)) }),
            p.label || p.key
          ] }, p.key))
        ] }),
        [["factor_parameter", "Library duration factor"], ["condition_parameter", "Library inclusion condition"]].map(([k, label]) => /* @__PURE__ */ (0, import_jsx_runtime2.jsxs)("label", { className: "p-field", children: [
          label,
          /* @__PURE__ */ (0, import_jsx_runtime2.jsxs)("select", { value: task[k], onChange: (e) => patch(k, e.target.value), children: [
            /* @__PURE__ */ (0, import_jsx_runtime2.jsx)("option", { value: "", children: "None" }),
            parameters.filter((p) => p.key).map((p) => /* @__PURE__ */ (0, import_jsx_runtime2.jsx)("option", { value: p.key, children: p.label || p.key }, p.key))
          ] })
        ] }, k)),
        /* @__PURE__ */ (0, import_jsx_runtime2.jsx)("p", { children: "Independent standards have no predecessors. Add project-specific dependencies after copying into a template." }),
        /* @__PURE__ */ (0, import_jsx_runtime2.jsxs)("label", { className: "p-field", children: [
          "Library checklist, one item per line",
          /* @__PURE__ */ (0, import_jsx_runtime2.jsx)("textarea", { value: task.checklist.join("\n"), onChange: (e) => patch("checklist", e.target.value.split("\n")) })
        ] }),
        /* @__PURE__ */ (0, import_jsx_runtime2.jsx)(Field, { label: "Library revision reason", value: reason, onChange: setReason, required: true }),
        /* @__PURE__ */ (0, import_jsx_runtime2.jsx)("button", { disabled: busy, children: busy ? "Saving library revision\u2026" : "Save library revision" })
      ] })
    ] }),
    !entries.length && /* @__PURE__ */ (0, import_jsx_runtime2.jsx)("p", { children: "No task library standards configured." }),
    entries.map((s) => /* @__PURE__ */ (0, import_jsx_runtime2.jsxs)("details", { children: [
      /* @__PURE__ */ (0, import_jsx_runtime2.jsxs)("summary", { children: [
        s.name,
        " \xB7 v",
        s.version,
        " \xB7 ",
        s.active ? "Active" : "Inactive"
      ] }),
      versions.filter((v) => v.standard_id === s.id).sort((a, b) => b.revision - a.revision).map((v) => /* @__PURE__ */ (0, import_jsx_runtime2.jsxs)("article", { className: "p-service-entry", children: [
        /* @__PURE__ */ (0, import_jsx_runtime2.jsxs)("h3", { children: [
          "Revision ",
          v.revision,
          " \xB7 ",
          v.name,
          " \xB7 ",
          v.active ? "Active" : "Inactive"
        ] }),
        /* @__PURE__ */ (0, import_jsx_runtime2.jsxs)("p", { children: [
          v.task.title,
          " \xB7 Phase ",
          v.task.phase,
          " \xB7 ",
          v.task.minutes,
          " minutes per ",
          v.task.unit,
          " \xB7 Setup ",
          v.task.fixed_minutes,
          " minutes \xB7 Crew ",
          v.task.crew,
          " ",
          v.task.crew_role
        ] }),
        /* @__PURE__ */ (0, import_jsx_runtime2.jsxs)("p", { children: [
          v.task.process,
          " \xB7 ",
          v.task.step,
          " \xB7 ",
          v.task.tools,
          " \xB7 ",
          v.task.preconditions
        ] }),
        /* @__PURE__ */ (0, import_jsx_runtime2.jsxs)("p", { children: [
          "Fixed quantity: ",
          v.task.fixed_quantity,
          " \xB7 Quantity parameters: ",
          v.task.quantity_parameters.join(", ") || "None",
          " \xB7 Duration factor: ",
          v.task.factor_parameter || "None",
          " \xB7 Inclusion condition: ",
          v.task.condition_parameter || "None"
        ] }),
        v.parameters.map((p) => /* @__PURE__ */ (0, import_jsx_runtime2.jsxs)("p", { children: [
          p.label,
          " (",
          p.key,
          ") \xB7 Range ",
          p.min,
          "\u2013",
          p.max,
          " \xB7 Default ",
          p.default
        ] }, p.key)),
        /* @__PURE__ */ (0, import_jsx_runtime2.jsxs)("p", { children: [
          "Reason: ",
          v.reason,
          " \xB7 Author: ",
          v.author_id,
          " \xB7 ",
          v.created_at
        ] }),
        /* @__PURE__ */ (0, import_jsx_runtime2.jsxs)("p", { children: [
          "Checklist: ",
          v.task.checklist.join("; ") || "None"
        ] })
      ] }, v.id))
    ] }, s.id))
  ] });
}
// Annotate the CommonJS export names for ESM import in node:
0 && (module.exports = {
  TaskLibrary
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
*/
