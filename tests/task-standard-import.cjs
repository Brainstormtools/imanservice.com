const assert=require('node:assert/strict'),fs=require('node:fs'),path=require('node:path'),{buildSync}=require('esbuild');
const dir=fs.mkdtempSync(path.join(__dirname,'standard-map-'));
try{
 const file=path.join(dir,'bundle.cjs');buildSync({entryPoints:[path.resolve(__dirname,'../src/portal/task-standard-import.ts')],bundle:true,platform:'node',outfile:file});const {standardImportFields:f,mapStandardRows:map}=require(file),mapping=Object.fromEntries(f.map((k,i)=>[k,String(i)]));
 const row=['Survey','survey','0','Survey task','Survey','Inspect','node','30.5','0','2','2','Technician','Tester','Access','Check route\nCheck label'];
 const run=(r=row,m=mapping)=>map([f,r],m);let v=run()[0];assert.equal(v.task.minutes,30.5);assert.deepEqual(v.task.checklist,['Check route','Check label']);console.log('PASS Explicit decimal minutes, zero setup and multiline checklist preserved');
 assert.equal(v.task.fixed_quantity,2);assert.deepEqual(v.task.quantity_parameters,[]);assert.deepEqual(v.task.depends_on,[]);console.log('PASS Fixed standard has no inferred formula or predecessor');
 const reverse=f.slice().reverse();assert.deepEqual(map([reverse,row.slice().reverse()],Object.fromEntries(f.map(k=>[k,String(reverse.indexOf(k))]))),run());console.log('PASS Reordered source columns map explicitly');
 for(const [label,k,value] of [['missing minutes','minutes',''],['negative time','minutes','-1'],['typed duration','minutes','30 min'],['formula','minutes','=1+2'],['NaN','minutes','NaN'],['infinity','minutes','Infinity'],['too large','minutes','100001'],['fractional crew','crew','1.5'],['zero crew','crew','0'],['fractional phase','phase','0.5'],['phase range','phase','6'],['invalid key','key','Survey'],['missing title','title',''],['blank checklist line','checklist','One\n\nTwo']]){const r=row.slice();r[f.indexOf(k)]=value;assert.throws(()=>run(r));console.log('PASS '+label+' rejected');}
 assert.throws(()=>map([f,row,row],mapping),/Duplicate/);console.log('PASS Duplicate batch names/keys rejected');
 assert.throws(()=>run(row,{...mapping,crew:mapping.minutes}),/distinct/);assert.throws(()=>run(row,{...mapping,minutes:'-1'}),/required/);console.log('PASS Missing and overlapping mappings rejected');
 assert.throws(()=>map([f,...Array(101).fill(row)],mapping),/1–100/);console.log('PASS Import row bounds enforced');
 const r=row.slice();r[f.indexOf('tools')]='x'.repeat(2001);assert.throws(()=>run(r));console.log('PASS Long field bound enforced');
}finally{fs.rmSync(dir,{recursive:true,force:true});}
