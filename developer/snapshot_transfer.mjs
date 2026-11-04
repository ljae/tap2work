import {createHash} from 'node:crypto';

// These are already permission-filtered fields, never raw workspace documents.
export const retainedSnapshotFields=Object.freeze([
  'manualCatalog','storeSetupCatalog','checklistLibrary','checklistBackup',
  'manualPrintTemplates','manualSearch','taskTemplates','recommendedTaps',
]);

export function snapshotFieldHash(value){
  return createHash('sha256').update(JSON.stringify(value)).digest('hex');
}

export function compactSnapshot(snapshot, query){
  if(query.get('sync')!=='fields-v1')return snapshot;
  const raw=query.get('fields');
  let known={};
  try{if(raw&&raw.length<=2048)known=JSON.parse(raw);}catch{ /* Send a complete snapshot. */ }
  if(!known||typeof known!=='object'||Array.isArray(known))known={};
  const result={...snapshot};const retained=[];const hashes={};
  for(const field of retainedSnapshotFields){
    // A field omitted by current permissions must never be restored by a client.
    if(!Object.hasOwn(snapshot,field))continue;
    hashes[field]=snapshotFieldHash(snapshot[field]);
    if(hashes[field]!==known[field])continue;
    delete result[field];retained.push(field);
  }
  result.fieldHashes=hashes;
  if(retained.length)result.retainedFields=retained;
  return result;
}
