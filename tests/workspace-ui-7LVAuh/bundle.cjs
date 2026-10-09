Warning: truncated output (original token count: 478798)
... 866616 bytes omitted ...

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
    module2.exports = crc32;
  }
});

// node_modules/pako/lib/zlib/messages.js
var require_messages = __commonJS({
  "node_modules/pako/lib/zlib/messages.js"(exports2, module2) {
    "use strict";
    module2.exports = {
      2: "need dictionary",
      /* Z_NEED_DICT       2  */
      1: "stream end",
      /* Z_STREAM_END      1  */
      0: "",
      /* Z_OK              0  */
      "-1": "file error",
      /* Z_ERRNO         (-1) */
      "-2": "stream error",
      /* Z_STREAM_ERROR  (-2) */
      "-3": "data error",
      /* Z_DATA_ERROR    (-3) */
      "-4": "insufficient memory",
      /* Z_MEM_ERROR     (-4) */
      "-5": "buffer error",
      /* Z_BUF_ERROR     (-5) */
      "-6": "incompatible version"
      /* Z_VERSION_ERROR (-6) */
    };
  }
});

// node_modules/pako/lib/zlib/constants.js
var require_constants = __commonJS({
  "node_modules/pako/lib/zlib/constants.js"(exports2, module2) {
    "use strict";
    module2.exports = {
      /* Allowed flush values; see deflate() and inflate() below for details */
      Z_NO_FLUSH: 0,
      Z_PARTIAL_FLUSH: 1,
      Z_SYNC_FLUSH: 2,
      Z_FULL_FLUSH: 3,
      Z_FINISH: 4,
      Z_BLOCK: 5,
      Z_TREES: 6,
      /* Return codes for the compression/decompression functions. Negative values
      * are errors, positive values are used for special but normal events.
      */
      Z_OK: 0,
      Z_STREAM_END: 1,
      Z_NEED_DICT: 2,
      Z_ERRNO: -1,
      Z_STREAM_ERROR: -2,
      Z_DATA_ERROR: -3,
      Z_MEM_ERROR: -4,
      Z_BUF_ERROR: -5,
      //Z_VERSION_ERROR: -6,
      /* compression levels */
      Z_NO_COMPRESSION: 0,
      Z_BEST_SPEED: 1,
      Z_BEST_COMPRESSION: 9,
      Z_DEFAULT_COMPRESSION: -1,
      Z_FILTERED: 1,
      Z_HUFFMAN_ONLY: 2,
      Z_RLE: 3,
      Z_FIXED: 4,
      Z_DEFAULT_STRATEGY: 0,
      /* Possible values of the data_type field (though see inflate()) */
      Z_BINARY: 0,
      Z_TEXT: 1,
      //Z_ASCII:                1, // = Z_TEXT (deprecated)
      Z_UNKNOWN: 2,
      /* The deflate compression method */
      Z_DEFLATED: 8
      //Z_NULL:                 null // Use -1 or null inline, depending on var type
    };
  }
});

// node_modules/pako/lib/zlib/deflate.js
var require_deflate = __commonJS({
  "node_modules/pako/lib/zlib/deflate.js"(exports2, module2) {
    "use strict";
    var { _tr_init, _tr_stored_block, _tr_flush_block, _tr_tally, _tr_align } = require_trees();
    var adler32 = require_adler32();
    var crc32 = require_crc32();
    var msg = require_messages();
    var {
      Z_NO_FLUSH,
      Z_PARTIAL_FLUSH,
      Z_FULL_FLUSH,
      Z_FINISH,
      Z_BLOCK,
      Z_OK,
      Z_STREAM_END,
      Z_STREAM_ERROR,
      Z_DATA_ERROR,
      Z_BUF_ERROR,
      Z_DEFAULT_COMPRESSION,
      Z_FILTERED,
      Z_HUFFMAN_ONLY,
      Z_RLE,
      Z_FIXED,
      Z_DEFAULT_STRATEGY,
      Z_UNKNOWN,
      Z_DEFLATED
    } = require_constants();
    var MAX_MEM_LEVEL = 9;
    var MAX_WBITS = 15;
    var DEF_MEM_LEVEL = 8;
    var LENGTH_CODES = 29;
    var LITERALS = 256;
    var L_CODES = LITERALS + 1 + LENGTH_CODES;
    var D_CODES = 30;
    var BL_CODES = 19;
    var HEAP_SIZE = 2 * L_CODES + 1;
    var MAX_BITS = 15;
    var MIN_MATCH = 3;
    var MAX_MATCH = 258;
    var MIN_LOOKAHEAD = MAX_MATCH + MIN_MATCH + 1;
    var PRESET_DICT = 32;
    var INIT_STATE = 42;
    var GZIP_STATE = 57;
    var EXTRA_STATE = 69;
    var NAME_STATE = 73;
    var COMMENT_STATE = 91;
    var HCRC_STATE = 103;
    var BUSY_STATE = 113;
    var FINISH_STATE = 666;
    var BS_NEED_MORE = 1;
    var BS_BLOCK_DONE = 2;
    var BS_FINISH_STARTED = 3;
    var BS_FINISH_DONE = 4;
    var OS_CODE = 3;
    var err = (strm, errorCode) => {
      strm.msg = msg[errorCode];
      return errorCode;
    };
    var rank = (f) => {
      return f * 2 - (f > 4 ? 9 : 0);
    };
    var zero = (buf) => {
      let len = buf.length;
      while (--len >= 0) {
        buf[len] = 0;
      }
    };
    var slide_hash = (s) => {
      let n, m;
      let p;
      let wsize = s.w_size;
      n = s.hash_size;
      p = n;
      do {
        m = s.head[--p];
        s.head[p] = m >= wsize ? m - wsize : 0;
      } while (--n);
      n = wsize;
      p = n;
      do {
        m = s.prev[--p];
        s.prev[p] = m >= wsize ? m - wsize : 0;
      } while (--n);
    };
    var HASH = (s, prev, data) => (prev << s.hash_shift ^ data) & s.hash_mask;
    var INSERT_STRING = (s, str) => {
      let h;
      if (s.legacy_hash) {
        h = s.ins_h = HASH(s, s.ins_h, s.window[str + MIN_MATCH - 1]);
      } else {
        const w = s.window;
        const value = w[str] | w[str + 1] << 8 | w[str + 2] << 16 | w[str + 3] << 24;
        h = s.ins_h = Math.imul(value, 66521) + 66521 >>> 16 & s.hash_mask;
      }
      const hash_head = s.prev[str & s.w_mask] = s.head[h];
      s.head[h] = str;
      return hash_head;
    };
    var flush_pending = (strm) => {
      const s = strm.state;
      let len = s.pending;
      if (len > strm.avail_out) {
        len = strm.avail_out;
      }
      if (len === 0) {
        return;
      }
      strm.output.set(s.pending_buf.subarray(s.pending_out, s.pending_out + len), strm.next_out);
      strm.next_out += len;
      s.pending_out += len;
      strm.total_out += len;
      strm.avail_out -= len;
      s.pending -= len;
      if (s.pending === 0) {
        s.pending_out = 0;
      }
    };
    var flush_block_only = (s, last) => {
      _tr_flush_block(s, s.block_start >= 0 ? s.block_start : -1, s.strstart - s.block_start, last);
      s.block_start = s.strstart;
      flush_pending(s.strm);
    };
    var put_byte = (s, b) => {
      s.pending_buf[s.pending++] = b;
    };
    var putShortMSB = (s, b) => {
      s.pending_buf[s.pending++] = b >>> 8 & 255;
      s.pending_buf[s.pending++] = b & 255;
    };
    var read_buf = (strm, buf, start, size) => {
      let len = strm.avail_in;
      if (len > size) {
        len = size;
      }
      if (len === 0) {
        return 0;
      }
      strm.avail_in -= len;
      buf.set(strm.input.subarray(strm.next_in, strm.next_in + len), start);
      if (strm.state.wrap === 1) {
        strm.adler = adler32(strm.adler, buf, len, start);
      } else if (strm.state.wrap === 2) {
        strm.adler = crc32(strm.adler, buf, len, start);
      }
      strm.next_in += len;
      strm.total_in += len;
      return len;
    };
    var longest_match = (s, cur_match) => {
      let chain_length = s.max_chain_length;
      let scan = s.strstart;
      let match;
      let len;
      let best_len = s.prev_length;
      let nice_match = s.nice_match;
      const limit = s.strstart > s.w_size - MIN_LOOKAHEAD ? s.strstart - (s.w_size - MIN_LOOKAHEAD) : 0;
      const _win = s.window;
      const wmask = s.w_mask;
      const prev = s.prev;
      const strend = s.strstart + MAX_MATCH;
      let scan_end1 = _win[scan + best_len - 1];
      let scan_end = _win[scan + best_len];
      if (s.prev_length >= s.good_match) {
        chain_length >>= 2;
      }
      if (nice_match > s.lookahead) {
        nice_match = s.lookahead;
      }
      do {
        match = cur_match;
        if (_win[match + best_len] !== scan_end || _win[match + best_len - 1] !== scan_end1 || _win[match] !== _win[scan] || _win[++match] !== _win[scan + 1]) {
          continue;
        }
        scan += 2;
        match++;
        do {
        } while (_win[++scan] === _win[++match] && _win[++scan] === _win[++match] && _win[++scan] === _win[++match] && _win[++scan] === _win[++match] && _win[++scan] === _win[++match] && _win[++scan] === _win[++match] && _win[++scan] === _win[++match] && _win[++scan] === _win[++match] && scan < strend);
        len = MAX_MATCH - (strend - scan);
        scan = strend - MAX_MATCH;
        if (len > best_len) {
          s.match_start = cur_match;
          best_len = len;
          if (len >= nice_match) {
            break;
          }
          scan_end1 = _win[scan + best_len - 1];
          scan_end = _win[scan + best_len];
        }
      } while ((cur_match = prev[cur_match & wmask]) > limit && --chain_length !== 0);
      if (best_len <= s.lookahead) {
        return best_len;
      }
      return s.lookahead;
    };
    var fill_window = (s) => {
      const _w_size = s.w_size;
      let n, more, str;
      do {
        more = s.window_size - s.lookahead - s.strstart;
        if (s.strstart >= _w_size + (_w_size - MIN_LOOKAHEAD)) {
          s.window.set(s.window.subarray(_w_size, _w_size + _w_size - more), 0);
          s.match_start -= _w_size;
          s.strstart -= _w_size;
          s.block_start -= _w_size;
          if (s.insert > s.strstart) {
            s.insert = s.strstart;
          }
          slide_hash(s);
          more += _w_size;
        }
        if (s.strm.avail_in === 0) {
          break;
        }
        n = read_buf(s.strm, s.window, s.strstart + s.lookahead, more);
        s.lookahead += n;
        if (!s.legacy_hash) {
          if (s.lookahead + s.insert > MIN_MATCH) {
            str = s.strstart - s.insert;
            while (s.insert) {
              INSERT_STRING(s, str);
              str++;
              s.insert--;
              if (s.lookahead + s.insert <= MIN_MATCH) {
                break;
              }
            }
          }
        } else if (s.lookahead + s.insert >= MIN_MATCH) {
          str = s.strstart - s.insert;
          s.ins_h = s.window[str];
          s.ins_h = HASH(s, s.ins_h, s.window[str + 1]);
          while (s.insert) {
            INSERT_STRING(s, str);
            str++;
            s.insert--;
            if (s.lookahead + s.insert < MIN_MATCH) {
              break;
            }
          }
        }
      } while (s.lookahead < MIN_LOOKAHEAD && s.strm.avail_in !== 0);
    };
    var deflate_stored = (s, flush) => {
      let min_block = s.pending_buf_size - 5 > s.w_size ? s.w_size : s.pending_buf_size - 5;
      let len, left, have, last = 0;
      let used = s.strm.avail_in;
      do {
        len = 65535;
        have = s.bi_valid + 42 >> 3;
        if (s.strm.avail_out < have) {
          break;
        }
        have = s.strm.avail_out - have;
        left = s.strstart - s.block_start;
        if (len > left + s.strm.avail_in) {
          len = left + s.strm.avail_in;
        }
        if (len > have) {
          len = have;
        }
        if (len < min_block && (len === 0 && flush !== Z_FINISH || flush === Z_NO_FLUSH || len !== left + s.strm.avail_in)) {
          break;
        }
        last = flush === Z_FINISH && len === left + s.strm.avail_in ? 1 : 0;
        _tr_stored_block(s, 0, 0, last);
        s.pending_buf[s.pending - 4] = len;
        s.pending_buf[s.pending - 3] = len >> 8;
        s.pending_buf[s.pending - 2] = ~len;
        s.pending_buf[s.pending - 1] = ~len >> 8;
        flush_pending(s.strm);
        if (left) {
          if (left > len) {
            left = len;
          }
          s.strm.output.set(s.window.subarray(s.block_start, s.block_start + left), s.strm.next_out);
          s.strm.next_out += left;
          s.strm.avail_out -= left;
          s.strm.total_out += left;
          s.block_start += left;
          len -= left;
        }
        if (len) {
          read_buf(s.strm, s.strm.output, s.strm.next_out, len);
          s.strm.next_out += len;
          s.strm.avail_out -= len;
          s.strm.total_out += len;
        }
      } while (last === 0);
      used -= s.strm.avail_in;
      if (used) {
        if (used >= s.w_size) {
          s.matches = 2;
          s.window.set(s.strm.input.subarray(s.strm.next_in - s.w_size, s.strm.next_in), 0);
          s.strstart = s.w_size;
          s.insert = s.strstart;
        } else {
          if (s.window_size - s.strstart <= used) {
            s.strstart -= s.w_size;
            s.window.set(s.window.subarray(s.w_size, s.w_size + s.strstart), 0);
            if (s.matches < 2) {
              s.matches++;
            }
            if (s.insert > s.strstart) {
              s.insert = s.strstart;
            }
          }
          s.window.set(s.strm.input.subarray(s.strm.next_in - used, s.strm.next_in), s.strstart);
          s.strstart += used;
          s.insert += used > s.w_size - s.insert ? s.w_size - s.insert : used;
        }
        s.block_start = s.strstart;
      }
      if (s.high_water < s.strstart) {
        s.high_water = s.strstart;
      }
      if (last) {
        return BS_FINISH_DONE;
      }
      if (flush !== Z_NO_FLUSH && flush !== Z_FINISH && s.strm.avail_in === 0 && s.strstart === s.block_start) {
        return BS_BLOCK_DONE;
      }
      have = s.window_size - s.strstart;
      if (s.strm.avail_in > have && s.block_start >= s.w_size) {
        s.block_start -= s.w_size;
        s.strstart -= s.w_size;
        s.window.set(s.window.subarray(s.w_size, s.w_size + s.strstart), 0);
        if (s.matches < 2) {
          s.matches++;
        }
        have += s.w_size;
        if (s.insert > s.strstart) {
          s.insert = s.strstart;
        }
      }
      if (have > s.strm.avail_in) {
        have = s.strm.avail_in;
      }
      if (have) {
        read_buf(s.strm, s.window, s.strstart, have);
        s.strstart += have;
        s.insert += have > s.w_size - s.insert ? s.w_size - s.insert : have;
      }
      if (s.high_water < s.strstart) {
        s.high_water = s.strstart;
      }
      have = s.bi_valid + 42 >> 3;
      have = s.pending_buf_size - have > 65535 ? 65535 : s.pending_buf_size - have;
      min_block = have > s.w_size ? s.w_size : have;
      left = s.strstart - s.block_start;
      if (left >= min_block || (left || flush === Z_FINISH) && flush !== Z_NO_FLUSH && s.strm.avail_in === 0 && left <= have) {
        len = left > have ? have : left;
        last = flush === Z_FINISH && s.strm.avail_in === 0 && len === left ? 1 : 0;
        _tr_stored_block(s, s.block_start, len, last);
        s.block_start += len;
        flush_pending(s.strm);
      }
      return last ? BS_FINISH_STARTED : BS_NEED_MORE;
    };
    var deflate_fast = (s, flush) => {
      let hash_head;
      let bflush;
      for (; ; ) {
        if (s.lookahead < MIN_LOOKAHEAD) {
          fill_window(s);
          if (s.lookahead < MIN_LOOKAHEAD && flush === Z_NO_FLUSH) {
            return BS_NEED_MORE;
          }
          if (s.lookahead === 0) {
            break;
          }
        }
        hash_head = 0;
        …197152 tokens truncated…&& (e3.metadata.Unicode.encoding = n3, e3.encoding = n3.codePages[0]);
      }]);
    })(C.API), /**
     * @license
     * Licensed under the MIT License.
     * http://opensource.org/licenses/mit-license
     */
    (function(t2) {
      var e2 = function(t3) {
        for (var e3 = t3.length, r2 = new Uint8Array(e3), n2 = 0; n2 < e3; n2++) r2[n2] = t3.charCodeAt(n2);
        return r2;
      };
      t2.API.events.push(["addFont", function(r2) {
        var n2 = void 0, a2 = r2.font, o2 = r2.instance;
        if (!a2.isStandardFont) {
          if (void 0 === o2) throw new Error("Font does not exist in vFS, import fonts or remove declaration doc.addFont('" + a2.postScriptName + "').");
          if ("string" != typeof (n2 = false === o2.existsFileInVFS(a2.postScriptName) ? o2.loadFile(a2.postScriptName) : o2.getFileFromVFS(a2.postScriptName))) throw new Error("Font is not stored as string-data in vFS, import fonts or remove declaration doc.addFont('" + a2.postScriptName + "').");
          !(function(r3, n3) {
            n3 = /^\x00\x01\x00\x00/.test(n3) ? e2(n3) : e2(i(n3)), r3.metadata = t2.API.TTFFont.open(n3), r3.metadata.Unicode = r3.metadata.Unicode || { encoding: {}, kerning: {}, widths: [] }, r3.metadata.glyIdsUsed = [0];
          })(a2, n2);
        }
      }]);
    })(C), C.API.addSvgAsImage = function(t2, e2, n2, i2, a2, o2, c2, u2) {
      if (isNaN(e2) || isNaN(n2)) throw s.error("jsPDF.addSvgAsImage: Invalid coordinates", arguments), new Error("Invalid coordinates passed to jsPDF.addSvgAsImage");
      if (isNaN(i2) || isNaN(a2)) throw s.error("jsPDF.addSvgAsImage: Invalid measurements", arguments), new Error("Invalid measurements (width and/or height) passed to jsPDF.addSvgAsImage");
      var l2 = document.createElement("canvas");
      l2.width = i2, l2.height = a2;
      var h2 = l2.getContext("2d");
      h2.fillStyle = "#fff", h2.fillRect(0, 0, l2.width, l2.height);
      var f2 = { ignoreMouse: true, ignoreAnimation: true, ignoreDimensions: true }, d2 = this;
      return (r.canvg ? Promise.resolve(r.canvg) : "object" == typeof exports2 && "undefined" != typeof module2 ? new Promise(function(t3, e3) {
        try {
          t3(require_lib2());
        } catch (r2) {
          e3(r2);
        }
      }) : "function" == typeof define && define.amd ? new Promise(function(t3, e3) {
        try {
          require(["canvg"], t3);
        } catch (r2) {
          e3(r2);
        }
      }) : Promise.reject(new Error("Could not load canvg"))).catch(function(t3) {
        return Promise.reject(new Error("Could not load canvg: " + t3));
      }).then(function(t3) {
        return t3.default ? t3.default : t3;
      }).then(function(e3) {
        return e3.fromString(h2, t2, f2);
      }, function() {
        return Promise.reject(new Error("Could not load canvg."));
      }).then(function(t3) {
        return t3.render(f2);
      }).then(function() {
        d2.addImage(l2.toDataURL("image/jpeg", 1), e2, n2, i2, a2, c2, u2);
      });
    }, C.API.putTotalPages = function(t2) {
      var e2, r2 = 0;
      parseInt(this.internal.getFont().id.substr(1), 10) < 15 ? (e2 = new RegExp(t2, "g"), r2 = this.internal.getNumberOfPages()) : (e2 = new RegExp(this.pdfEscape16(t2, this.internal.getFont()), "g"), r2 = this.pdfEscape16(this.internal.getNumberOfPages() + "", this.internal.getFont()));
      for (var n2 = 1; n2 <= this.internal.getNumberOfPages(); n2++) for (var i2 = 0; i2 < this.internal.pages[n2].length; i2++) this.internal.pages[n2][i2] = this.internal.pages[n2][i2].replace(e2, r2);
      return this;
    }, C.API.viewerPreferences = function(t2, e2) {
      var r2;
      t2 = t2 || {}, e2 = e2 || false;
      var n2, i2, a2, o2 = { HideToolbar: { defaultValue: false, value: false, type: "boolean", explicitSet: false, valueSet: [true, false], pdfVersion: 1.3 }, HideMenubar: { defaultValue: false, value: false, type: "boolean", explicitSet: false, valueSet: [true, false], pdfVersion: 1.3 }, HideWindowUI: { defaultValue: false, value: false, type: "boolean", explicitSet: false, valueSet: [true, false], pdfVersion: 1.3 }, FitWindow: { defaultValue: false, value: false, type: "boolean", explicitSet: false, valueSet: [true, false], pdfVersion: 1.3 }, CenterWindow: { defaultValue: false, value: false, type: "boolean", explicitSet: false, valueSet: [true, false], pdfVersion: 1.3 }, DisplayDocTitle: { defaultValue: false, value: false, type: "boolean", explicitSet: false, valueSet: [true, false], pdfVersion: 1.4 }, NonFullScreenPageMode: { defaultValue: "UseNone", value: "UseNone", type: "name", explicitSet: false, valueSet: ["UseNone", "UseOutlines", "UseThumbs", "UseOC"], pdfVersion: 1.3 }, Direction: { defaultValue: "L2R", value: "L2R", type: "name", explicitSet: false, valueSet: ["L2R", "R2L"], pdfVersion: 1.3 }, ViewArea: { defaultValue: "CropBox", value: "CropBox", type: "name", explicitSet: false, valueSet: ["MediaBox", "CropBox", "TrimBox", "BleedBox", "ArtBox"], pdfVersion: 1.4 }, ViewClip: { defaultValue: "CropBox", value: "CropBox", type: "name", explicitSet: false, valueSet: ["MediaBox", "CropBox", "TrimBox", "BleedBox", "ArtBox"], pdfVersion: 1.4 }, PrintArea: { defaultValue: "CropBox", value: "CropBox", type: "name", explicitSet: false, valueSet: ["MediaBox", "CropBox", "TrimBox", "BleedBox", "ArtBox"], pdfVersion: 1.4 }, PrintClip: { defaultValue: "CropBox", value: "CropBox", type: "name", explicitSet: false, valueSet: ["MediaBox", "CropBox", "TrimBox", "BleedBox", "ArtBox"], pdfVersion: 1.4 }, PrintScaling: { defaultValue: "AppDefault", value: "AppDefault", type: "name", explicitSet: false, valueSet: ["AppDefault", "None"], pdfVersion: 1.6 }, Duplex: { defaultValue: "", value: "none", type: "name", explicitSet: false, valueSet: ["Simplex", "DuplexFlipShortEdge", "DuplexFlipLongEdge", "none"], pdfVersion: 1.7 }, PickTrayByPDFSize: { defaultValue: false, value: false, type: "boolean", explicitSet: false, valueSet: [true, false], pdfVersion: 1.7 }, PrintPageRange: { defaultValue: "", value: "", type: "array", explicitSet: false, valueSet: null, pdfVersion: 1.7 }, NumCopies: { defaultValue: 1, value: 1, type: "integer", explicitSet: false, valueSet: null, pdfVersion: 1.7 } }, s2 = Object.keys(o2), c2 = [], u2 = 0, l2 = 0, h2 = 0;
      function f2(t3, e3) {
        var r3, n3 = false;
        for (r3 = 0; r3 < t3.length; r3 += 1) t3[r3] === e3 && (n3 = true);
        return n3;
      }
      if (void 0 === this.internal.viewerpreferences && (this.internal.viewerpreferences = {}, this.internal.viewerpreferences.configuration = JSON.parse(JSON.stringify(o2)), this.internal.viewerpreferences.isSubscribed = false), r2 = this.internal.viewerpreferences.configuration, "reset" === t2 || true === e2) {
        var d2 = s2.length;
        for (h2 = 0; h2 < d2; h2 += 1) r2[s2[h2]].value = r2[s2[h2]].defaultValue, r2[s2[h2]].explicitSet = false;
      }
      if ("object" == typeof t2) {
        for (i2 in t2) if (a2 = t2[i2], f2(s2, i2) && void 0 !== a2) {
          if ("boolean" === r2[i2].type && "boolean" == typeof a2) r2[i2].value = a2;
          else if ("name" === r2[i2].type && f2(r2[i2].valueSet, a2)) r2[i2].value = a2;
          else if ("integer" === r2[i2].type && Number.isInteger(a2)) r2[i2].value = a2;
          else if ("array" === r2[i2].type) {
            for (u2 = 0; u2 < a2.length; u2 += 1) if (n2 = true, 1 === a2[u2].length && "number" == typeof a2[u2][0]) c2.push(String(a2[u2] - 1));
            else if (a2[u2].length > 1) {
              for (l2 = 0; l2 < a2[u2].length; l2 += 1) "number" != typeof a2[u2][l2] && (n2 = false);
              true === n2 && c2.push([a2[u2][0] - 1, a2[u2][1] - 1].join(" "));
            }
            r2[i2].value = "[" + c2.join(" ") + "]";
          } else r2[i2].value = r2[i2].defaultValue;
          r2[i2].explicitSet = true;
        }
      }
      return false === this.internal.viewerpreferences.isSubscribed && (this.internal.events.subscribe("putCatalog", function() {
        var t3, e3 = [];
        for (t3 in r2) true === r2[t3].explicitSet && ("name" === r2[t3].type ? e3.push("/" + t3 + " /" + r2[t3].value) : e3.push("/" + t3 + " " + r2[t3].value));
        0 !== e3.length && this.internal.write("/ViewerPreferences\n<<\n" + e3.join("\n") + "\n>>");
      }), this.internal.viewerpreferences.isSubscribed = true), this.internal.viewerpreferences.configuration = r2, this;
    }, C.API.addMetadata = function(t2, e2) {
      return void 0 === this.internal.__metadata__ && (this.internal.__metadata__ = { metadata: t2, namespaceUri: e2 ?? "http://jspdf.default.namespaceuri/", rawXml: "boolean" == typeof e2 && e2 }, this.internal.events.subscribe("putCatalog", ne), this.internal.events.subscribe("postPutResources", re)), this;
    }, (function(t2) {
      var e2 = t2.API, r2 = e2.pdfEscape16 = function(t3, e3) {
        for (var r3, n3 = e3.metadata.Unicode.widths, i3 = ["", "0", "00", "000", "0000"], a2 = [""], o2 = 0, s2 = t3.length; o2 < s2; ++o2) {
          if (r3 = e3.metadata.characterToGlyph(t3.charCodeAt(o2)), e3.metadata.glyIdsUsed.push(r3), e3.metadata.toUnicode[r3] = t3.charCodeAt(o2), -1 == n3.indexOf(r3) && (n3.push(r3), n3.push([parseInt(e3.metadata.widthOfGlyph(r3), 10)])), "0" == r3) return a2.join("");
          r3 = r3.toString(16), a2.push(i3[4 - r3.length], r3);
        }
        return a2.join("");
      }, n2 = function(t3) {
        var e3, r3, n3, i3, a2, o2, s2;
        for (a2 = "/CIDInit /ProcSet findresource begin\n12 dict begin\nbegincmap\n/CIDSystemInfo <<\n  /Registry (Adobe)\n  /Ordering (UCS)\n  /Supplement 0\n>> def\n/CMapName /Adobe-Identity-UCS def\n/CMapType 2 def\n1 begincodespacerange\n<0000><ffff>\nendcodespacerange", n3 = [], o2 = 0, s2 = (r3 = Object.keys(t3).sort(function(t4, e4) {
          return t4 - e4;
        })).length; o2 < s2; o2++) e3 = r3[o2], n3.length >= 100 && (a2 += "\n" + n3.length + " beginbfchar\n" + n3.join("\n") + "\nendbfchar", n3 = []), void 0 !== t3[e3] && null !== t3[e3] && "function" == typeof t3[e3].toString && (i3 = ("0000" + t3[e3].toString(16)).slice(-4), e3 = ("0000" + (+e3).toString(16)).slice(-4), n3.push("<" + e3 + "><" + i3 + ">"));
        return n3.length && (a2 += "\n" + n3.length + " beginbfchar\n" + n3.join("\n") + "\nendbfchar\n"), a2 + "endcmap\nCMapName currentdict /CMap defineresource pop\nend\nend";
      };
      e2.events.push(["putFont", function(e3) {
        !(function(e4) {
          var r3 = e4.font, i3 = e4.out, a2 = e4.newObject, o2 = e4.putStream;
          if (r3.metadata instanceof t2.API.TTFFont && "Identity-H" === r3.encoding) {
            for (var s2 = r3.metadata.Unicode.widths, c2 = r3.metadata.subset.encode(r3.metadata.glyIdsUsed, 1), u2 = "", l2 = 0; l2 < c2.length; l2++) u2 += String.fromCharCode(c2[l2]);
            var h2 = a2();
            o2({ data: u2, addLength1: true, objectId: h2 }), i3("endobj");
            var f2 = a2();
            o2({ data: n2(r3.metadata.toUnicode), addLength1: true, objectId: f2 }), i3("endobj");
            var d2 = a2();
            i3("<<"), i3("/Type /FontDescriptor"), i3("/FontName /" + S(r3.fontName)), i3("/FontFile2 " + h2 + " 0 R"), i3("/FontBBox " + t2.API.PDFObject.convert(r3.metadata.bbox)), i3("/Flags " + r3.metadata.flags), i3("/StemV " + r3.metadata.stemV), i3("/ItalicAngle " + r3.metadata.italicAngle), i3("/Ascent " + r3.metadata.ascender), i3("/Descent " + r3.metadata.decender), i3("/CapHeight " + r3.metadata.capHeight), i3(">>"), i3("endobj");
            var p2 = a2();
            i3("<<"), i3("/Type /Font"), i3("/BaseFont /" + S(r3.fontName)), i3("/FontDescriptor " + d2 + " 0 R"), i3("/W " + t2.API.PDFObject.convert(s2)), i3("/CIDToGIDMap /Identity"), i3("/DW 1000"), i3("/Subtype /CIDFontType2"), i3("/CIDSystemInfo"), i3("<<"), i3("/Supplement 0"), i3("/Registry (Adobe)"), i3("/Ordering (" + r3.encoding + ")"), i3(">>"), i3(">>"), i3("endobj"), r3.objectNumber = a2(), i3("<<"), i3("/Type /Font"), i3("/Subtype /Type0"), i3("/ToUnicode " + f2 + " 0 R"), i3("/BaseFont /" + S(r3.fontName)), i3("/Encoding /" + r3.encoding), i3("/DescendantFonts [" + p2 + " 0 R]"), i3(">>"), i3("endobj"), r3.isAlreadyPutted = true;
          }
        })(e3);
      }]), e2.events.push(["putFont", function(e3) {
        !(function(e4) {
          var r3 = e4.font, i3 = e4.out, a2 = e4.newObject, o2 = e4.putStream;
          if (r3.metadata instanceof t2.API.TTFFont && "WinAnsiEncoding" === r3.encoding) {
            for (var s2 = r3.metadata.rawData, c2 = "", u2 = 0; u2 < s2.length; u2++) c2 += String.fromCharCode(s2[u2]);
            var l2 = a2();
            o2({ data: c2, addLength1: true, objectId: l2 }), i3("endobj");
            var h2 = a2();
            o2({ data: n2(r3.metadata.toUnicode), addLength1: true, objectId: h2 }), i3("endobj");
            var f2 = a2();
            i3("<<"), i3("/Descent " + r3.metadata.decender), i3("/CapHeight " + r3.metadata.capHeight), i3("/StemV " + r3.metadata.stemV), i3("/Type /FontDescriptor"), i3("/FontFile2 " + l2 + " 0 R"), i3("/Flags 96"), i3("/FontBBox " + t2.API.PDFObject.convert(r3.metadata.bbox)), i3("/FontName /" + S(r3.fontName)), i3("/ItalicAngle " + r3.metadata.italicAngle), i3("/Ascent " + r3.metadata.ascender), i3(">>"), i3("endobj"), r3.objectNumber = a2();
            for (var d2 = 0; d2 < r3.metadata.hmtx.widths.length; d2++) r3.metadata.hmtx.widths[d2] = parseInt(r3.metadata.hmtx.widths[d2] * (1e3 / r3.metadata.head.unitsPerEm));
            i3("<</Subtype/TrueType/Type/Font/ToUnicode " + h2 + " 0 R/BaseFont/" + S(r3.fontName) + "/FontDescriptor " + f2 + " 0 R/Encoding/" + r3.encoding + " /FirstChar 29 /LastChar 255 /Widths " + t2.API.PDFObject.convert(r3.metadata.hmtx.widths) + ">>"), i3("endobj"), r3.isAlreadyPutted = true;
          }
        })(e3);
      }]);
      var i2 = function(t3) {
        var e3, n3 = t3.text || "", i3 = t3.x, a2 = t3.y, o2 = t3.options || {}, s2 = t3.mutex || {}, c2 = s2.pdfEscape, u2 = s2.activeFontKey, l2 = s2.fonts, h2 = u2, f2 = "", d2 = 0, p2 = "", g2 = l2[h2].encoding;
        if ("Identity-H" !== l2[h2].encoding) return { text: n3, x: i3, y: a2, options: o2, mutex: s2 };
        for (p2 = n3, h2 = u2, Array.isArray(n3) && (p2 = n3[0]), d2 = 0; d2 < p2.length; d2 += 1) l2[h2].metadata.hasOwnProperty("cmap") && (e3 = l2[h2].metadata.cmap.unicode.codeMap[p2[d2].charCodeAt(0)]), e3 || p2[d2].charCodeAt(0) < 256 && l2[h2].metadata.hasOwnProperty("Unicode") ? f2 += p2[d2] : f2 += "";
        var m2 = "";
        return parseInt(h2.slice(1)) < 14 || "WinAnsiEncoding" === g2 ? m2 = c2(f2, h2).split("").map(function(t4) {
          return t4.charCodeAt(0).toString(16);
        }).join("") : "Identity-H" === g2 && (m2 = r2(f2, l2[h2])), s2.isHex = true, { text: m2, x: i3, y: a2, options: o2, mutex: s2 };
      };
      e2.events.push(["postProcessText", function(t3) {
        var e3 = t3.text || "", r3 = [], n3 = { text: e3, x: t3.x, y: t3.y, options: t3.options, mutex: t3.mutex };
        if (Array.isArray(e3)) {
          var a2 = 0;
          for (a2 = 0; a2 < e3.length; a2 += 1) Array.isArray(e3[a2]) && 3 === e3[a2].length ? r3.push([i2(Object.assign({}, n3, { text: e3[a2][0] })).text, e3[a2][1], e3[a2][2]]) : r3.push(i2(Object.assign({}, n3, { text: e3[a2] })).text);
          t3.text = r3;
        } else t3.text = i2(Object.assign({}, n3, { text: e3 })).text;
      }]);
    })(C), /**
     * @license
     * jsPDF virtual FileSystem functionality
     *
     * Licensed under the MIT License.
     * http://opensource.org/licenses/mit-license
     */
    (function(t2) {
      var e2 = function() {
        return void 0 === this.internal.vFS && (this.internal.vFS = {}), true;
      };
      t2.existsFileInVFS = function(t3) {
        return e2.call(this), void 0 !== this.internal.vFS[t3];
      }, t2.addFileToVFS = function(t3, r2) {
        return e2.call(this), this.internal.vFS[t3] = r2, this;
      }, t2.getFileFromVFS = function(t3) {
        return e2.call(this), void 0 !== this.internal.vFS[t3] ? this.internal.vFS[t3] : null;
      };
    })(C.API), /**
     * @license
     * Unicode Bidi Engine based on the work of Alex Shensis (@asthensis)
     * MIT License
     */
    (function(t2) {
      t2.__bidiEngine__ = t2.prototype.__bidiEngine__ = function(t3) {
        var r3, n2, i2, a2, o2, s2, c2, u2 = e2, l2 = [[0, 3, 0, 1, 0, 0, 0], [0, 3, 0, 1, 2, 2, 0], [0, 3, 0, 17, 2, 0, 1], [0, 3, 5, 5, 4, 1, 0], [0, 3, 21, 21, 4, 0, 1], [0, 3, 5, 5, 4, 2, 0]], h2 = [[2, 0, 1, 1, 0, 1, 0], [2, 0, 1, 1, 0, 2, 0], [2, 0, 2, 1, 3, 2, 0], [2, 0, 2, 33, 3, 1, 1]], f2 = { L: 0, R: 1, EN: 2, AN: 3, N: 4, B: 5, S: 6 }, d2 = { 0: 0, 5: 1, 6: 2, 7: 3, 32: 4, 251: 5, 254: 6, 255: 7 }, p2 = ["(", ")", "(", "<", ">", "<", "[", "]", "[", "{", "}", "{", "\xAB", "\xBB", "\xAB", "\u2039", "\u203A", "\u2039", "\u2045", "\u2046", "\u2045", "\u207D", "\u207E", "\u207D", "\u208D", "\u208E", "\u208D", "\u2264", "\u2265", "\u2264", "\u2329", "\u232A", "\u2329", "\uFE59", "\uFE5A", "\uFE59", "\uFE5B", "\uFE5C", "\uFE5B", "\uFE5D", "\uFE5E", "\uFE5D", "\uFE64", "\uFE65", "\uFE64"], g2 = new RegExp(/^([1-4|9]|1[0-9]|2[0-9]|3[0168]|4[04589]|5[012]|7[78]|159|16[0-9]|17[0-2]|21[569]|22[03489]|250)$/), m2 = false, v2 = 0;
        this.__bidiEngine__ = {};
        var b2 = function(t4) {
          var e3 = t4.charCodeAt(), r4 = e3 >> 8, n3 = d2[r4];
          return void 0 !== n3 ? u2[256 * n3 + (255 & e3)] : 252 === r4 || 253 === r4 ? "AL" : g2.test(r4) ? "L" : 8 === r4 ? "R" : "N";
        }, y2 = function(t4) {
          for (var e3, r4 = 0; r4 < t4.length; r4++) {
            if ("L" === (e3 = b2(t4.charAt(r4)))) return false;
            if ("R" === e3) return true;
          }
          return false;
        }, w2 = function(t4, e3, o3, s3) {
          var c3, u3, l3, h3, f3 = e3[s3];
          switch (f3) {
            case "L":
            case "R":
            case "LRE":
            case "RLE":
            case "LRO":
            case "RLO":
            case "PDF":
              m2 = false;
              break;
            case "N":
            case "AN":
              break;
            case "EN":
              m2 && (f3 = "AN");
              break;
            case "AL":
              m2 = true, f3 = "R";
              break;
            case "WS":
            case "BN":
              f3 = "N";
              break;
            case "CS":
              s3 < 1 || s3 + 1 >= e3.length || "EN" !== (c3 = o3[s3 - 1]) && "AN" !== c3 || "EN" !== (u3 = e3[s3 + 1]) && "AN" !== u3 ? f3 = "N" : m2 && (u3 = "AN"), f3 = u3 === c3 ? u3 : "N";
              break;
            case "ES":
              f3 = "EN" === (c3 = s3 > 0 ? o3[s3 - 1] : "B") && s3 + 1 < e3.length && "EN" === e3[s3 + 1] ? "EN" : "N";
              break;
            case "ET":
              if (s3 > 0 && "EN" === o3[s3 - 1]) {
                f3 = "EN";
                break;
              }
              if (m2) {
                f3 = "N";
                break;
              }
              for (l3 = s3 + 1, h3 = e3.length; l3 < h3 && "ET" === e3[l3]; ) l3++;
              f3 = l3 < h3 && "EN" === e3[l3] ? "EN" : "N";
              break;
            case "NSM":
              if (i2 && !a2) {
                for (h3 = e3.length, l3 = s3 + 1; l3 < h3 && "NSM" === e3[l3]; ) l3++;
                if (l3 < h3) {
                  var d3 = t4[s3], p3 = d3 >= 1425 && d3 <= 2303 || 64286 === d3;
                  if (c3 = e3[l3], p3 && ("R" === c3 || "AL" === c3)) {
                    f3 = "R";
                    break;
                  }
                }
              }
              f3 = s3 < 1 || "B" === (c3 = e3[s3 - 1]) ? "N" : o3[s3 - 1];
              break;
            case "B":
              m2 = false, r3 = true, f3 = v2;
              break;
            case "S":
              n2 = true, f3 = "N";
          }
          return f3;
        }, N2 = function(t4, e3, r4) {
          var n3 = t4.split("");
          return r4 && L2(n3, r4, { hiLevel: v2 }), n3.reverse(), e3 && e3.reverse(), n3.join("");
        }, L2 = function(t4, e3, i3) {
          var a3, o3, s3, c3, u3, d3 = -1, p3 = t4.length, g3 = 0, y3 = [], N3 = v2 ? h2 : l2, L3 = [];
          for (m2 = false, r3 = false, n2 = false, o3 = 0; o3 < p3; o3++) L3[o3] = b2(t4[o3]);
          for (s3 = 0; s3 < p3; s3++) {
            if (u3 = g3, y3[s3] = w2(t4, L3, y3, s3), a3 = 240 & (g3 = N3[u3][f2[y3[s3]]]), g3 &= 15, e3[s3] = c3 = N3[g3][5], a3 > 0) if (16 === a3) {
              for (o3 = d3; o3 < s3; o3++) e3[o3] = 1;
              d3 = -1;
            } else d3 = -1;
            if (N3[g3][6]) -1 === d3 && (d3 = s3);
            else if (d3 > -1) {
              for (o3 = d3; o3 < s3; o3++) e3[o3] = c3;
              d3 = -1;
            }
            "B" === L3[s3] && (e3[s3] = 0), i3.hiLevel |= c3;
          }
          n2 && (function(t5, e4, r4) {
            for (var n3 = 0; n3 < r4; n3++) if ("S" === t5[n3]) {
              e4[n3] = v2;
              for (var i4 = n3 - 1; i4 >= 0 && "WS" === t5[i4]; i4--) e4[i4] = v2;
            }
          })(L3, e3, p3);
        }, x2 = function(t4, e3, n3, i3, a3) {
          if (!(a3.hiLevel < t4)) {
            if (1 === t4 && 1 === v2 && !r3) return e3.reverse(), void (n3 && n3.reverse());
            for (var o3, s3, c3, u3, l3 = e3.length, h3 = 0; h3 < l3; ) {
              if (i3[h3] >= t4) {
                for (c3 = h3 + 1; c3 < l3 && i3[c3] >= t4; ) c3++;
                for (u3 = h3, s3 = c3 - 1; u3 < s3; u3++, s3--) o3 = e3[u3], e3[u3] = e3[s3], e3[s3] = o3, n3 && (o3 = n3[u3], n3[u3] = n3[s3], n3[s3] = o3);
                h3 = c3;
              }
              h3++;
            }
          }
        }, A2 = function(t4, e3, r4) {
          var n3 = t4.split(""), i3 = { hiLevel: v2 };
          return r4 || (r4 = []), L2(n3, r4, i3), (function(t5, e4, r5) {
            if (0 !== r5.hiLevel && c2) for (var n4, i4 = 0; i4 < t5.length; i4++) 1 === e4[i4] && (n4 = p2.indexOf(t5[i4])) >= 0 && (t5[i4] = p2[n4 + 1]);
          })(n3, r4, i3), x2(2, n3, e3, r4, i3), x2(1, n3, e3, r4, i3), n3.join("");
        };
        return this.__bidiEngine__.doBidiReorder = function(t4, e3, r4) {
          if ((function(t5, e4) {
            if (e4) for (var r5 = 0; r5 < t5.length; r5++) e4[r5] = r5;
            void 0 === a2 && (a2 = y2(t5)), void 0 === s2 && (s2 = y2(t5));
          })(t4, e3), i2 || !o2 || s2) if (i2 && o2 && a2 ^ s2) v2 = a2 ? 1 : 0, t4 = N2(t4, e3, r4);
          else if (!i2 && o2 && s2) v2 = a2 ? 1 : 0, t4 = A2(t4, e3, r4), t4 = N2(t4, e3);
          else if (!i2 || a2 || o2 || s2) {
            if (i2 && !o2 && a2 ^ s2) t4 = N2(t4, e3), a2 ? (v2 = 0, t4 = A2(t4, e3, r4)) : (v2 = 1, t4 = A2(t4, e3, r4), t4 = N2(t4, e3));
            else if (i2 && a2 && !o2 && s2) v2 = 1, t4 = A2(t4, e3, r4), t4 = N2(t4, e3);
            else if (!i2 && !o2 && a2 ^ s2) {
              var n3 = c2;
              a2 ? (v2 = 1, t4 = A2(t4, e3, r4), v2 = 0, c2 = false, t4 = A2(t4, e3, r4), c2 = n3) : (v2 = 0, t4 = A2(t4, e3, r4), t4 = N2(t4, e3), v2 = 1, c2 = false, t4 = A2(t4, e3, r4), c2 = n3, t4 = N2(t4, e3));
            }
          } else v2 = 0, t4 = A2(t4, e3, r4);
          else v2 = a2 ? 1 : 0, t4 = A2(t4, e3, r4);
          return t4;
        }, this.__bidiEngine__.setOptions = function(t4) {
          t4 && (i2 = t4.isInputVisual, o2 = t4.isOutputVisual, a2 = t4.isInputRtl, s2 = t4.isOutputRtl, c2 = t4.isSymmetricSwapping);
        }, this.__bidiEngine__.setOptions(t3), this.__bidiEngine__;
      };
      var e2 = ["BN", "BN", "BN", "BN", "BN", "BN", "BN", "BN", "BN", "S", "B", "S", "WS", "B", "BN", "BN", "BN", "BN", "BN", "BN", "BN", "BN", "BN", "BN", "BN", "BN", "BN", "BN", "B", "B", "B", "S", "WS", "N", "N", "ET", "ET", "ET", "N", "N", "N", "N", "N", "ES", "CS", "ES", "CS", "CS", "EN", "EN", "EN", "EN", "EN", "EN", "EN", "EN", "EN", "EN", "CS", "N", "N", "N", "N", "N", "N", "L", "L", "L", "L", "L", "L", "L", "L", "L", "L", "L", "L", "L", "L", "L", "L", "L", "L", "L", "L", "L", "L", "L", "L", "L", "L", "N", "N", "N", "N", "N", "N", "L", "L", "L", "L", "L", "L", "L", "L", "L", "L", "L", "L", "L", "L", "L", "L", "L", "L", "L", "L", "L", "L", "L", "L", "L", "L", "N", "N", "N", "N", "BN", "BN", "BN", "BN", "BN", "BN", "B", "BN", "BN", "BN", "BN", "BN", "BN", "BN", "BN", "BN", "BN", "BN", "BN", "BN", "BN", "BN", "BN", "BN", "BN", "BN", "BN", "BN", "BN", "BN", "BN", "BN", "BN", "CS", "N", "ET", "ET", "ET", "ET", "N", "N", "N", "N", "L", "N", "N", "BN", "N", "N", "ET", "ET", "EN", "EN", "N", "L", "N", "N", "N", "EN", "L", "N", "N", "N", "N", "N", "L", "L", "L", "L", "L", "L", "L", "L", "L", "L", "L", "L", "L", "L", "L", "L", "L", "L", "L", "L", "L", "L", "L", "N", "L", "L", "L", "L", "L", "L", "L", "L", "L", "L", "L", "L", "L", "L", "L", "L", "L", "L", "L", "L", "L", "L", "L", "L", "L", "L", "L", "L", "L", "L", "L", "N", "L", "L", "L", "L", "L", "L", "L", "L", "L", "L", "L", "L", "L", "L", "L", "L", "L", "L", "L", "L", "L", "L", "L", "L", "L", "L", "L", "L", "L", "L", "L", "L", "L", "L", "L", "L", "L", "L", "L", "L", "L", "L", "L", "L", "L", "L", "L", "L", "L", "L", "L", "L", "L", "L", "L", "L", "N", "L", "L", "L", "L", "L", "L", "L", "L", "L", "L", "L", "L", "L", "L", "L", "L", "L", "L", "L", "L", "L", "L", "L", "L", "L", "L", "L", "L", "L", "L", "L", "L", "L", "L", "L", "L", "L", "L", "N", "N", "L", "L", "L", "L", "L", "L", "L", "N", "L", "L", "L", "L", "L", "L", "L", "L", "L", "L", "L", "L", "L", "L", "L", "L", "L", "L", "L", "L", "L", "L", "L", "L", "L", "L", "L", "L", "L", "L", "L", "L", "L", "L", "L", "L", "L", "L", "L", "N", "L", "N", "N", "N", "N", "N", "ET", "N", "NSM", "NSM", "NSM", "NSM", "NSM", "NSM", "NSM", "NSM", "NSM", "NSM", "NSM", "NSM", "NSM", "NSM", "NSM", "NSM", "NSM", "NSM", "NSM", "NSM", "NSM", "NSM", "NSM", "NSM", "NSM", "NSM", "NSM", "NSM", "NSM", "NSM", "NSM", "NSM", "NSM", "NSM", "NSM", "NSM", "NSM", "NSM", "NSM", "NSM", "NSM", "NSM", "NSM", "NSM", "NSM", "R", "NSM", "R", "NSM", "NSM", "R", "NSM", "NSM", "R", "NSM", "N", "N", "N", "N", "N", "N", "N", "N", "R", "R", "R", "R", "R", "R", "R", "R", "R", "R", "R", "R", "R", "R", "R", "R", "R", "R", "R", "R", "R", "R", "R", "R", "R", "R", "R", "N", "N", "N", "N", "N", "R", "R", "R", "R", "R", "N", "N", "N", "N", "N", "N", "N", "N", "N", "N", "N", "AN", "AN", "AN", "AN", "AN", "AN", "N", "N", "AL", "ET", "ET", "AL", "CS", "AL", "N", "N", "NSM", "NSM", "NSM", "NSM", "NSM", "NSM", "NSM", "NSM", "NSM", "NSM", "NSM", "AL", "AL", "N", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "NSM", "NSM", "NSM", "NSM", "NSM", "NSM", "NSM", "NSM", "NSM", "NSM", "NSM", "NSM", "NSM", "NSM", "NSM", "NSM", "NSM", "NSM", "NSM", "NSM", "NSM", "AN", "AN", "AN", "AN", "AN", "AN", "AN", "AN", "AN", "AN", "ET", "AN", "AN", "AL", "AL", "AL", "NSM", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "NSM", "NSM", "NSM", "NSM", "NSM", "NSM", "NSM", "AN", "N", "NSM", "NSM", "NSM", "NSM", "NSM", "NSM", "AL", "AL", "NSM", "NSM", "N", "NSM", "NSM", "NSM", "NSM", "AL", "AL", "EN", "EN", "EN", "EN", "EN", "EN", "EN", "EN", "EN", "EN", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "N", "AL", "AL", "NSM", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "NSM", "NSM", "NSM", "NSM", "NSM", "NSM", "NSM", "NSM", "NSM", "NSM", "NSM", "NSM", "NSM", "NSM", "NSM", "NSM", "NSM", "NSM", "NSM", "NSM", "NSM", "NSM", "NSM", "NSM", "NSM", "NSM", "NSM", "N", "N", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "NSM", "NSM", "NSM", "NSM", "NSM", "NSM", "NSM", "NSM", "NSM", "NSM", "NSM", "AL", "N", "N", "N", "N", "N", "N", "N", "N", "N", "N", "N", "N", "N", "N", "R", "R", "R", "R", "R", "R", "R", "R", "R", "R", "R", "R", "R", "R", "R", "R", "R", "R", "R", "R", "R", "R", "R", "R", "R", "R", "R", "R", "R", "R", "R", "R", "R", "R", "R", "R", "R", "R", "R", "R", "R", "R", "R", "NSM", "NSM", "NSM", "NSM", "NSM", "NSM", "NSM", "NSM", "NSM", "R", "R", "N", "N", "N", "N", "R", "N", "N", "N", "N", "N", "WS", "WS", "WS", "WS", "WS", "WS", "WS", "WS", "WS", "WS", "WS", "BN", "BN", "BN", "L", "R", "N", "N", "N", "N", "N", "N", "N", "N", "N", "N", "N", "N", "N", "N", "N", "N", "N", "N", "N", "N", "N", "N", "N", "N", "WS", "B", "LRE", "RLE", "PDF", "LRO", "RLO", "CS", "ET", "ET", "ET", "ET", "ET", "N", "N", "N", "N", "N", "N", "N", "N", "N", "N", "N", "N", "N", "N", "N", "CS", "N", "N", "N", "N", "N", "N", "N", "N", "N", "N", "N", "N", "N", "N", "N", "N", "N", "N", "N", "N", "N", "N", "N", "N", "N", "N", "WS", "BN", "BN", "BN", "BN", "BN", "N", "LRI", "RLI", "FSI", "PDI", "BN", "BN", "BN", "BN", "BN", "BN", "EN", "L", "N", "N", "EN", "EN", "EN", "EN", "EN", "EN", "ES", "ES", "N", "N", "N", "L", "EN", "EN", "EN", "EN", "EN", "EN", "EN", "EN", "EN", "EN", "ES", "ES", "N", "N", "N", "N", "L", "L", "L", "L", "L", "L", "L", "L", "L", "L", "L", "L", "L", "N", "N", "N", "ET", "ET", "ET", "ET", "ET", "ET", "ET", "ET", "ET", "ET", "ET", "ET", "ET", "ET", "ET", "ET", "ET", "ET", "ET", "ET", "ET", "ET", "ET", "ET", "ET", "ET", "ET", "ET", "ET", "ET", "ET", "N", "N", "N", "N", "N", "N", "N", "N", "N", "N", "N", "N", "N", "N", "N", "N", "N", "NSM", "NSM", "NSM", "NSM", "NSM", "NSM", "NSM", "NSM", "NSM", "NSM", "NSM", "NSM", "NSM", "NSM", "NSM", "NSM", "NSM", "NSM", "NSM", "NSM", "NSM", "NSM", "NSM", "NSM", "NSM", "NSM", "NSM", "NSM", "NSM", "NSM", "NSM", "NSM", "NSM", "N", "N", "N", "N", "N", "N", "N", "N", "N", "N", "N", "N", "N", "N", "N", "L", "L", "L", "L", "L", "L", "L", "N", "N", "N", "N", "N", "N", "N", "N", "N", "N", "N", "N", "L", "L", "L", "L", "L", "N", "N", "N", "N", "N", "R", "NSM", "R", "R", "R", "R", "R", "R", "R", "R", "R", "R", "ES", "R", "R", "R", "R", "R", "R", "R", "R", "R", "R", "R", "R", "R", "N", "R", "R", "R", "R", "R", "N", "R", "N", "R", "R", "N", "R", "R", "N", "R", "R", "R", "R", "R", "R", "R", "R", "R", "R", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "N", "N", "N", "N", "N", "N", "N", "N", "N", "N", "N", "N", "N", "N", "N", "N", "N", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "NSM", "NSM", "NSM", "NSM", "NSM", "NSM", "NSM", "NSM", "NSM", "NSM", "NSM", "NSM", "NSM", "NSM", "NSM", "NSM", "N", "N", "N", "N", "N", "N", "N", "N", "N", "N", "N", "N", "N", "N", "N", "N", "NSM", "NSM", "NSM", "NSM", "NSM", "NSM", "NSM", "NSM", "NSM", "NSM", "NSM", "NSM", "NSM", "NSM", "NSM", "NSM", "N", "N", "N", "N", "N", "N", "N", "N", "N", "N", "N", "N", "N", "N", "N", "N", "N", "N", "N", "N", "N", "N", "N", "N", "N", "N", "N", "N", "N", "N", "N", "N", "CS", "N", "CS", "N", "N", "CS", "N", "N", "N", "N", "N", "N", "N", "N", "N", "ET", "N", "N", "ES", "ES", "N", "N", "N", "N", "N", "ET", "ET", "N", "N", "N", "N", "N", "AL", "AL", "AL", "AL", "AL", "N", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "N", "N", "BN", "N", "N", "N", "ET", "ET", "ET", "N", "N", "N", "N", "N", "ES", "CS", "ES", "CS", "CS", "EN", "EN", "EN", "EN", "EN", "EN", "EN", "EN", "EN", "EN", "CS", "N", "N", "N", "N", "N", "N", "L", "L", "L", "L", "L", "L", "L", "L", "L", "L", "L", "L", "L", "L", "L", "L", "L", "L", "L", "L", "L", "L", "L", "L", "L", "L", "N", "N", "N", "N", "N", "N", "L", "L", "L", "L", "L", "L", "L", "L", "L", "L", "L", "L", "L", "L", "L", "L", "L", "L", "L", "L", "L", "L", "L", "L", "L", "L", "N", "N", "N", "N", "N", "N", "N", "N", "N", "N", "N", "L", "L", "L", "L", "L", "L", "L", "L", "L", "L", "L", "L", "L", "L", "L", "L", "L", "L", "L", "L", "L", "L", "L", "L", "L", "L", "L", "L", "L", "L", "L", "L", "L", "L", "L", "L", "L", "L", "L", "L", "L", "L", "L", "L", "L", "L", "L", "L", "L", "L", "L", "L", "L", "L", "L", "L", "L", "L", "L", "L", "L", "L", "L", "L", "L", "L", "L", "L", "L", "L", "L", "L", "L", "L", "L", "L", "L", "L", "L", "L", "L", "L", "L", "L", "L", "L", "L", "L", "L", "N", "N", "N", "L", "L", "L", "L", "L", "L", "N", "N", "L", "L", "L", "L", "L", "L", "N", "N", "L", "L", "L", "L", "L", "L", "N", "N", "L", "L", "L", "N", "N", "N", "ET", "ET", "N", "N", "N", "ET", "ET", "N", "N", "N", "N", "N", "N", "N", "N", "N", "N", "N", "N", "N", "N", "N", "N", "N", "N", "N", "N", "N", "N", "N", "N", "N"], r2 = new t2.__bidiEngine__({ isInputVisual: true });
      t2.API.events.push(["postProcessText", function(t3) {
        var e3 = t3.text;
        t3.x, t3.y;
        var n2 = t3.options || {};
        t3.mutex, n2.lang;
        var i2 = [];
        if (n2.isInputVisual = "boolean" != typeof n2.isInputVisual || n2.isInputVisual, r2.setOptions(n2), "[object Array]" === Object.prototype.toString.call(e3)) {
          var a2 = 0;
          for (i2 = [], a2 = 0; a2 < e3.length; a2 += 1) "[object Array]" === Object.prototype.toString.call(e3[a2]) ? i2.push([r2.doBidiReorder(e3[a2][0]), e3[a2][1], e3[a2][2]]) : i2.push([r2.doBidiReorder(e3[a2])]);
          t3.text = i2;
        } else t3.text = r2.doBidiReorder(e3);
        r2.setOptions({ isInputVisual: true });
      }]);
    })(C), C.API.TTFFont = (function() {
      function t2(t3) {
        var e2;
        if (this.rawData = t3, e2 = this.contents = new ae(t3), this.contents.pos = 4, "ttcf" === e2.readString(4)) throw new Error("TTCF not supported.");
        e2.pos = 0, this.parse(), this.subset = new Ae(this), this.registerTTF();
      }
      return t2.open = function(e2) {
        return new t2(e2);
      }, t2.prototype.parse = function() {
        return this.directory = new oe(this.contents), this.head = new ue(this), this.name = new me(this), this.cmap = new he(this), this.toUnicode = {}, this.hhea = new fe(this), this.maxp = new ve(this), this.hmtx = new be(this), this.post = new pe(this), this.os2 = new de(this), this.loca = new xe(this), this.glyf = new we(this), this.ascender = this.os2.exists && this.os2.ascender || this.hhea.ascender, this.decender = this.os2.exists && this.os2.decender || this.hhea.decender, this.lineGap = this.os2.exists && this.os2.lineGap || this.hhea.lineGap, this.bbox = [this.head.xMin, this.head.yMin, this.head.xMax, this.head.yMax];
      }, t2.prototype.registerTTF = function() {
        var t3, e2, r2, n2, i2;
        if (this.scaleFactor = 1e3 / this.head.unitsPerEm, this.bbox = function() {
          var e3, r3, n3, i3;
          for (i3 = [], e3 = 0, r3 = (n3 = this.bbox).length; e3 < r3; e3++) t3 = n3[e3], i3.push(Math.round(t3 * this.scaleFactor));
          return i3;
        }.call(this), this.stemV = 0, this.post.exists ? (r2 = 255 & (n2 = this.post.italic_angle), 32768 & (e2 = n2 >> 16) && (e2 = -(1 + (65535 ^ e2))), this.italicAngle = +(e2 + "." + r2)) : this.italicAngle = 0, this.ascender = Math.round(this.ascender * this.scaleFactor), this.decender = Math.round(this.decender * this.scaleFactor), this.lineGap = Math.round(this.lineGap * this.scaleFactor), this.capHeight = this.os2.exists && this.os2.capHeight || this.ascender, this.xHeight = this.os2.exists && this.os2.xHeight || 0, this.familyClass = (this.os2.exists && this.os2.familyClass || 0) >> 8, this.isSerif = 1 === (i2 = this.familyClass) || 2 === i2 || 3 === i2 || 4 === i2 || 5 === i2 || 7 === i2, this.isScript = 10 === this.familyClass, this.flags = 0, this.post.isFixedPitch && (this.flags |= 1), this.isSerif && (this.flags |= 2), this.isScript && (this.flags |= 8), 0 !== this.italicAngle && (this.flags |= 64), this.flags |= 32, !this.cmap.unicode) throw new Error("No unicode cmap for font");
      }, t2.prototype.characterToGlyph = function(t3) {
        var e2;
        return (null != (e2 = this.cmap.unicode) ? e2.codeMap[t3] : void 0) || 0;
      }, t2.prototype.widthOfGlyph = function(t3) {
        var e2;
        return e2 = 1e3 / this.head.unitsPerEm, this.hmtx.forGlyph(t3).advance * e2;
      }, t2.prototype.widthOfString = function(t3, e2, r2) {
        var n2, i2, a2, o2;
        for (a2 = 0, i2 = 0, o2 = (t3 = "" + t3).length; 0 <= o2 ? i2 < o2 : i2 > o2; i2 = 0 <= o2 ? ++i2 : --i2) n2 = t3.charCodeAt(i2), a2 += this.widthOfGlyph(this.characterToGlyph(n2)) + r2 * (1e3 / e2) || 0;
        return a2 * (e2 / 1e3);
      }, t2.prototype.lineHeight = function(t3, e2) {
        var r2;
        return null == e2 && (e2 = false), r2 = e2 ? this.lineGap : 0, (this.ascender + r2 - this.decender) / 1e3 * t3;
      }, t2;
    })();
    var ie;
    var ae = (function() {
      function t2(t3) {
        this.data = null != t3 ? t3 : [], this.pos = 0, this.length = this.data.length;
      }
      return t2.prototype.readByte = function() {
        return this.data[this.pos++];
      }, t2.prototype.writeByte = function(t3) {
        return this.data[this.pos++] = t3;
      }, t2.prototype.readUInt32 = function() {
        return 16777216 * this.readByte() + (this.readByte() << 16) + (this.readByte() << 8) + this.readByte();
      }, t2.prototype.writeUInt32 = function(t3) {
        return this.writeByte(t3 >>> 24 & 255), this.writeByte(t3 >> 16 & 255), this.writeByte(t3 >> 8 & 255), this.writeByte(255 & t3);
      }, t2.prototype.readInt32 = function() {
        var t3;
        return (t3 = this.readUInt32()) >= 2147483648 ? t3 - 4294967296 : t3;
      }, t2.prototype.writeInt32 = function(t3) {
        return t3 < 0 && (t3 += 4294967296), this.writeUInt32(t3);
      }, t2.prototype.readUInt16 = function() {
        return this.readByte() << 8 | this.readByte();
      }, t2.prototype.writeUInt16 = function(t3) {
        return this.writeByte(t3 >> 8 & 255), this.writeByte(255 & t3);
      }, t2.prototype.readInt16 = function() {
        var t3;
        return (t3 = this.readUInt16()) >= 32768 ? t3 - 65536 : t3;
      }, t2.prototype.writeInt16 = function(t3) {
        return t3 < 0 && (t3 += 65536), this.writeUInt16(t3);
      }, t2.prototype.readString = function(t3) {
        var e2, r2;
        for (r2 = [], e2 = 0; 0 <= t3 ? e2 < t3 : e2 > t3; e2 = 0 <= t3 ? ++e2 : --e2) r2[e2] = String.fromCharCode(this.readByte());
        return r2.join("");
      }, t2.prototype.writeString = function(t3) {
        var e2, r2, n2;
        for (n2 = [], e2 = 0, r2 = t3.length; 0 <= r2 ? e2 < r2 : e2 > r2; e2 = 0 <= r2 ? ++e2 : --e2) n2.push(this.writeByte(t3.charCodeAt(e2)));
        return n2;
      }, t2.prototype.readShort = function() {
        return this.readInt16();
      }, t2.prototype.writeShort = function(t3) {
        return this.writeInt16(t3);
      }, t2.prototype.readLongLong = function() {
        var t3, e2, r2, n2, i2, a2, o2, s2;
        return t3 = this.readByte(), e2 = this.readByte(), r2 = this.readByte(), n2 = this.readByte(), i2 = this.readByte(), a2 = this.readByte(), o2 = this.readByte(), s2 = this.readByte(), 128 & t3 ? -1 * (72057594037927940 * (255 ^ t3) + 281474976710656 * (255 ^ e2) + 1099511627776 * (255 ^ r2) + 4294967296 * (255 ^ n2) + 16777216 * (255 ^ i2) + 65536 * (255 ^ a2) + 256 * (255 ^ o2) + (255 ^ s2) + 1) : 72057594037927940 * t3 + 281474976710656 * e2 + 1099511627776 * r2 + 4294967296 * n2 + 16777216 * i2 + 65536 * a2 + 256 * o2 + s2;
      }, t2.prototype.writeLongLong = function(t3) {
        var e2, r2;
        return e2 = Math.floor(t3 / 4294967296), r2 = 4294967295 & t3, this.writeByte(e2 >> 24 & 255), this.writeByte(e2 >> 16 & 255), this.writeByte(e2 >> 8 & 255), this.writeByte(255 & e2), this.writeByte(r2 >> 24 & 255), this.writeByte(r2 >> 16 & 255), this.writeByte(r2 >> 8 & 255), this.writeByte(255 & r2);
      }, t2.prototype.readInt = function() {
        return this.readInt32();
      }, t2.prototype.writeInt = function(t3) {
        return this.writeInt32(t3);
      }, t2.prototype.read = function(t3) {
        var e2, r2;
        for (e2 = [], r2 = 0; 0 <= t3 ? r2 < t3 : r2 > t3; r2 = 0 <= t3 ? ++r2 : --r2) e2.push(this.readByte());
        return e2;
      }, t2.prototype.write = function(t3) {
        var e2, r2, n2, i2;
        for (i2 = [], r2 = 0, n2 = t3.length; r2 < n2; r2++) e2 = t3[r2], i2.push(this.writeByte(e2));
        return i2;
      }, t2;
    })();
    var oe = (function() {
      var t2;
      function e2(t3) {
        var e3, r2, n2;
        for (this.scalarType = t3.readInt(), this.tableCount = t3.readShort(), this.searchRange = t3.readShort(), this.entrySelector = t3.readShort(), this.rangeShift = t3.readShort(), this.tables = {}, r2 = 0, n2 = this.tableCount; 0 <= n2 ? r2 < n2 : r2 > n2; r2 = 0 <= n2 ? ++r2 : --r2) e3 = { tag: t3.readString(4), checksum: t3.readInt(), offset: t3.readInt(), length: t3.readInt() }, this.tables[e3.tag] = e3;
      }
      return e2.prototype.encode = function(e3) {
        var r2, n2, i2, a2, o2, s2, c2, u2, l2, h2, f2, d2, p2;
        for (p2 in f2 = Object.keys(e3).length, s2 = Math.log(2), l2 = 16 * Math.floor(Math.log(f2) / s2), a2 = Math.floor(l2 / s2), u2 = 16 * f2 - l2, (n2 = new ae()).writeInt(this.scalarType), n2.writeShort(f2), n2.writeShort(l2), n2.writeShort(a2), n2.writeShort(u2), i2 = 16 * f2, c2 = n2.pos + i2, o2 = null, d2 = [], e3) for (h2 = e3[p2], n2.writeString(p2), n2.writeInt(t2(h2)), n2.writeInt(c2), n2.writeInt(h2.length), d2 = d2.concat(h2), "head" === p2 && (o2 = c2), c2 += h2.length; c2 % 4; ) d2.push(0), c2++;
        return n2.write(d2), r2 = 2981146554 - t2(n2.data), n2.pos = o2 + 8, n2.writeUInt32(r2), n2.data;
      }, t2 = function(t3) {
        var e3, r2, n2, i2;
        for (t3 = ye.call(t3); t3.length % 4; ) t3.push(0);
        for (n2 = new ae(t3), r2 = 0, e3 = 0, i2 = t3.length; e3 < i2; e3 = e3 += 4) r2 += n2.readUInt32();
        return 4294967295 & r2;
      }, e2;
    })();
    var se = {}.hasOwnProperty;
    var ce = function(t2, e2) {
      for (var r2 in e2) se.call(e2, r2) && (t2[r2] = e2[r2]);
      function n2() {
        this.constructor = t2;
      }
      return n2.prototype = e2.prototype, t2.prototype = new n2(), t2.__super__ = e2.prototype, t2;
    };
    ie = (function() {
      function t2(t3) {
        var e2;
        this.file = t3, e2 = this.file.directory.tables[this.tag], this.exists = !!e2, e2 && (this.offset = e2.offset, this.length = e2.length, this.parse(this.file.contents));
      }
      return t2.prototype.parse = function() {
      }, t2.prototype.encode = function() {
      }, t2.prototype.raw = function() {
        return this.exists ? (this.file.contents.pos = this.offset, this.file.contents.read(this.length)) : null;
      }, t2;
    })();
    var ue = (function() {
      function t2() {
        return t2.__super__.constructor.apply(this, arguments);
      }
      return ce(t2, ie), t2.prototype.tag = "head", t2.prototype.parse = function(t3) {
        return t3.pos = this.offset, this.version = t3.readInt(), this.revision = t3.readInt(), this.checkSumAdjustment = t3.readInt(), this.magicNumber = t3.readInt(), this.flags = t3.readShort(), this.unitsPerEm = t3.readShort(), this.created = t3.readLongLong(), this.modified = t3.readLongLong(), this.xMin = t3.readShort(), this.yMin = t3.readShort(), this.xMax = t3.readShort(), this.yMax = t3.readShort(), this.macStyle = t3.readShort(), this.lowestRecPPEM = t3.readShort(), this.fontDirectionHint = t3.readShort(), this.indexToLocFormat = t3.readShort(), this.glyphDataFormat = t3.readShort();
      }, t2.prototype.encode = function(t3) {
        var e2;
        return (e2 = new ae()).writeInt(this.version), e2.writeInt(this.revision), e2.writeInt(this.checkSumAdjustment), e2.writeInt(this.magicNumber), e2.writeShort(this.flags), e2.writeShort(this.unitsPerEm), e2.writeLongLong(this.created), e2.writeLongLong(this.modified), e2.writeShort(this.xMin), e2.writeShort(this.yMin), e2.writeShort(this.xMax), e2.writeShort(this.yMax), e2.writeShort(this.macStyle), e2.writeShort(this.lowestRecPPEM), e2.writeShort(this.fontDirectionHint), e2.writeShort(t3), e2.writeShort(this.glyphDataFormat), e2.data;
      }, t2;
    })();
    var le = (function() {
      function t2(t3, e2) {
        var r2, n2, i2, a2, o2, s2, c2, u2, l2, h2, f2, d2, p2, g2, m2, v2, b2;
        switch (this.platformID = t3.readUInt16(), this.encodingID = t3.readShort(), this.offset = e2 + t3.readInt(), l2 = t3.pos, t3.pos = this.offset, this.format = t3.readUInt16(), this.length = t3.readUInt16(), this.language = t3.readUInt16(), this.isUnicode = 3 === this.platformID && 1 === this.encodingID && 4 === this.format || 0 === this.platformID && 4 === this.format, this.codeMap = {}, this.format) {
          case 0:
            for (s2 = 0; s2 < 256; ++s2) this.codeMap[s2] = t3.readByte();
            break;
          case 4:
            for (f2 = t3.readUInt16(), h2 = f2 / 2, t3.pos += 6, i2 = (function() {
              var e3, r3;
              for (r3 = [], s2 = e3 = 0; 0 <= h2 ? e3 < h2 : e3 > h2; s2 = 0 <= h2 ? ++e3 : --e3) r3.push(t3.readUInt16());
              return r3;
            })(), t3.pos += 2, p2 = (function() {
              var e3, r3;
              for (r3 = [], s2 = e3 = 0; 0 <= h2 ? e3 < h2 : e3 > h2; s2 = 0 <= h2 ? ++e3 : --e3) r3.push(t3.readUInt16());
              return r3;
            })(), c2 = (function() {
              var e3, r3;
              for (r3 = [], s2 = e3 = 0; 0 <= h2 ? e3 < h2 : e3 > h2; s2 = 0 <= h2 ? ++e3 : --e3) r3.push(t3.readUInt16());
              return r3;
            })(), u2 = (function() {
              var e3, r3;
              for (r3 = [], s2 = e3 = 0; 0 <= h2 ? e3 < h2 : e3 > h2; s2 = 0 <= h2 ? ++e3 : --e3) r3.push(t3.readUInt16());
              return r3;
            })(), n2 = (this.length - t3.pos + this.offset) / 2, o2 = (function() {
              var e3, r3;
              for (r3 = [], s2 = e3 = 0; 0 <= n2 ? e3 < n2 : e3 > n2; s2 = 0 <= n2 ? ++e3 : --e3) r3.push(t3.readUInt16());
              return r3;
            })(), s2 = m2 = 0, b2 = i2.length; m2 < b2; s2 = ++m2) for (g2 = i2[s2], r2 = v2 = d2 = p2[s2]; d2 <= g2 ? v2 <= g2 : v2 >= g2; r2 = d2 <= g2 ? ++v2 : --v2) 0 === u2[s2] ? a2 = r2 + c2[s2] : 0 !== (a2 = o2[u2[s2] / 2 + (r2 - d2) - (h2 - s2)] || 0) && (a2 += c2[s2]), this.codeMap[r2] = 65535 & a2;
        }
        t3.pos = l2;
      }
      return t2.encode = function(t3, e2) {
        var r2, n2, i2, a2, o2, s2, c2, u2, l2, h2, f2, d2, p2, g2, m2, v2, b2, y2, w2, N2, L2, x2, A2, S2, _2, P2, k2, F2, I2, C2, j2, O2, B2, q2, M2, E2, R2, D2, T2, z2, U2, H2, W2, V2, G2, Y2;
        switch (F2 = new ae(), a2 = Object.keys(t3).sort(function(t4, e3) {
          return t4 - e3;
        }), e2) {
          case "macroman":
            for (p2 = 0, g2 = (function() {
              var t4 = [];
              for (d2 = 0; d2 < 256; ++d2) t4.push(0);
              return t4;
            })(), v2 = { 0: 0 }, i2 = {}, I2 = 0, B2 = a2.length; I2 < B2; I2++) null == v2[W2 = t3[n2 = a2[I2]]] && (v2[W2] = ++p2), i2[n2] = { old: t3[n2], new: v2[t3[n2]] }, g2[n2] = v2[t3[n2]];
            return F2.writeUInt16(1), F2.writeUInt16(0), F2.writeUInt32(12), F2.writeUInt16(0), F2.writeUInt16(262), F2.writeUInt16(0), F2.write(g2), { charMap: i2, subtable: F2.data, maxGlyphID: p2 + 1 };
          case "unicode":
            for (P2 = [], l2 = [], b2 = 0, v2 = {}, r2 = {}, m2 = c2 = null, C2 = 0, q2 = a2.length; C2 < q2; C2++) null == v2[w2 = t3[n2 = a2[C2]]] && (v2[w2] = ++b2), r2[n2] = { old: w2, new: v2[w2] }, o2 = v2[w2] - n2, null != m2 && o2 === c2 || (m2 && l2.push(m2), P2.push(n2), c2 = o2), m2 = n2;
            for (m2 && l2.push(m2), l2.push(65535), P2.push(65535), S2 = 2 * (A2 = P2.length), x2 = 2 * Math.pow(Math.log(A2) / Math.LN2, 2), h2 = Math.log(x2 / 2) / Math.LN2, L2 = 2 * A2 - x2, s2 = [], N2 = [], f2 = [], d2 = j2 = 0, M2 = P2.length; j2 < M2; d2 = ++j2) {
              if (_2 = P2[d2], u2 = l2[d2], 65535 === _2) {
                s2.push(0), N2.push(0);
                break;
              }
              if (_2 - (k2 = r2[_2].new) >= 32768) for (s2.push(0), N2.push(2 * (f2.length + A2 - d2)), n2 = O2 = _2; _2 <= u2 ? O2 <= u2 : O2 >= u2; n2 = _2 <= u2 ? ++O2 : --O2) f2.push(r2[n2].new);
              else s2.push(k2 - _2), N2.push(0);
            }
            for (F2.writeUInt16(3), F2.writeUInt16(1), F2.writeUInt32(12), F2.writeUInt16(4), F2.writeUInt16(16 + 8 * A2 + 2 * f2.length), F2.writeUInt16(0), F2.writeUInt16(S2), F2.writeUInt16(x2), F2.writeUInt16(h2), F2.writeUInt16(L2), U2 = 0, E2 = l2.length; U2 < E2; U2++) n2 = l2[U2], F2.writeUInt16(n2);
            for (F2.writeUInt16(0), H2 = 0, R2 = P2.length; H2 < R2; H2++) n2 = P2[H2], F2.writeUInt16(n2);
            for (V2 = 0, D2 = s2.length; V2 < D2; V2++) o2 = s2[V2], F2.writeUInt16(o2);
            for (G2 = 0, T2 = N2.length; G2 < T2; G2++) y2 = N2[G2], F2.writeUInt16(y2);
            for (Y2 = 0, z2 = f2.length; Y2 < z2; Y2++) p2 = f2[Y2], F2.writeUInt16(p2);
            return { charMap: r2, subtable: F2.data, maxGlyphID: b2 + 1 };
        }
      }, t2;
    })();
    var he = (function() {
      function t2() {
        return t2.__super__.constructor.apply(this, arguments);
      }
      return ce(t2, ie), t2.prototype.tag = "cmap", t2.prototype.parse = function(t3) {
        var e2, r2, n2;
        for (t3.pos = this.offset, this.version = t3.readUInt16(), n2 = t3.readUInt16(), this.tables = [], this.unicode = null, r2 = 0; 0 <= n2 ? r2 < n2 : r2 > n2; r2 = 0 <= n2 ? ++r2 : --r2) e2 = new le(t3, this.offset), this.tables.push(e2), e2.isUnicode && null == this.unicode && (this.unicode = e2);
        return true;
      }, t2.encode = function(t3, e2) {
        var r2, n2;
        return null == e2 && (e2 = "macroman"), r2 = le.encode(t3, e2), (n2 = new ae()).writeUInt16(0), n2.writeUInt16(1), r2.table = n2.data.concat(r2.subtable), r2;
      }, t2;
    })();
    var fe = (function() {
      function t2() {
        return t2.__super__.constructor.apply(this, arguments);
      }
      return ce(t2, ie), t2.prototype.tag = "hhea", t2.prototype.parse = function(t3) {
        return t3.pos = this.offset, this.version = t3.readInt(), this.ascender = t3.readShort(), this.decender = t3.readShort(), this.lineGap = t3.readShort(), this.advanceWidthMax = t3.readShort(), this.minLeftSideBearing = t3.readShort(), this.minRightSideBearing = t3.readShort(), this.xMaxExtent = t3.readShort(), this.caretSlopeRise = t3.readShort(), this.caretSlopeRun = t3.readShort(), this.caretOffset = t3.readShort(), t3.pos += 8, this.metricDataFormat = t3.readShort(), this.numberOfMetrics = t3.readUInt16();
      }, t2;
    })();
    var de = (function() {
      function t2() {
        return t2.__super__.constructor.apply(this, arguments);
      }
      return ce(t2, ie), t2.prototype.tag = "OS/2", t2.prototype.parse = function(t3) {
        if (t3.pos = this.offset, this.version = t3.readUInt16(), this.averageCharWidth = t3.readShort(), this.weightClass = t3.readUInt16(), this.widthClass = t3.readUInt16(), this.type = t3.readShort(), this.ySubscriptXSize = t3.readShort(), this.ySubscriptYSize = t3.readShort(), this.ySubscriptXOffset = t3.readShort(), this.ySubscriptYOffset = t3.readShort(), this.ySuperscriptXSize = t3.readShort(), this.ySuperscriptYSize = t3.readShort(), this.ySuperscriptXOffset = t3.readShort(), this.ySuperscriptYOffset = t3.readShort(), this.yStrikeoutSize = t3.readShort(), this.yStrikeoutPosition = t3.readShort(), this.familyClass = t3.readShort(), this.panose = (function() {
          var e2, r2;
          for (r2 = [], e2 = 0; e2 < 10; ++e2) r2.push(t3.readByte());
          return r2;
        })(), this.charRange = (function() {
          var e2, r2;
          for (r2 = [], e2 = 0; e2 < 4; ++e2) r2.push(t3.readInt());
          return r2;
        })(), this.vendorID = t3.readString(4), this.selection = t3.readShort(), this.firstCharIndex = t3.readShort(), this.lastCharIndex = t3.readShort(), this.version > 0 && (this.ascent = t3.readShort(), this.descent = t3.readShort(), this.lineGap = t3.readShort(), this.winAscent = t3.readShort(), this.winDescent = t3.readShort(), this.codePageRange = (function() {
          var e2, r2;
          for (r2 = [], e2 = 0; e2 < 2; e2 = ++e2) r2.push(t3.readInt());
          return r2;
        })(), this.version > 1)) return this.xHeight = t3.readShort(), this.capHeight = t3.readShort(), this.defaultChar = t3.readShort(), this.breakChar = t3.readShort(), this.maxContext = t3.readShort();
      }, t2;
    })();
    var pe = (function() {
      function t2() {
        return t2.__super__.constructor.apply(this, arguments);
      }
      return ce(t2, ie), t2.prototype.tag = "post", t2.prototype.parse = function(t3) {
        var e2, r2, n2;
        switch (t3.pos = this.offset, this.format = t3.readInt(), this.italicAngle = t3.readInt(), this.underlinePosition = t3.readShort(), this.underlineThickness = t3.readShort(), this.isFixedPitch = t3.readInt(), this.minMemType42 = t3.readInt(), this.maxMemType42 = t3.readInt(), this.minMemType1 = t3.readInt(), this.maxMemType1 = t3.readInt(), this.format) {
          case 65536:
          case 196608:
            break;
          case 131072:
            var i2;
            for (r2 = t3.readUInt16(), this.glyphNameIndex = [], i2 = 0; 0 <= r2 ? i2 < r2 : i2 > r2; i2 = 0 <= r2 ? ++i2 : --i2) this.glyphNameIndex.push(t3.readUInt16());
            for (this.names = [], n2 = []; t3.pos < this.offset + this.length; ) e2 = t3.readByte(), n2.push(this.names.push(t3.readString(e2)));
            return n2;
          case 151552:
            return r2 = t3.readUInt16(), this.offsets = t3.read(r2);
          case 262144:
            return this.map = function() {
              var e3, r3, n3;
              for (n3 = [], i2 = e3 = 0, r3 = this.file.maxp.numGlyphs; 0 <= r3 ? e3 < r3 : e3 > r3; i2 = 0 <= r3 ? ++e3 : --e3) n3.push(t3.readUInt32());
              return n3;
            }.call(this);
        }
      }, t2;
    })();
    var ge = function(t2, e2) {
      this.raw = t2, this.length = t2.length, this.platformID = e2.platformID, this.encodingID = e2.encodingID, this.languageID = e2.languageID;
    };
    var me = (function() {
      function t2() {
        return t2.__super__.constructor.apply(this, arguments);
      }
      return ce(t2, ie), t2.prototype.tag = "name", t2.prototype.parse = function(t3) {
        var e2, r2, n2, i2, a2, o2, s2, c2, u2, l2, h2;
        for (t3.pos = this.offset, t3.readShort(), e2 = t3.readShort(), o2 = t3.readShort(), r2 = [], i2 = 0; 0 <= e2 ? i2 < e2 : i2 > e2; i2 = 0 <= e2 ? ++i2 : --i2) r2.push({ platformID: t3.readShort(), encodingID: t3.readShort(), languageID: t3.readShort(), nameID: t3.readShort(), length: t3.readShort(), offset: this.offset + o2 + t3.readShort() });
        for (s2 = {}, i2 = u2 = 0, l2 = r2.length; u2 < l2; i2 = ++u2) n2 = r2[i2], t3.pos = n2.offset, c2 = t3.readString(n2.length), a2 = new ge(c2, n2), null == s2[h2 = n2.nameID] && (s2[h2] = []), s2[n2.nameID].push(a2);
        this.strings = s2, this.copyright = s2[0], this.fontFamily = s2[1], this.fontSubfamily = s2[2], this.uniqueSubfamily = s2[3], this.fontName = s2[4], this.version = s2[5];
        try {
          this.postscriptName = s2[6][0].raw.replace(/[\x00-\x19\x80-\xff]/g, "");
        } catch (f2) {
          this.postscriptName = s2[4][0].raw.replace(/[\x00-\x19\x80-\xff]/g, "");
        }
        return this.trademark = s2[7], this.manufacturer = s2[8], this.designer = s2[9], this.description = s2[10], this.vendorUrl = s2[11], this.designerUrl = s2[12], this.license = s2[13], this.licenseUrl = s2[14], this.preferredFamily = s2[15], this.preferredSubfamily = s2[17], this.compatibleFull = s2[18], this.sampleText = s2[19];
      }, t2;
    })();
    var ve = (function() {
      function t2() {
        return t2.__super__.constructor.apply(this, arguments);
      }
      return ce(t2, ie), t2.prototype.tag = "maxp", t2.prototype.parse = function(t3) {
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

// src/portal/it-operations.tsx
var it_operations_exports = {};
__export(it_operations_exports, {
  ItOperations: () => ItOperations
});
module.exports = __toCommonJS(it_operations_exports);
var import_react2 = require("/workspace/scratch/76b8a24bf15c/imanservice/node_modules/react/index.js");

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

// mock:client
var db = globalThis.__db;
function check(r) {
  if (r.error) throw r.error;
  return r.data;
}

// src/portal/operations.tsx
var import_react = require("/workspace/scratch/76b8a24bf15c/imanservice/node_modules/react/index.js");
var import_jsx_runtime = __toESM(require_jsx_runtime(), 1);
var priorities = ["Low", "Normal", "High", "Urgent"];
var shortDate = (v) => v ? (/* @__PURE__ */ new Date(`${v.slice(0, 10)}T12:00:00`)).toLocaleDateString() : "Not set";
function Input({ name, label, value = "", type = "text", required = false, children, max = 200 }) {
  return /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("label", { className: "p-field", children: [
    /* @__PURE__ */ (0, import_jsx_runtime.jsx)("span", { children: label }),
    children ? /* @__PURE__ */ (0, import_jsx_runtime.jsx)("select", { name, defaultValue: value, required, children }) : type === "textarea" ? /* @__PURE__ */ (0, import_jsx_runtime.jsx)("textarea", { name, defaultValue: value, maxLength: 1e4, rows: 3 }) : /* @__PURE__ */ (0, import_jsx_runtime.jsx)("input", { name, type, defaultValue: value, required, maxLength: type === "text" ? max : void 0 })
  ] });
}
function SaveForm({ children, onSave, busy, label = "Save" }) {
  return /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("form", { className: "p-form", onSubmit: async (e) => {
    e.preventDefault();
    const f = e.currentTarget;
    const ok = await onSave(Object.fromEntries(new FormData(f)));
    if (ok && f.isConnected) f.reset();
  }, children: [
    children,
    /* @__PURE__ */ (0, import_jsx_runtime.jsx)("button", { disabled: busy, className: "p-primary", children: busy ? "Saving\u2026" : label })
  ] });
}

// src/portal/it-operations.tsx
var import_jsx_runtime2 = __toESM(require_jsx_runtime(), 1);
var names = { sites: "Sites & IT assets", audits: "Network audits", visits: "Maintenance visits", renewals: "AMC renewals" };
var opts = (rs) => rs.map((r) => /* @__PURE__ */ (0, import_jsx_runtime2.jsx)("option", { value: r.id, children: r.title || r.name }, r.id));
var localStamp = (s) => {
  const d = new Date(s);
  return new Date(d.getTime() - d.getTimezoneOffset() * 6e4).toISOString().slice(0, 16);
};
function download(name, text) {
  const u = URL.createObjectURL(new Blob([text], { type: "text/plain;charset=utf-8" }));
  const a = document.createElement("a");
  a.href = u;
  a.download = name;
  a.click();
  URL.revokeObjectURL(u);
}
function ItOperations({ view, profile, companies, projects, members }) {
  const admin = profile.role === "admin", staff = profile.role !== "client";
  const [data, setData] = (0, import_react2.useState)({ client_sites: [], it_jobs: [], amc_renewals: [], it_operation_history: [], it_job_reports: [], equipment: [], contracts: [], files: [], tasks: [] });
  const [busy, setBusy] = (0, import_react2.useState)(false), [error, setError] = (0, import_react2.useState)(""), [notice, setNotice] = (0, import_react2.useState)(""), [edit, setEdit] = (0, import_react2.useState)(null), [cid, setCid] = (0, import_react2.useState)(companies[0]?.id || ""), [site, setSite] = (0, import_react2.useState)(""), [project, setProject] = (0, import_react2.useState)(""), [query, setQuery] = (0, import_react2.useState)(""), [filter, setFilter] = (0, import_react2.useState)(""), [month, setMonth] = (0, import_react2.useState)((/* @__PURE__ */ new Date()).toISOString().slice(0, 7));
  async function load() {
    const tables = Object.keys(data);
    const results = await Promise.all(tables.map((t) => db.from(t).select("*")));
    const d = {};
    results.forEach((r, i) => {
      d[tables[i]] = check(r) || [];
    });
    setData(d);
  }
  (0, import_react2.useEffect)(() => {
    setEdit(null);
    setError("");
    setNotice("");
    setBusy(true);
    load().catch((e) => setError(e.message)).finally(() => setBusy(false));
  }, [view, profile.id]);
  async function act(fn) {
    setBusy(true);
    setError("");
    setNotice("");
    try {
      await fn();
      await load();
      setEdit(null);
      setNotice("Saved.");
      return true;
    } catch (e) {
      setError(e.message);
      return false;
    } finally {
      setBusy(false);
    }
  }
  const rpc = (name, args) => act(async () => check(await db.rpc(name, args)));
  const startEdit = (r) => {
    setEdit(r);
    setCid(r.company_id || cid);
    setSite(r.site_id || "");
    setProject(r.project_id || "");
  };
  const activeStaff = members.filter((x) => x.active && x.role !== "client");
  const contract = data.contracts.find((c) => c.id === (edit?.contract_id || ""));
  const jobs = data.it_jobs.filter((j) => j.kind === (view === "audits" ? "Audit" : "Visit") && (!filter || j.site_id === filter) && `${j.title} ${j.status}`.toLowerCase().includes(query.toLowerCase())).sort((a, b) => a.scheduled_at.localeCompare(b.scheduled_at));
  const jobAction = (r, a, n = "") => rpc("it_job_action", { p_id: r.id, p_version: r.version, p_action: a, p_note: n });
  const renewalAction = (r, a, n = "") => rpc("amc_renewal_action", { p_id: r.id, p_version: r.version, p_action: a, p_note: n });
  function history(r) {
    return /* @__PURE__ */ (0, import_jsx_runtime2.jsxs)("details", { children: [
      /* @__PURE__ */ (0, import_jsx_runtime2.jsx)("summary", { children: "Action history" }),
      data.it_operation_history.filter((h) => h.record_id === r.id).sort((a, b) => a.created_at.localeCompare(b.created_at)).map((h) => /* @__PURE__ */ (0, import_jsx_runtime2.jsxs)("p", { children: [
        new Date(h.created_at).toLocaleString(),
        " \xB7 ",
        h.action,
        " \xB7 ",
        members.find((m) => m.id === h.actor_id)?.name || "Portal user"
      ] }, h.id))
    ] });
  }
  return /* @__PURE__ */ (0, import_jsx_runtime2.jsxs)(import_jsx_runtime2.Fragment, { children: [
    /* @__PURE__ */ (0, import_jsx_runtime2.jsxs)("div", { className: "p-heading", children: [
      /* @__PURE__ */ (0, import_jsx_runtime2.jsxs)("div", { children: [
        /* @__PURE__ */ (0, import_jsx_runtime2.jsx)("span", { className: "p-eyebrow", children: "IT OPERATIONS" }),
        /* @__PURE__ */ (0, import_jsx_runtime2.jsx)("h1", { children: names[view] })
      ] }),
      /* @__PURE__ */ (0, import_jsx_runtime2.jsx)("button", { disabled: busy, onClick: () => act(load), children: "Refresh" }),
      admin && /* @__PURE__ */ (0, import_jsx_runtime2.jsxs)("button", { disabled: busy, className: "p-primary", onClick: () => startEdit({ id: "", company_id: cid }), children: [
        "Add ",
        view === "sites" ? "site" : view === "renewals" ? "renewal" : view === "audits" ? "audit" : "visit"
      ] })
    ] }),
    error && /* @__PURE__ */ (0, import_jsx_runtime2.jsx)("p", { role: "alert", className: "p-error", children: error }),
    notice && /* @__PURE__ */ (0, import_jsx_runtime2.jsx)("p", { role: "status", className: "p-notice", children: notice }),
    busy && /* @__PURE__ */ (0, import_jsx_runtime2.jsx)("p", { role: "status", children: "Loading / saving\u2026" }),
    view === "sites" && /* @__PURE__ */ (0, import_jsx_runtime2.jsxs)(import_jsx_runtime2.Fragment, { children: [
      edit && admin && /* @__PURE__ */ (0, import_jsx_runtime2.jsxs)("section", { className: "p-panel", children: [
        /* @__PURE__ */ (0, import_jsx_runtime2.jsx)("h2", { children: edit.id ? "Edit site" : "New site" }),
        /* @__PURE__ */ (0, import_jsx_runtime2.jsxs)(SaveForm, { busy, onSave: (v) => rpc("save_client_site", { p_id: edit.id || null, p_version: edit.version || null, p_company: edit.id ? edit.company_id : v.company_id, p_name: v.name, p_address: v.address, p_contact: v.contact, p_active: v.active === "true" }), children: [
          !edit.id && /* @__PURE__ */ (0, import_jsx_runtime2.jsx)(Input, { name: "company_id", label: "Client company", required: true, children: opts(companies) }),
          /* @__PURE__ */ (0, import_jsx_runtime2.jsx)(Input, { name: "name", label: "Site name", value: edit.name, required: true }),
          /* @__PURE__ */ (0, import_jsx_runtime2.jsx)(Input, { name: "address", label: "Address", type: "textarea", value: edit.address }),
          /* @__PURE__ */ (0, import_jsx_runtime2.jsx)(Input, { name: "contact", label: "Site contact details (shared with client)", type: "textarea", value: edit.contact }),
          /* @__PURE__ */ (0, import_jsx_runtime2.jsxs)(Input, { name: "active", label: "Status", value: edit.active === false ? "false" : "true", children: [
            /* @__PURE__ */ (0, import_jsx_runtime2.jsx)("option", { value: "true", children: "Active" }),
            /* @__PURE__ */ (0, import_jsx_runtime2.jsx)("option", { value: "false", children: "Archived" })
          ] })
        ] }, edit.id || "new-site"),
        /* @__PURE__ */ (0, import_jsx_runtime2.jsx)("button", { onClick: () => setEdit(null), children: "Close" })
      ] }),
      data.client_sites.map((s) => /* @__PURE__ */ (0, import_jsx_runtime2.jsxs)("section", { className: "p-panel", children: [
        /* @__PURE__ */ (0, import_jsx_runtime2.jsxs)("h2", { children: [
          s.name,
          " ",
          s.active ? "" : "(Archived)"
        ] }),
        /* @__PURE__ */ (0, import_jsx_runtime2.jsx)("p", { children: companies.find((c) => c.id === s.company_id)?.name }),
        /* @__PURE__ */ (0, import_jsx_runtime2.jsxs)("p", { className: "p-pre", children: [
          s.address,
          "\n",
          s.contact
        ] }),
        admin && /* @__PURE__ */ (0, import_jsx_runtime2.jsx)("button", { disabled: busy, onClick: () => startEdit(s), children: "Edit site" }),
        /* @__PURE__ */ (0, import_jsx_runtime2.jsx)("h3", { children: "Assets at this site" }),
        data.equipment.filter((e) => e.site_id === s.id).map((e) => /* @__PURE__ */ (0, import_jsx_runtime2.jsxs)("p", { children: [
          e.name,
          " \xB7 ",
          e.status,
          " \xB7 ",
          e.serial_number
        ] }, e.id)),
        admin && /* @__PURE__ */ (0, import_jsx_runtime2.jsx)(SaveForm, { busy, label: "Link asset", onSave: (v) => act(async () => check(await db.from("equipment").update({ site_id: s.id }).eq("id", v.asset_id).select().single())), children: /* @__PURE__ */ (0, import_jsx_runtime2.jsxs)(Input, { name: "asset_id", label: "Equipment", required: true, children: [
          /* @__PURE__ */ (0, import_jsx_runtime2.jsx)("option", { value: "", children: "Choose asset\u2026" }),
          opts(data.equipment.filter((e) => e.company_id === s.company_id && e.site_id !== s.id))
        ] }) }),
        history(s)
      ] }, s.id)),
      /* @__PURE__ */ (0, import_jsx_runtime2.jsxs)("section", { className: "p-panel", children: [
        /* @__PURE__ */ (0, import_jsx_runtime2.jsx)("h2", { children: "Assets without a site" }),
        data.equipment.filter((e) => !e.site_id).map((e) => /* @__PURE__ */ (0, import_jsx_runtime2.jsx)("p", { children: e.name }, e.id))
      ] })
    ] }),
    ["audits", "visits"].includes(view) && /* @__PURE__ */ (0, import_jsx_runtime2.jsxs)(import_jsx_runtime2.Fragment, { children: [
      /* @__PURE__ */ (0, import_jsx_runtime2.jsxs)("div", { className: "p-toolbar", children: [
        /* @__PURE__ */ (0, import_jsx_runtime2.jsxs)("label", { children: [
          "Find work",
          /* @__PURE__ */ (0, import_jsx_runtime2.jsx)("input", { value: query, onChange: (e) => setQuery(e.target.value) })
        ] }),
        /* @__PURE__ */ (0, import_jsx_runtime2.jsxs)("label", { children: [
          "Site",
          /* @__PURE__ */ (0, import_jsx_runtime2.jsxs)("select", { value: filter, onChange: (e) => setFilter(e.target.value), children: [
            /* @__PURE__ */ (0, import_jsx_runtime2.jsx)("option", { value: "", children: "All sites" }),
            opts(data.client_sites)
          ] })
        ] }),
        view === "visits" && /* @__PURE__ */ (0, import_jsx_runtime2.jsxs)("label", { children: [
          "Calendar month",
          /* @__PURE__ */ (0, import_jsx_runtime2.jsx)("input", { type: "month", value: month, onChange: (e) => setMonth(e.target.value) })
        ] })
      ] }),
      view === "visits" && /* @__PURE__ */ (0, import_jsx_runtime2.jsxs)("section", { className: "p-panel", children: [
        /* @__PURE__ */ (0, import_jsx_runtime2.jsxs)("h2", { children: [
          "Visit calendar \u2014 ",
          month
        ] }),
        /* @__PURE__ */ (0, import_jsx_runtime2.jsxs)("p", { children: [
          "Times shown in ",
          Intl.DateTimeFormat().resolvedOptions().timeZone,
          ". Agenda ordered by appointment time."
        ] }),
        jobs.filter((j) => localStamp(j.scheduled_at).startsWith(month)).map((j) => /* @__PURE__ */ (0, import_jsx_runtime2.jsxs)("p", { children: [
          new Date(j.scheduled_at).toLocaleString(),
          " \u2013 ",
          new Date(j.ends_at).toLocaleTimeString(),
          " \xB7 ",
          j.title,
          " \xB7 ",
          j.status
        ] }, j.id))
      ] }),
      edit && staff && /* @__PURE__ */ (0, import_jsx_runtime2.jsxs)("section", { className: "p-panel", children: [
        /* @__PURE__ */ (0, import_jsx_runtime2.jsx)("h2", { children: edit.id ? "Edit work record" : "Schedule work" }),
        /* @__PURE__ */ (0, import_jsx_runtime2.jsxs)(SaveForm, { busy, onSave: (v) => {
          try {
            return rpc("save_it_job", { p_id: edit.id || null, p_version: edit.version || null, p_kind: view === "audits" ? "Audit" : "Visit", p_site: site, p_project: project || null, p_technician: admin ? v.technician_id : edit.technician_id, p_title: v.title, p_start: admin ? new Date(v.start).toISOString() : edit.scheduled_at, p_end: admin ? new Date(v.end).toISOString() : edit.ends_at, p_work: v.work, p_checklist: String(v.checklist).split("\n").filter((x) => x.trim()).map((x) => ({ title: x.replace(/^\[[ xX]\]\s*/, ""), done: /^\[[xX]\]/.test(x) })), p_findings: view === "audits" ? String(v.findings).split("\n").filter((x) => x.trim()).map((x) => {
              const [severity, title, ...rec] = x.split("|");
              return { severity: severity.trim(), title: title?.trim(), recommendation: rec.join("|").trim() };
            }) : [], p_task: admin ? v.task_id || null : edit.task_id || null, p_evidence: new FormData(document.getElementById("it-evidence")).getAll("file") });
          } catch (e) {
            setError(e.message);
            return Promise.resolve(false);
          }
        }, children: [
          admin && /* @__PURE__ */ (0, import_jsx_runtime2.jsxs)(import_jsx_runtime2.Fragment, { children: [
            /* @__PURE__ */ (0, import_jsx_runtime2.jsxs)("label", { className: "p-field", children: [
              "Site",
              /* @__PURE__ */ (0, import_jsx_runtime2.jsxs)("select", { required: true, value: site, onChange: (e) => {
                setSite(e.target.value);
                setProject("");
              }, children: [
                /* @__PURE__ */ (0, import_jsx_runtime2.jsx)("option", { value: "", children: "Choose site\u2026" }),
                opts(data.client_sites.filter((s) => s.active))
              ] })
            ] }),
            /* @__PURE__ */ (0, import_jsx_runtime2.jsxs)("label", { className: "p-field", children: [
              "Related project",
              /* @__PURE__ */ (0, import_jsx_runtime2.jsxs)("select", { value: project, onChange: (e) => setProject(e.target.value), children: [
                /* @__PURE__ */ (0, import_jsx_runtime2.jsx)("option", { value: "", children: "No project" }),
                opts(projects.filter((p) => p.company_id === data.client_sites.find((s) => s.id === site)?.company_id))
              ] })
            ] }),
            /* @__PURE__ */ (0, import_jsx_runtime2.jsxs)(Input, { name: "task_id", label: "Related maintenance / project task", value: edit.task_id || "", children: [
              /* @__PURE__ */ (0, import_jsx_runtime2.jsx)("option", { value: "", children: "No task" }),
              opts(data.tasks.filter((t) => t.project_id === project && !t.internal))
            ] }, project),
            /* @__PURE__ */ (0, import_jsx_runtime2.jsx)(Input, { name: "technician_id", label: "Technician", required: true, value: edit.technician_id, children: opts(activeStaff) }),
            /* @__PURE__ */ (0, import_jsx_runtime2.jsx)(Input, { name: "start", label: "Appointment start (your timezone)", type: "datetime-local", required: true, value: edit.scheduled_at ? localStamp(edit.scheduled_at) : "" }),
            /* @__PURE__ */ (0, import_jsx_runtime2.jsx)(Input, { name: "end", label: "Appointment end (your timezone)", type: "datetime-local", required: true, value: edit.ends_at ? localStamp(edit.ends_at) : "" })
          ] }),
          /* @__PURE__ */ (0, import_jsx_runtime2.jsx)(Input, { name: "title", label: "Title", value: edit.title, required: true }),
          /* @__PURE__ */ (0, import_jsx_runtime2.jsx)(Input, { name: "work", label: "Work performed / audit scope and summary", type: "textarea", value: edit.work }),
          /* @__PURE__ */ (0, import_jsx_runtime2.jsx)(Input, { name: "checklist", label: "Checklist: one item per line; prefix [x] when completed", type: "textarea", value: (edit.checklist || [{ title: "Review configuration and connectivity", done: false }, { title: "Check security and backups", done: false }]).map((c) => `[${c.done ? "x" : " "}] ${c.title}`).join("\n") }),
          view === "audits" && /* @__PURE__ */ (0, import_jsx_runtime2.jsx)(Input, { name: "findings", label: "Findings: Severity | Title | Recommendation (one per line)", type: "textarea", value: (edit.findings || []).map((f) => `${f.severity} | ${f.title} | ${f.recommendation}`).join("\n") })
        ] }, edit.id || "new-job"),
        /* @__PURE__ */ (0, import_jsx_runtime2.jsxs)("form", { id: "it-evidence", children: [
          /* @__PURE__ */ (0, import_jsx_runtime2.jsx)("h3", { children: "Evidence from project files" }),
          /* @__PURE__ */ (0, import_jsx_runtime2.jsx)("p", { children: "Upload evidence in the project's Files tab, then select it here. Technician uploads remain private until administrator publication." }),
          data.files.filter((f) => f.project_id === project).map((f) => /* @__PURE__ */ (0, import_jsx_runtime2.jsxs)("label", { className: "p-check", children: [
            /* @__PURE__ */ (0, import_jsx_runtime2.jsx)("input", { name: "file", type: "checkbox", value: f.id, defaultChecked: edit.evidence?.includes(f.id) }),
            f.name
          ] }, f.id))
        ] }),
        /* @__PURE__ */ (0, import_jsx_runtime2.jsx)("button", { onClick: () => setEdit(null), children: "Close" })
      ] }),
      jobs.map((j) => /* @__PURE__ */ (0, import_jsx_runtime2.jsxs)("section", { className: "p-panel", children: [
        /* @__PURE__ */ (0, import_jsx_runtime2.jsxs)("h2", { children: [
          j.title,
          " ",
          /* @__PURE__ */ (0, import_jsx_runtime2.jsx)("span", { className: "p-badge", children: j.status })
        ] }),
        /* @__PURE__ */ (0, import_jsx_runtime2.jsxs)("p", { children: [
          data.client_sites.find((s) => s.id === j.site_id)?.name,
          " \xB7 ",
          members.find((m) => m.id === j.technician_id)?.name || "Assigned technician",
          " \xB7 ",
          new Date(j.scheduled_at).toLocaleString(),
          " \u2013 ",
          new Date(j.ends_at).toLocaleString()
        ] }),
        j.task_id && /* @__PURE__ */ (0, import_jsx_runtime2.jsxs)("p", { children: [
          "Related task: ",
          data.tasks.find((t) => t.id === j.task_id)?.title || "Project task"
        ] }),
        /* @__PURE__ */ (0, import_jsx_runtime2.jsx)("p", { className: "p-pre", children: j.work }),
        j.checklist.map((c, i) => /* @__PURE__ */ (0, import_jsx_runtime2.jsxs)("p", { children: [
          c.done ? "\u2713" : "\u25CB",
          " ",
          c.title
        ] }, i)),
        j.findings.map((f, i) => /* @__PURE__ */ (0, import_jsx_runtime2.jsxs)("article", { children: [
          /* @__PURE__ */ (0, import_jsx_runtime2.jsxs)("strong", { children: [
            f.severity,
            ": ",
            f.title
          ] }),
          /* @__PURE__ */ (0, import_jsx_runtime2.jsx)("p", { children: f.recommendation })
        ] }, i)),
        j.evidence.map((id) => /* @__PURE__ */ (0, import_jsx_runtime2.jsxs)("p", { children: [
          "Evidence: ",
          data.files.find((f) => f.id === id)?.name || "Project file",
          " ",
          /* @__PURE__ */ (0, import_jsx_runtime2.jsx)("button", { disabled: busy, onClick: () => act(async () => {
            const f = data.files.find((f2) => f2.id === id);
            if (!f) throw new Error("Refresh project files first");
            const b = check(await db.storage.from("project-files").download(f.path));
            const u = URL.createObjectURL(b);
            const a = document.createElement("a");
            a.href = u;
            a.download = f.name;
            a.click();
            URL.revokeObjectURL(u);
          }), children: "Download evidence" })
        ] }, id)),
        j.client_note && /* @__PURE__ */ (0, import_jsx_runtime2.jsxs)("p", { children: [
          "Client feedback: ",
          j.client_note
        ] }),
        staff && ["Scheduled", "Changes requested"].includes(j.status) && /* @__PURE__ */ (0, import_jsx_runtime2.jsxs)(import_jsx_runtime2.Fragment, { children: [
          /* @__PURE__ */ (0, import_jsx_runtime2.jsx)("button", { disabled: busy, onClick: () => startEdit(j), children: "Edit record" }),
          /* @__PURE__ */ (0, import_jsx_runtime2.jsx)("button", { disabled: busy, onClick: () => jobAction(j, "Submit"), children: "Submit for review" })
        ] }),
        admin && j.status === "Submitted" && /* @__PURE__ */ (0, import_jsx_runtime2.jsxs)(import_jsx_runtime2.Fragment, { children: [
          /* @__PURE__ */ (0, import_jsx_runtime2.jsx)("button", { disabled: busy, onClick: () => jobAction(j, "Publish"), children: "Publish to client" }),
          /* @__PURE__ */ (0, import_jsx_runtime2.jsx)(SaveForm, { busy, label: "Return work for changes", onSave: (v) => jobAction(j, "Return", v.note), children: /* @__PURE__ */ (0, import_jsx_runtime2.jsx)(Input, { name: "note", label: "Administrator review feedback", required: true }) })
        ] }),
        !staff && j.status === "Published" && /* @__PURE__ */ (0, import_jsx_runtime2.jsxs)(import_jsx_runtime2.Fragment, { children: [
          /* @__PURE__ */ (0, import_jsx_runtime2.jsx)("button", { disabled: busy, onClick: () => jobAction(j, "Confirm"), children: "Confirm completion" }),
          /* @__PURE__ */ (0, import_jsx_runtime2.jsx)(SaveForm, { busy, label: "Request changes", onSave: (v) => jobAction(j, "Request changes", v.note), children: /* @__PURE__ */ (0, import_jsx_runtime2.jsx)(Input, { name: "note", label: "Changes required", type: "textarea", required: true }) })
        ] }),
        admin && ["Scheduled", "Submitted", "Changes requested"].includes(j.status) && /* @__PURE__ */ (0, import_jsx_runtime2.jsx)(SaveForm, { busy, label: "Cancel work", onSave: (v) => jobAction(j, "Cancel", v.note), children: /* @__PURE__ */ (0, import_jsx_runtime2.jsx)(Input, { name: "note", label: "Cancellation reason", required: true }) }),
        /* @__PURE__ */ (0, import_jsx_runtime2.jsx)("button", { disabled: busy, onClick: () => act(async () => {
          await downloadReportPDF(`it-${j.kind.toLowerCase()}-${j.id}.pdf`, j.title, `${j.status} | Appointment UTC: ${j.scheduled_at} - ${j.ends_at}`, [{ title: "Work performed", headers: ["Summary"], rows: [[j.work]] }, { title: "Checklist", headers: ["Item", "Complete"], rows: j.checklist.map((c) => [c.title, c.done ? "Yes" : "No"]) }, { title: "Findings", headers: ["Severity", "Finding", "Recommendation"], rows: j.findings.map((f) => [f.severity, f.title, f.recommendation]) }, { title: "Evidence & feedback", headers: ["Evidence", "Client feedback"], rows: [[j.evidence.map((id) => data.files.find((f) => f.id === id)?.name || id).join(", "), j.client_note]] }]);
        }), children: "Download report PDF" }),
        /* @__PURE__ */ (0, import_jsx_runtime2.jsx)("button", { onClick: () => download(`it-${j.kind.toLowerCase()}-${j.id}.txt`, `${j.title}
${j.status}
${j.scheduled_at} \u2014 ${j.ends_at}
${j.work}

Checklist
${j.checklist.map((c) => `${c.done ? "Complete" : "Pending"}: ${c.title}`).join("\n")}

Findings
${j.findings.map((f) => `${f.severity}: ${f.title}
Recommendation: ${f.recommendation}`).join("\n")}
Evidence: ${j.evidence.map((id) => data.files.find((f) => f.id === id)?.name || id).join(", ")}
Client feedback: ${j.client_note}`), children: "Download report (.txt)" }),
        /* @__PURE__ */ (0, import_jsx_runtime2.jsxs)("details", { children: [
          /* @__PURE__ */ (0, import_jsx_runtime2.jsx)("summary", { children: "Published report versions" }),
          data.it_job_reports.filter((r) => r.job_id === j.id).map((r) => /* @__PURE__ */ (0, import_jsx_runtime2.jsxs)("p", { children: [
            "Version ",
            r.version,
            " \xB7 ",
            new Date(r.created_at).toLocaleString(),
            " ",
            /* @__PURE__ */ (0, import_jsx_runtime2.jsx)("button", { onClick: () => download(`it-report-${j.id}-v${r.version}.txt`, JSON.stringify(r.snapshot, null, 2)), children: "Download saved version" })
          ] }, r.id))
        ] }),
        history(j)
      ] }, j.id)),
      !jobs.length && /* @__PURE__ */ (0, import_jsx_runtime2.jsx)("p", { children: "No work records match this view." })
    ] }),
    view === "renewals" && /* @__PURE__ */ (0, import_jsx_runtime2.jsxs)(import_jsx_runtime2.Fragment, { children: [
      /* @__PURE__ */ (0, import_jsx_runtime2.jsx)("p", { children: "Client acceptance records agreement to the proposal. Administrator activation creates a new operational contract; projects keep their current contract until deliberately reassigned. Pricing is a proposal amount, and does not issue an invoice." }),
      edit && admin && /* @__PURE__ */ (0, import_jsx_runtime2.jsxs)("section", { className: "p-panel", children: [
        /* @__PURE__ */ (0, import_jsx_runtime2.jsx)("h2", { children: "Renewal proposal" }),
        /* @__PURE__ */ (0, import_jsx_runtime2.jsxs)(SaveForm, { busy, onSave: (v) => rpc("save_amc_renewal", { p_id: edit.id || null, p_version: edit.version || null, p_contract: edit.contract_id, p_title: v.title, p_start: v.start, p_end: v.end, p_services: v.services, p_targets: Object.fromEntries(priorities.map((p) => [p, { response: Number(v[p + "_response"]), resolution: Number(v[p + "_resolution"]) }])), p_price: Number(v.price), p_currency: v.currency }), children: [
          !edit.id && /* @__PURE__ */ (0, import_jsx_runtime2.jsxs)("label", { className: "p-field", children: [
            "Original contract",
            /* @__PURE__ */ (0, import_jsx_runtime2.jsxs)("select", { required: true, value: edit.contract_id || "", onChange: (e) => {
              const c = data.contracts.find((x) => x.id === e.target.value);
              setEdit({ ...edit, contract_id: c.id, title: c.title + " renewal", services: c.services, targets: c.targets });
            }, children: [
              /* @__PURE__ */ (0, import_jsx_runtime2.jsx)("option", { value: "", children: "Choose contract\u2026" }),
              opts(data.contracts.filter((c) => c.status !== "Cancelled"))
            ] })
          ] }),
          /* @__PURE__ */ (0, import_jsx_runtime2.jsx)(Input, { name: "title", label: "Renewal title", required: true, value: edit.title }),
          /* @__PURE__ */ (0, import_jsx_runtime2.jsx)(Input, { name: "start", label: "Next period start", type: "date", required: true, value: edit.start_date }),
          /* @__PURE__ */ (0, import_jsx_runtime2.jsx)(Input, { name: "end", label: "Next period end", type: "date", required: true, value: edit.end_date }),
          /* @__PURE__ */ (0, import_jsx_runtime2.jsx)(Input, { name: "services", label: "Services and terms", type: "textarea", value: edit.services }),
          /* @__PURE__ */ (0, import_jsx_runtime2.jsxs)("label", { className: "p-field", children: [
            "Agreed renewal price",
            /* @__PURE__ */ (0, import_jsx_runtime2.jsx)("input", { name: "price", type: "number", min: "0", step: "0.01", required: true, defaultValue: edit.price || "0" })
          ] }),
          /* @__PURE__ */ (0, import_jsx_runtime2.jsx)(Input, { name: "currency", label: "Currency (three letters)", value: edit.currency || "PKR", required: true }),
          priorities.map((p) => /* @__PURE__ */ (0, import_jsx_runtime2.jsxs)("div", { className: "p-form-grid", children: [
            /* @__PURE__ */ (0, import_jsx_runtime2.jsx)(Input, { name: p + "_response", label: p + " response minutes", type: "number", required: true, value: edit.targets?.[p]?.response ?? contract?.targets[p].response }),
            /* @__PURE__ */ (0, import_jsx_runtime2.jsx)(Input, { name: p + "_resolution", label: p + " resolution minutes", type: "number", required: true, value: edit.targets?.[p]?.resolution ?? contract?.targets[p].resolution })
          ] }, p))
        ] }, edit.contract_id || edit.id),
        /* @__PURE__ */ (0, import_jsx_runtime2.jsx)("button", { onClick: () => setEdit(null), children: "Close" })
      ] }),
      data.amc_renewals.map((r) => /* @__PURE__ */ (0, import_jsx_runtime2.jsxs)("section", { className: "p-panel", children: [
        /* @__PURE__ */ (0, import_jsx_runtime2.jsxs)("h2", { children: [
          r.title,
          " ",
          /* @__PURE__ */ (0, import_jsx_runtime2.jsx)("span", { className: "p-badge", children: r.status })
        ] }),
        /* @__PURE__ */ (0, import_jsx_runtime2.jsxs)("p", { children: [
          shortDate(r.start_date),
          " \u2013 ",
          shortDate(r.end_date),
          " \xB7 ",
          r.currency,
          " ",
          r.price
        ] }),
        /* @__PURE__ */ (0, import_jsx_runtime2.jsx)("p", { className: "p-pre", children: r.services }),
        priorities.map((p) => /* @__PURE__ */ (0, import_jsx_runtime2.jsxs)("p", { children: [
          p,
          ": response ",
          r.targets[p].response,
          " min / resolution ",
          r.targets[p].resolution,
          " min \xB7 24/7"
        ] }, p)),
        r.client_note && /* @__PURE__ */ (0, import_jsx_runtime2.jsxs)("p", { children: [
          "Client note: ",
          r.client_note
        ] }),
        admin && r.status === "Draft" && /* @__PURE__ */ (0, import_jsx_runtime2.jsxs)(import_jsx_runtime2.Fragment, { children: [
          /* @__PURE__ */ (0, import_jsx_runtime2.jsx)("button", { onClick: () => startEdit(r), children: "Edit draft" }),
          /* @__PURE__ */ (0, import_jsx_runtime2.jsx)("button", { disabled: busy, onClick: () => renewalAction(r, "Publish"), children: "Publish proposal" })
        ] }),
        !staff && r.status === "Published" && /* @__PURE__ */ (0, import_jsx_runtime2.jsxs)(SaveForm, { busy, label: "Record decision", onSave: (v) => renewalAction(r, v.decision, v.note), children: [
          /* @__PURE__ */ (0, import_jsx_runtime2.jsxs)(Input, { name: "decision", label: "Decision", children: [
            /* @__PURE__ */ (0, import_jsx_runtime2.jsx)("option", { value: "", children: "Choose decision\u2026" }),
            /* @__PURE__ */ (0, import_jsx_runtime2.jsx)("option", { children: "Accept" }),
            /* @__PURE__ */ (0, import_jsx_runtime2.jsx)("option", { children: "Decline" })
          ] }),
          /* @__PURE__ */ (0, import_jsx_runtime2.jsxs)("label", { className: "p-check", children: [
            /* @__PURE__ */ (0, import_jsx_runtime2.jsx)("input", { type: "checkbox", required: true }),
            "I am authorized to record this company's decision."
          ] }),
          /* @__PURE__ */ (0, import_jsx_runtime2.jsx)(Input, { name: "note", label: "Decision note", type: "textarea" })
        ] }),
        admin && r.status === "Accepted" && /* @__PURE__ */ (0, import_jsx_runtime2.jsx)("button", { disabled: busy, onClick: () => renewalAction(r, "Activate"), children: "Activate new contract period" }),
        admin && ["Draft", "Published"].includes(r.status) && /* @__PURE__ */ (0, import_jsx_runtime2.jsx)(SaveForm, { busy, label: "Withdraw proposal", onSave: (v) => renewalAction(r, "Withdraw", v.note), children: /* @__PURE__ */ (0, import_jsx_runtime2.jsx)(Input, { name: "note", label: "Withdrawal reason", required: true }) }),
        r.new_contract_id && /* @__PURE__ */ (0, import_jsx_runtime2.jsxs)("p", { children: [
          "New contract ID: ",
          r.new_contract_id
        ] }),
        history(r)
      ] }, r.id)),
      !data.amc_renewals.length && /* @__PURE__ */ (0, import_jsx_runtime2.jsx)("p", { children: "No renewal proposals yet." })
    ] })
  ] });
}
// Annotate the CommonJS export names for ESM import in node:
0 && (module.exports = {
  ItOperations
});
/*! Bundled license information:

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
