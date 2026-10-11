{{flutter_js}}
{{flutter_build_config}}

// Discover renderer dependencies while main.dart.js is still downloading.
const kit = document.createElement('link');
kit.rel = 'preload'; kit.as = 'fetch'; kit.crossOrigin = 'anonymous';
kit.href = 'canvaskit/chromium/canvaskit.wasm';
if (window.chrome) document.head.appendChild(kit);
const engineConfig = { canvasKitBaseUrl: 'canvaskit/' };
_flutter.loader.load({
  config: engineConfig,
  onEntrypointLoaded: async (engineInitializer) => {
    try {
      const appRunner = await engineInitializer.initializeEngine(engineConfig);
      await appRunner.runApp();
    } catch (_) {
      window.tap2workBootFailed?.();
    }
  },
}).catch(() => window.tap2workBootFailed?.());
