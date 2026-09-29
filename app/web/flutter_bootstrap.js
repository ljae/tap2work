{{flutter_js}}
{{flutter_build_config}}

// Discover renderer dependencies while main.dart.js is still downloading.
const kit = document.createElement('link');
kit.rel = 'preload'; kit.as = 'fetch'; kit.crossOrigin = 'anonymous';
kit.href = 'canvaskit/chromium/canvaskit.wasm';
if (window.chrome) document.head.appendChild(kit);
_flutter.loader.load({
  config: { canvasKitBaseUrl: 'canvaskit/' },
  onEntrypointLoaded: async (engineInitializer) => {
    try {
      const appRunner = await engineInitializer.initializeEngine();
      await appRunner.runApp();
    } catch (_) {
      window.tap2workBootFailed?.();
    }
  },
}).catch(() => window.tap2workBootFailed?.());
