"""Package the supplied TAP Work artwork at platform-required sizes.

No redraw, crop, or recoloring: the original is versioned under docs/branding.
"""
from pathlib import Path
from PIL import Image
import json

ROOT = Path(__file__).resolve().parents[3]
source = Image.open(ROOT / 'docs/branding/TapWater_logo.png').convert('RGBA')
if source.width != source.height:
    raise ValueError('The approved TAP Work source must be square.')
# The supplied alpha is fully opaque. Export RGB so iOS icons have no alpha.
if source.getchannel('A').getextrema() != (255, 255):
    raise ValueError('The approved source must have an opaque background.')
source = source.convert('RGB')
base = source.resize((1024, 1024), Image.Resampling.LANCZOS)
brand = ROOT / 'app/assets/branding/tap2work.png'
display = base.resize((256, 256), Image.Resampling.LANCZOS)
display.save(brand, optimize=True)
display.save(ROOT / 'tap2work.png', optimize=True)
# Maskable icons keep the complete square artwork inside the central safe circle.
maskable = Image.new('RGB', (1024, 1024), 'white')
inset = source.resize((576, 576), Image.Resampling.LANCZOS)
maskable.paste(inset, (224, 224))
web = ROOT / 'app/web'
for name, size in [('favicon.png', 64), ('icons/Icon-192.png', 192),
                   ('icons/Icon-512.png', 512), ('icons/Icon-maskable-192.png', 192),
                   ('icons/Icon-maskable-512.png', 512)]:
    artwork = maskable if 'maskable' in name else base
    artwork.resize((size, size), Image.Resampling.LANCZOS).save(web/name, optimize=True)
android = ROOT / 'app/android/app/src/main/res'
for density, size in [('mdpi', 48), ('hdpi', 72), ('xhdpi', 96),
                      ('xxhdpi', 144), ('xxxhdpi', 192)]:
    base.resize((size, size), Image.Resampling.LANCZOS).save(
        android / f'mipmap-{density}/ic_launcher.png', optimize=True)
ios = ROOT / 'app/ios/Runner/Assets.xcassets/AppIcon.appiconset'
for entry in json.loads((ios / 'Contents.json').read_text())['images']:
    if 'filename' not in entry:
        continue
    size = round(float(entry['size'].split('x')[0]) * float(entry['scale'][:-1]))
    base.resize((size, size), Image.Resampling.LANCZOS).save(
        ios / entry['filename'], optimize=True)
print('Packaged supplied TAP Work logo and web, Android, iOS icons')
