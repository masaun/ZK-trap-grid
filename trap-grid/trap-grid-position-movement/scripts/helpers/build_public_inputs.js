"use strict";
/**
 * Build public_inputs file from Prover.toml
 *
 * This script reads the Prover.toml file and extracts the public inputs,
 * then writes them to a binary file in the correct format for the verifier.
 *
 * Public inputs order (17 fields, each 32 bytes):
 * 1. trap_merkle_root (Field)
 * 2. move_x (u32)
 * 3. move_y (u32)
 * 4. is_hit (u32)
 * 5. trap_merkle_proof_length (u32)
 * 6-11. trap_merkle_proof_indices (6 x u1)
 * 12-17. trap_merkle_proof_siblings (6 x Field)
 */
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || (function () {
    var ownKeys = function(o) {
        ownKeys = Object.getOwnPropertyNames || function (o) {
            var ar = [];
            for (var k in o) if (Object.prototype.hasOwnProperty.call(o, k)) ar[ar.length] = k;
            return ar;
        };
        return ownKeys(o);
    };
    return function (mod) {
        if (mod && mod.__esModule) return mod;
        var result = {};
        if (mod != null) for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
        __setModuleDefault(result, mod);
        return result;
    };
})();
Object.defineProperty(exports, "__esModule", { value: true });
const fs = __importStar(require("fs"));
const path = __importStar(require("path"));
function parseToml(content) {
    const lines = content.split('\n');
    const data = {};
    let currentSection = null;
    for (const line of lines) {
        const trimmed = line.trim();
        if (!trimmed || trimmed.startsWith('#'))
            continue;
        // Section header
        if (trimmed.startsWith('[') && trimmed.endsWith(']')) {
            currentSection = trimmed.slice(1, -1);
            data[currentSection] = {};
            continue;
        }
        // Key-value pair
        const match = trimmed.match(/^(\w+)\s*=\s*(.+)$/);
        if (match) {
            const [, key, value] = match;
            let parsed;
            if (value.startsWith('[')) {
                // Array
                parsed = value
                    .slice(1, -1)
                    .split(',')
                    .map(v => v.trim().replace(/"/g, ''));
            }
            else {
                // String or number
                parsed = value.replace(/"/g, '');
            }
            if (currentSection) {
                data[currentSection][key] = parsed;
            }
            else {
                data[key] = parsed;
            }
        }
    }
    return data;
}
function hexToBytes32(hex) {
    // Remove 0x prefix if present
    const cleanHex = hex.startsWith('0x') ? hex.slice(2) : hex;
    // Pad to 64 hex chars (32 bytes)
    const padded = cleanHex.padStart(64, '0');
    return Buffer.from(padded, 'hex');
}
function u32ToBytes32(value) {
    const num = BigInt(value);
    const buf = Buffer.alloc(32);
    // Write as big-endian in the last 4 bytes
    buf.writeBigUInt64BE(num >> 32n, 24);
    buf.writeUInt32BE(Number(num & 0xffffffffn), 28);
    return buf;
}
function u1ToBytes32(value) {
    return u32ToBytes32(value);
}
function fieldToBytes32(value) {
    return hexToBytes32(value);
}
// Main execution
const proverTomlPath = path.join(__dirname, '../../Prover.toml');
const outputPath = path.join(__dirname, '../../target', 'public_inputs');
// Read and parse Prover.toml
const tomlContent = fs.readFileSync(proverTomlPath, 'utf-8');
const data = parseToml(tomlContent);
// Extract public inputs (they might be at root level or in public_inputs section)
const publicInputs = (data.public_inputs || data);
// Build the 17 fields (each 32 bytes)
const fields = [];
// 1. trap_merkle_root (Field)
fields.push(fieldToBytes32(publicInputs.trap_merkle_root));
// 2. move_x (u32)
fields.push(u32ToBytes32(publicInputs.move_x));
// 3. move_y (u32)
fields.push(u32ToBytes32(publicInputs.move_y));
// 4. is_hit (u32)
fields.push(u32ToBytes32(publicInputs.is_hit));
// 5. trap_merkle_proof_length (u32)
fields.push(u32ToBytes32(publicInputs.trap_merkle_proof_length));
// 6-11. trap_merkle_proof_indices (6 x u1)
const indices = Array.isArray(publicInputs.trap_merkle_proof_indices)
    ? publicInputs.trap_merkle_proof_indices
    : [];
for (let i = 0; i < 6; i++) {
    const value = indices[i] || '0';
    fields.push(u1ToBytes32(value));
}
// 12-17. trap_merkle_proof_siblings (6 x Field)
const siblings = Array.isArray(publicInputs.trap_merkle_proof_siblings)
    ? publicInputs.trap_merkle_proof_siblings
    : [];
for (let i = 0; i < 6; i++) {
    const value = siblings[i] || '0x0';
    fields.push(fieldToBytes32(value));
}
// Combine all fields
const publicInputsBuffer = Buffer.concat(fields);
// Ensure output directory exists
const targetDir = path.dirname(outputPath);
if (!fs.existsSync(targetDir)) {
    fs.mkdirSync(targetDir, { recursive: true });
}
// Write to file
fs.writeFileSync(outputPath, publicInputsBuffer);
console.log(`✓ Generated public_inputs file: ${publicInputsBuffer.length} bytes`);
console.log(`  Expected: ${17 * 32} bytes`);
