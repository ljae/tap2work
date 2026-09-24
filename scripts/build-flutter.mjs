// Only explicitly allowlisted PUBLIC settings enter the browser bundle.
import { spawnSync } from 'node:child_process';
const review = process.argv.includes('--review');
const args = ['build','web','--release','--base-href',review ? '/' : '/app/','--pwa-strategy=none','--no-web-resources-cdn'];
if (review) args.push('--dart-define=PUBLIC_REVIEW=true','--output=build/review-web');
const url = process.env.SUPABASE_URL, key = process.env.SUPABASE_PUBLISHABLE_KEY;
if (url && key) {
  if (!key.startsWith('sb_publishable_')) throw Error('SUPABASE_PUBLISHABLE_KEY must be a public publishable key. Secret/service keys are forbidden in Flutter builds.');
  if (!/^https:\/\/[a-z0-9-]+\.supabase\.co\/?$/.test(url)) throw Error('Invalid SUPABASE_URL');
  args.push(`--dart-define=SUPABASE_URL=${url.replace(/\/$/,'')}`,`--dart-define=SUPABASE_PUBLISHABLE_KEY=${key}`);
}
const result = spawnSync('flutter', args, { cwd: new URL('../app',import.meta.url), env: process.env, stdio:'inherit' });
process.exitCode = result.status ?? 1;
