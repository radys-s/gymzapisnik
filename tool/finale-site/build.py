"""Zkopíruje stránky z docs/design do public/ a přepíše odkazy na artefakty na relativní."""
import io
import pathlib

ROOT = pathlib.Path(__file__).resolve().parents[2]
OUT = pathlib.Path(__file__).resolve().parent / 'public'
FINALE = 'https://claude.ai/code/artifact/8b5559c5-c88d-424d-9f8e-b5b305effb40'
KONCEPTY = 'https://claude.ai/code/artifact/507b7536-4470-4ca8-88ba-debc3dacd292'

OUT.mkdir(exist_ok=True)
for src, dst in [('finaliste.html', 'index.html'), ('life-dashboard-koncepty.html', 'koncepty.html')]:
    s = io.open(ROOT / 'docs' / 'design' / src, encoding='utf-8').read()
    s = s.replace(FINALE + '"', '/"').replace(KONCEPTY + '"', '/koncepty.html"')
    s = s.replace(' target="_blank" rel="noopener"', '')
    io.open(OUT / dst, 'w', encoding='utf-8', newline='\n').write(s)
    print(dst, len(s))
