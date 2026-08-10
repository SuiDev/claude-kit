#!/usr/bin/env python3
"""スライドHTMLをChromium印刷用に変換します。

Chromiumのprint-to-pdfはメディアクエリを実ページ幅より狭い幅で評価することが
あり、モバイル向けの非表示規則が発動して挿絵が消えます。また印刷経路では
インラインSVGが描画されないことがあります。このスクリプトは max-width /
max-height のメディアクエリ除去と、SVGのdata URI画像化で両方を回避します。
"""
import argparse
import base64
import pathlib
import re

PRINT_CSS = """
  @page { size: 1920px 1080px; margin: 0; }
  html, body { overflow: visible; }
  .deck { height: auto; overflow: visible; scroll-snap-type: none; }
  .slide { height: 1080px; page-break-after: always; break-inside: avoid; opacity: 1 !important; }
  .slide .reveal { opacity: 1 !important; transform: none !important; transition: none !important; }
  .deck-progress, .deck-dots, .deck-counter, .deck-hints { display: none !important; }
  .illus img, .illus-bare img { width: 100%; height: auto; }
  .illus-bare img { max-height: 74vh; }
  .illus img { max-height: 56vh; }
"""


def strip_max_media_blocks(html):
    out = []
    i = 0
    while True:
        m = re.search(r'@media[^{]*\(max-(?:width|height)[^{]*\{', html[i:])
        if not m:
            out.append(html[i:])
            break
        out.append(html[i:i + m.start()])
        j = i + m.end()
        depth = 1
        while j < len(html) and depth:
            if html[j] == '{':
                depth += 1
            elif html[j] == '}':
                depth -= 1
            j += 1
        i = j
    return ''.join(out)


def svg_to_img(m):
    svg = m.group(0)
    label = re.search(r'aria-label="([^"]*)"', svg)
    alt = label.group(1) if label else ""
    b64 = base64.b64encode(svg.encode("utf-8")).decode("ascii")
    return f'<img alt="{alt}" src="data:image/svg+xml;base64,{b64}">'


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("src")
    ap.add_argument("dst")
    args = ap.parse_args()

    html = pathlib.Path(args.src).read_text(encoding="utf-8")
    html = strip_max_media_blocks(html)
    html, n = re.subn(r'<svg[^>]*>.*?</svg>', svg_to_img, html, flags=re.DOTALL)
    html = html.replace("</style>", PRINT_CSS + "</style>", 1)
    pathlib.Path(args.dst).write_text(html, encoding="utf-8")
    print(f"print variant: {args.dst} (svg to img: {n})")


if __name__ == "__main__":
    main()
