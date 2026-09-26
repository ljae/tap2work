// Run with node --env-file=.env. Never print tokens or database connection strings.
import { readFile, readdir } from 'node:fs/promises';
import { spawnSync } from 'node:child_process';
const { SUPABASE_ACCESS_TOKEN: token, SUPABASE_PROJECT_REF: ref } = process.env;
if (!token || !ref) throw new Error('Set SUPABASE_ACCESS_TOKEN and SUPABASE_PROJECT_REF in .env');
const directory = new URL('../supabase/migrations/', import.meta.url);
for (const filename of (await readdir(directory)).filter(name => /^\d+.*\.sql$/.test(name)).sort()) {
  const query = await readFile(new URL(filename, directory), 'utf8');
  const response = await fetch(`https://api.supabase.com/v1/projects/${ref}/database/query`, {
    method: 'POST', headers: { Authorization: `Bearer ${token}`, 'Content-Type': 'application/json' }, body: JSON.stringify({ query }),
  });
  if (!response.ok) { console.error('Migration failed:', filename, 'HTTP', response.status); process.exit(1); }
  console.log('Migration applied:', filename);
}
const result = spawnSync('supabase', ['functions', 'deploy', 'operations', '--project-ref', ref, '--use-api'], { env: process.env, stdio: 'inherit' });
process.exitCode = result.status ?? 1;
