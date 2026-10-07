// Optional isolated PostgreSQL integration harness. Install @electric-sql/pglite
// outside the source tree, then pass --pglite-module=/absolute/package/dist/index.js.
// No live database credentials are read or used.
import {readFile} from 'node:fs/promises';
import {pathToFileURL} from 'node:url';
const moduleArgument=process.argv.find(arg=>arg.startsWith('--pglite-module='));
const moduleName=moduleArgument ? pathToFileURL(moduleArgument.slice('--pglite-module='.length)).href : '@electric-sql/pglite';
const {PGlite}=await import(moduleName);
const db=new PGlite();
try {
  await db.exec(`create schema auth; create table auth.users(id uuid primary key); create role anon; create role authenticated; create role service_role bypassrls; grant usage on schema public to anon,authenticated,service_role;`);
  await db.exec(await readFile(new URL('../supabase/migrations/20261007010000_content_catalog.sql',import.meta.url),'utf8'));
  await db.exec('begin');
  const results=await db.exec(await readFile(new URL('../developer/test/content_catalog.sql',import.meta.url),'utf8'));
  console.log(results.at(-1).rows[0].verification);
  await db.exec('rollback');
  // Full checked-in release seed also proves UTF-8/JSONB round-trip preserves the
  // existing catalog ID and all taxonomy/source/Task values.
  const release=JSON.parse(await readFile(new URL('../docs/market/current.json',import.meta.url),'utf8'));
  const seeded=await db.query('select public.tap2work_catalog_seed(null,$1::jsonb,$2,gen_random_uuid()) as result',[JSON.stringify(release),release.releaseId]);
  const read=await db.query('select public.tap2work_catalog_read() as result');
  const expected=JSON.stringify(canonical(release));
  if(JSON.stringify(canonical(read.rows[0].result.release))!==expected || seeded.rows[0].result.releaseId!==release.releaseId)throw Error('Checked-in release changed across DB seed/read');
  console.log(`Exact checked-in release seed/read passed (${release.entries.length} TAPs).`);
} finally { await db.close(); }
function canonical(value){if(Array.isArray(value))return value.map(canonical);if(value&&typeof value==='object')return Object.fromEntries(Object.keys(value).sort().map(key=>[key,canonical(value[key])]));return value;}
