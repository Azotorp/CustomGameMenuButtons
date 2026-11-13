from pathlib import Path
from PIL import Image, ImageOps, ImageDraw
import hashlib, json

ROOT = Path(__file__).resolve().parents[1]
ASSETS = [
    ('CustomGameMenuButtons', 'Main — cyan'),
    ('CustomGameMenuButtons-ForeverAuras', 'ForeverAuras — green'),
    ('CustomGameMenuButtons-ReloadUI', 'Reload UI — red'),
]
def square(im, size):
    fitted = ImageOps.contain(im.convert('RGBA'), (size, size), Image.Resampling.LANCZOS)
    out = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    out.paste(fitted, ((size-fitted.width)//2, (size-fitted.height)//2))
    return out

preview = Image.new('RGB', (980, 450), '#171b22')
draw = ImageDraw.Draw(preview)
manifest = []
for index, (addon, label) in enumerate(ASSETS):
    source = ROOT / 'masters' / (addon + '.png')
    with Image.open(source) as im:
        dims = im.size
        texture = ROOT / 'AddOns' / addon / 'Media' / 'AddonIcon.tga'
        texture.parent.mkdir(parents=True, exist_ok=True)
        square(im, 64).save(texture)
        page = ROOT / 'exports' / (addon + '-512.png')
        page.parent.mkdir(exist_ok=True)
        square(im, 512).save(page)
        x = 20 + index * 325
        draw.text((x, 15), label, fill='white')
        preview.paste(square(im, 280), (x, 45), square(im, 280))
        for size, offset in [(64, 0), (24, 100), (16, 175)]:
            icon = square(im, size)
            preview.paste(icon, (x + offset, 350), icon)
            draw.text((x + offset, 422), str(size) + ' px', fill='white')
        manifest.append({'addon': addon, 'master_size': dims,
                         'master_sha256': hashlib.sha256(source.read_bytes()).hexdigest(),
                         'padding': 'Centered transparent square; no crop or stretch',
                         'toc_metadata': '## IconTexture: Interface\\AddOns\\' + addon + '\\Media\\AddonIcon.tga'})
    with Image.open(texture) as result:
        assert result.size == (64, 64) and result.mode == 'RGBA'
(ROOT / 'manifest.json').write_text(json.dumps(manifest, indent=2) + '\n')
preview.save(ROOT / 'Icon-Preview.png')
print('Validated 3 RGBA 64x64 TGA textures; generated 3 PNG exports and preview.')
