import { createHash } from 'node:crypto';
import { cp, readdir, readFile, writeFile } from 'node:fs/promises';
import { join } from 'node:path';

const digest = value => createHash('sha256').update(value).digest('hex').slice(0, 20);

async function assetRevision(directory) {
  const hash = createHash('sha256');
  async function visit(path, relative = '') {
    const entries = (await readdir(path, { withFileTypes: true })).sort((a, b) => a.name.localeCompare(b.name, 'en'));
    for (const entry of entries) {
      const name = `${relative}${entry.name}`;
      if (entry.isDirectory()) await visit(join(path, entry.name), `${name}/`);
      else {
        hash.update(name).update('\0').update(digest(await readFile(join(path, entry.name)))).update('\0');
      }
    }
  }
  await visit(join(directory, 'assets'));
  return hash.digest('hex').slice(0, 20);
}

// Pages caches stable URLs. Version both the loader and its entrypoint so a new
// document cannot accidentally pair with an older cached Flutter application.
// Keep stable files for already cached documents during the deployment transition.
export async function versionWebAssets(directory) {
  const main = await readFile(join(directory, 'main.dart.js'));
  const bootstrap = await readFile(join(directory, 'flutter_bootstrap.js'), 'utf8');
  const html = await readFile(join(directory, 'index.html'), 'utf8');
  const mainHref = /href="main(?:\.[a-f0-9]{20})?\.dart\.js"/g;
  const loaderSrc = /src="flutter_bootstrap(?:\.[a-f0-9]{20})?\.js"/g;
  const loaderConfig = "const engineConfig = { canvasKitBaseUrl: 'canvaskit/' };";
  if (!bootstrap.includes('"mainJsPath":"main.dart.js"') ||
      !bootstrap.includes(loaderConfig) ||
      !html.match(mainHref) ||
      !html.match(loaderSrc)) {
    throw Error('Flutter web entrypoint format changed; refusing an unversioned deployment.');
  }
  const mainName = `main.${digest(main)}.dart.js`;
  const assetBase = `assets.${await assetRevision(directory)}/`;
  // Flutter appends assets/ to assetBase when resolving a logical asset key.
  await cp(join(directory, 'assets'), join(directory, assetBase, 'assets'), { recursive: true });
  const versionedBootstrap = bootstrap
    .replaceAll('"mainJsPath":"main.dart.js"', `"mainJsPath":"${mainName}"`)
    .replace(loaderConfig, `const engineConfig = { canvasKitBaseUrl: 'canvaskit/', assetBase: '${assetBase}' };`);
  const bootstrapName = `flutter_bootstrap.${digest(versionedBootstrap)}.js`;
  await writeFile(join(directory, mainName), main);
  await writeFile(join(directory, bootstrapName), versionedBootstrap);
  await writeFile(join(directory, 'index.html'), html
    .replace(mainHref, `href="${mainName}"`)
    .replace(loaderSrc, `src="${bootstrapName}"`));
  return { mainName, bootstrapName, assetBase };
}
