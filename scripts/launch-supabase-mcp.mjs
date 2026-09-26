// Keep this Codex MCP connection scoped to tap2work without modifying another project's launcher.
import { readFileSync } from 'node:fs';
import { spawn } from 'node:child_process';
import { parseEnv } from 'node:util';

const expectedRef = 'sgpmhqtaylgqymeqciin';
let localEnv;
try {
  localEnv = parseEnv(readFileSync(new URL('../.env', import.meta.url), 'utf8'));
} catch {
  process.stderr.write('tap2work .env를 읽을 수 없습니다.\n');
  process.exit(1);
}

if (localEnv.SUPABASE_PROJECT_REF !== expectedRef || !localEnv.SUPABASE_ACCESS_TOKEN) {
  process.stderr.write('tap2work Supabase 프로젝트 참조값과 액세스 토큰을 확인해 주세요.\n');
  process.exit(1);
}

if (process.argv.includes('--check')) process.exit(0);

const server = spawn('npx', ['-y', '@supabase/mcp-server-supabase@latest', '--project-ref', expectedRef], {
  stdio: 'inherit',
  env: { ...process.env, SUPABASE_ACCESS_TOKEN: localEnv.SUPABASE_ACCESS_TOKEN },
});
server.on('error', () => {
  process.stderr.write('tap2work Supabase MCP 서버를 시작하지 못했습니다.\n');
  process.exitCode = 1;
});
server.on('exit', (code) => { process.exitCode = code ?? 1; });
