"""Vyrobí ikony aplikace pro iOS, Android a web z jednoho SVG.

Použití: python scripts/make_icons.py design/ikona.svg

SVG má viewBox 0 0 1024 1024. Prvky pozadí mají id začínající `bg`
(černá plocha, mřížka); bez nich zbyde samotná značka pro adaptivní
ikonu Androidu a pro maskovatelné ikony webu. Vykresluje Chrome bez
okna, zmenšuje Pillow.
"""

import re
import subprocess
import sys
import tempfile
from pathlib import Path

from PIL import Image

CHROME = r"C:\Program Files\Google\Chrome\Application\chrome.exe"
ROOT = Path(__file__).resolve().parent.parent
BG = (0, 0, 0)


def render(svg: str, size: int, transparent: bool) -> Image.Image:
    with tempfile.TemporaryDirectory() as tmp:
        src = Path(tmp) / "icon.html"
        out = Path(tmp) / "icon.png"
        src.write_text(
            "<!doctype html><style>html,body{margin:0;background:transparent}"
            f"svg{{display:block;width:{size}px;height:{size}px}}</style>{svg}",
            encoding="utf8",
        )
        args = [
                CHROME,
                "--headless",
                f"--user-data-dir={tmp}",
                "--disable-gpu",
                "--hide-scrollbars",
                f"--window-size={size},{size}",
                f"--screenshot={out}",
                "--default-background-color=00000000" if transparent else "",
                src.as_uri(),
        ]
        subprocess.run([a for a in args if a], check=True, capture_output=True)
        return Image.open(out).convert("RGBA").copy()


def mark_only(svg: str) -> str:
    """SVG bez prvků pozadí (id="bg…")."""
    return re.sub(r'<(rect|path)[^>]*\bid="bg[^"]*"[^>]*/>', "", svg)


def flat(img: Image.Image) -> Image.Image:
    """iOS nesmí mít alfa kanál: podklad černý."""
    out = Image.new("RGB", img.size, BG)
    out.paste(img, mask=img.split()[3])
    return out


def padded(mark: Image.Image, size: int, scale: float, bg) -> Image.Image:
    """Značka zmenšená na [scale] plochy, uprostřed (bezpečná zóna)."""
    inner = round(size * scale)
    canvas = Image.new("RGBA", (size, size), bg)
    m = mark.resize((inner, inner), Image.LANCZOS)
    canvas.alpha_composite(m, ((size - inner) // 2, (size - inner) // 2))
    return canvas


def main(path: str) -> None:
    svg = Path(path).read_text(encoding="utf8")
    full = render(svg, 1024, transparent=False)
    mark = render(mark_only(svg), 1024, transparent=True)

    ios = ROOT / "ios/Runner/Assets.xcassets/AppIcon.appiconset"
    for f in ios.glob("Icon-App-*.png"):
        m = re.match(r"Icon-App-([\d.]+)x[\d.]+@(\d)x\.png", f.name)
        px = round(float(m.group(1)) * int(m.group(2)))
        flat(full.resize((px, px), Image.LANCZOS)).save(f)

    res = ROOT / "android/app/src/main/res"
    for dpi, k in {"mdpi": 1, "hdpi": 1.5, "xhdpi": 2, "xxhdpi": 3, "xxxhdpi": 4}.items():
        d = res / f"mipmap-{dpi}"
        if not d.exists():
            continue
        flat(full.resize((round(48 * k),) * 2, Image.LANCZOS)).save(d / "ic_launcher.png")
        # Adaptivní popředí 108 dp, viditelný kruh ~66 dp: značka na 62 %.
        padded(mark, round(108 * k), 0.62, (0, 0, 0, 0)).save(
            d / "ic_launcher_foreground.png"
        )

    web = ROOT / "web"
    for name, px in {"Icon-192.png": 192, "Icon-512.png": 512}.items():
        flat(full.resize((px, px), Image.LANCZOS)).save(web / "icons" / name)
    for name, px in {"Icon-maskable-192.png": 192, "Icon-maskable-512.png": 512}.items():
        # Maskovatelná: bezpečný kruh 80 %, značka na 70 %.
        flat(padded(mark, px, 0.70, BG + (255,))).save(web / "icons" / name)
    flat(full.resize((180, 180), Image.LANCZOS)).save(web / "icons/apple-touch-icon.png")
    flat(full.resize((64, 64), Image.LANCZOS)).save(web / "favicon.png")
    print("ikony hotové")


if __name__ == "__main__":
    main(sys.argv[1])
