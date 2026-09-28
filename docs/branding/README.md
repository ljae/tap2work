# Current branding

The current route/check mark is generated from `app/assets/branding/generate_brand.py`. On 2026-09-28 the user requested removal of the white background: the 1024px root `tap2work.png` and Flutter asset now use transparent RGBA outside the existing rounded mark. Internal cream route and coral dots are preserved. `scripts/sync-branding.mjs` keeps the Flutter copy identical.

Ordinary web icons/favicon are transparent PNG. Native launcher and PWA maskable icons use a full-bleed teal background for opaque artwork. Native device/build validation is not claimed. Menu artwork is unchanged.
