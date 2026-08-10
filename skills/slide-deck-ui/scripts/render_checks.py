#!/usr/bin/env python3
"""PDFのページ数を表示し、指定ページを検証用PNGとして書き出します。

コンテナ内での実行を想定します（pypdfium2とpillowが必要）。
usage: render_checks.py deck.pdf outdir [page ...]
ページ指定を省略した場合は先頭・中間・末尾の3ページを書き出します。
"""
import sys

import pypdfium2 as pdfium


def main():
    pdf_path, outdir, *pages = sys.argv[1:]
    pdf = pdfium.PdfDocument(pdf_path)
    total = len(pdf)
    print("pages:", total)
    idxs = sorted({int(p) - 1 for p in pages}) if pages else [0, total // 2, total - 1]
    for i in idxs:
        if not 0 <= i < total:
            print(f"skip out-of-range page {i + 1}")
            continue
        out = f"{outdir}/check-{i + 1:02d}.png"
        pdf[i].render(scale=0.8).to_pil().save(out)
        print("wrote", out)


if __name__ == "__main__":
    main()
