import * as fs from 'fs';
import * as path from 'path';

interface AbiType {
  kind: string;
  length?: number;
  type?: AbiType;
  fields?: Array<{ type: AbiType }>;
}

interface AbiParameter {
  visibility: string;
  type: AbiType;
}

interface CircuitAbi {
  abi: {
    parameters: AbiParameter[];
  };
}

const abiPath = path.join(__dirname, '../../target/trap_grid.json');
const abiData: CircuitAbi = JSON.parse(fs.readFileSync(abiPath, 'utf-8'));

const publicParam = abiData.abi.parameters.find(p => p.visibility === 'public');

if (!publicParam) {
  process.stdout.write('0');
  process.exit(0);
}

const flatten = (t: AbiType): number => {
  return t.kind === 'array' && t.length && t.type 
    ? t.length * flatten(t.type) 
    : 1;
};

const flattenStruct = (t: AbiType): number => {
  return t.kind === 'struct' && t.fields
    ? t.fields.reduce((sum, field) => sum + flatten(field.type), 0)
    : flatten(t);
};

process.stdout.write(String(flattenStruct(publicParam.type)));
