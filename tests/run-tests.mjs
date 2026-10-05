import {readdir} from 'node:fs/promises';
import {spawnSync} from 'node:child_process';
const files=(await readdir(new URL('.',import.meta.url))).filter(f=>/\.(mjs|cjs)$/.test(f)&&f!=='run-tests.mjs').sort();
let count=0;
for(const file of files){const r=spawnSync(process.execPath,[`tests/${file}`],{encoding:'utf8',env:{...process.env,TZ:'UTC'},maxBuffer:10*1024*1024});if(r.status!==0){console.error(`FAIL ${file}\n${r.stdout}\n${r.stderr}`);process.exit(r.status||1);}const n=(r.stdout.match(/^PASS\b/gm)||[]).length;count+=n;console.log(`${file}: ${n} checks passed`);}
console.log(`${count} checks passed across ${files.length} suites`);
