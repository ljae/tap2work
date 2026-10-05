// Only explicitly allowlisted PUBLIC settings enter the browser bundle.
import { spawnSync } from 'node:child_process';
import { fileURLToPath } from 'node:url';
import { versionWebAssets } from './version-web-assets.mjs';
await import('./build-legal.mjs');
const review = process.argv.includes('--review');
const args = ['build','web','--release','--base-href',review ? '/' : '/app/','--pwa-strategy=none','--no-web-resources-cdn'];
if (process.env.FLUTTER_SKIP_PUB === '1') args.push('--no-pub');
if (review) args.push('--dart-define=PUBLIC_REVIEW=true','--output=build/review-web');
const url = process.env.SUPABASE_URL, key = process.env.SUPABASE_PUBLISHABLE_KEY;
if (review && (!url || !key)) throw Error('Public app requires Supabase configuration for saved workspaces.');
if (url && key) {
  if (!key.startsWith('sb_publishable_')) throw Error('SUPABASE_PUBLISHABLE_KEY must be a public publishable key. Secret/service keys are forbidden in Flutter builds.');
  if (!/^https:\/\/[a-z0-9-]+\.supabase\.co\/?$/.test(url)) throw Error('Invalid SUPABASE_URL');
  args.push(`--dart-define=SUPABASE_URL=${url.replace(/\/$/,'')}`,`--dart-define=SUPABASE_PUBLISHABLE_KEY=${key}`);
}
const result = spawnSync('flutter', args, { cwd: new URL('../app',import.meta.url), env: process.env, stdio:'inherit' });
process.exitCode = result.status ?? 1;

if (result.status === 0) {
  await versionWebAssets(fileURLToPath(new URL(review ? '../app/build/review-web' : '../app/build/web', import.meta.url)));
}
