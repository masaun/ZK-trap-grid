const abi = require('../../target/trap_grid.json').abi;
const n = abi.parameters.find(p => p.visibility === 'public');
if (!n) {
  process.stdout.write('0');
  process.exit(0);
}

const flatten = t => t.kind === 'array' ? t.length * flatten(t.type) : 1;
const flattenStruct = t => t.kind === 'struct' ? t.fields.reduce((s,f)=>s+flatten(f.type),0) : flatten(t);
process.stdout.write(String(flattenStruct(n.type)));
