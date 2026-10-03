import { createHash } from 'node:crypto';
import { readFile, writeFile } from 'node:fs/promises';
import { join } from 'node:path';

const digest = value => createHash('sha256').update(value).digest('hex').slice(0, 20);

// Pages caches stable URLs. Version both the loader and its entrypoint so a new
// document cannot accidentally pair with an older cached Flutter application.
// Keep stable files for already cached documents during the deployment transition.
export async function versionWebAssets(directory) {
  const main = await readFile(join(directory, 'main.dart.js'));
  const bootstrap = await readFile(join(directory, 'flutter_bootstrap.js'), 'utf8');
  const html = await readFile(join(directory, 'index.html'), 'utf8');
  if (!bootstrap.includes('"mainJsPath":"main.dart.js"') ||
      !html.includes('href="main.dart.js"') ||
      !html.includes('src="flutter_bootstrap.js"')) {
    throw Error('Flutter web entrypoint format changed; refusing an unversioned deployment.');
  }
  const mainName = `main.${digest(main)}.dart.js`;
  const versionedBootstrap = bootstrap.replaceAll('"mainJsPath":"main.dart.js"', `"mainJsPath":"${mainName}"`);
  const bootstrapName = `flutter_bootstrap.${digest(versionedBootstrap)}.js`;
  await writeFile(join(directory, mainName), main);
  await writeFile(join(directory, bootstrapName), versionedBootstrap);
  await writeFile(join(directory, 'index.html'), html
    .replaceAll('href="main.dart.js"', `href="${mainName}"`)
    .replaceAll('src="flutter_bootstrap.js"', `src="${bootstrapName}"`));
  return { mainName, bootstrapName };
}
