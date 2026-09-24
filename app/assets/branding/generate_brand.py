"""Generate tap2work's route/check symbol and platform icon sizes."""
from pathlib import Path
from PIL import Image, ImageDraw
import re

ROOT = Path(__file__).resolve().parents[3]
SIZE = 1024
SCALE = 4
navy = '#193B3A'
cream = '#FFF9F0'
coral = '#E45B42'
image = Image.new('RGB', (SIZE * SCALE, SIZE * SCALE), cream)
d = ImageDraw.Draw(image)
def box(coords, radius, fill):
    d.rounded_rectangle(tuple(round(v*SCALE) for v in coords), radius=radius*SCALE, fill=fill)
def ellipse(coords, fill):
    d.ellipse(tuple(round(v*SCALE) for v in coords), fill=fill)
box((52, 52, 972, 972), 220, navy)
# One continuous route through two compact work steps.
box((239, 277, 675, 351), 37, cream)
box((601, 277, 675, 640), 37, cream)
box((378, 566, 675, 640), 37, cream)
box((378, 566, 452, 735), 37, cream)
ellipse((218, 245, 352, 379), coral)
ellipse((344, 693, 486, 835), coral)
base = image.resize((SIZE, SIZE), Image.Resampling.LANCZOS)
brand = ROOT / 'app/assets/branding/tap2work.png'
base.save(brand, optimize=True)
base.save(ROOT / 'tap2work.png', optimize=True)
web = ROOT / 'app/web'
for name, size in [('favicon.png', 64), ('icons/Icon-192.png', 192),
                   ('icons/Icon-512.png', 512), ('icons/Icon-maskable-192.png', 192),
                   ('icons/Icon-maskable-512.png', 512)]:
    base.resize((size, size), Image.Resampling.LANCZOS).save(web/name, optimize=True)
android = ROOT / 'app/android/app/src/main/res'
for density, size in [('mdpi', 48), ('hdpi', 72), ('xhdpi', 96),
                      ('xxhdpi', 144), ('xxxhdpi', 192)]:
    base.resize((size, size), Image.Resampling.LANCZOS).save(
        android / f'mipmap-{density}/ic_launcher.png', optimize=True)
ios = ROOT / 'app/ios/Runner/Assets.xcassets/AppIcon.appiconset'
for path in ios.glob('Icon-App-*.png'):
    match = re.search(r'-(\d+(?:\.\d+)?)x\1@(\d+)x\.png$', path.name)
    if match:
        size = round(float(match.group(1))*int(match.group(2)))
        base.resize((size, size), Image.Resampling.LANCZOS).save(path, optimize=True)
print('Generated logo and web, Android, iOS icons')
