// Produces only public build configuration; secrets never enter the app bundle.
import {mkdir, writeFile} from 'node:fs/promises';
const config = {};
for (const key of ['GOOGLE_IOS_CLIENT_ID','GOOGLE_WEB_CLIENT_ID']) {
  const value = process.env[key]?.trim();
  if (!value || !/^[a-zA-Z0-9-]+\.apps\.googleusercontent\.com$/.test(value)) {
    throw new Error(`${key} must be a Google OAuth client ID. See docs/NATIVE_AUTH_SETUP.md`);
  }
  config[key] = value;
}
const url=process.env.SUPABASE_URL, key=process.env.SUPABASE_PUBLISHABLE_KEY;
if (!/^https:\/\/[a-z0-9-]+\.supabase\.co\/?$/.test(url??'') || !key?.startsWith('sb_publishable_')) {
  throw new Error('SUPABASE_URL and a public SUPABASE_PUBLISHABLE_KEY are required.');
}
config.SUPABASE_URL=url.replace(/\/$/,'');
config.SUPABASE_PUBLISHABLE_KEY=key;
await mkdir(new URL('../.local/',import.meta.url),{recursive:true});
await writeFile(new URL('../.local/native-auth.json',import.meta.url),JSON.stringify(config,null,2)+'\n');
const reverse=config.GOOGLE_IOS_CLIENT_ID.split('.').reverse().join('.');
await writeFile(new URL('../app/ios/Flutter/Auth.xcconfig',import.meta.url),`// Generated public OAuth callback. Do not edit.\nGOOGLE_REVERSED_CLIENT_ID = ${reverse}\n`);
console.log('Generated .local/native-auth.json and app/ios/Flutter/Auth.xcconfig (public values only).');
