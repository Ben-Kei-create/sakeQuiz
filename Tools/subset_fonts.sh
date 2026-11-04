#!/usr/bin/env bash
# フォントを、アプリで使う文字だけに絞る。新しい漢字を読み物に足したら、再実行する。
# 使い方: Tools/subset_fonts.sh <元フォントのフォルダ> （Shippori Mincho の Regular/Bold を含む。入手先は Google Fonts のリポジトリ、OFL）
# 前提: python3 に fonttools（pip install fonttools brotli）
set -euo pipefail
SRC="${1:?元フォントのフォルダを指定}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT="$ROOT/NihonshuQuiz/Resources/Fonts"
TMP="$(mktemp -d)"
python3 -I - "$ROOT" "$TMP/chars.txt" <<'PY'
import sys, pathlib
root, out = pathlib.Path(sys.argv[1]), sys.argv[2]
chars = set(chr(c) for c in range(0x20, 0x7f)) | set("〜…・※→←↑↓●○◯□■▲△▽★☆")
for hi in range(0x21, 0x7f):
    for lo in range(0x21, 0x7f):
        try: chars.add(bytes([hi + 0x80, lo + 0x80]).decode("euc_jp"))
        except Exception: pass
for pattern in ("NihonshuQuiz/**/*.swift", "NihonshuQuiz/Resources/*.json", "NihonshuQuiz/Info.plist"):
    for f in root.glob(pattern): chars |= set(f.read_text(encoding="utf-8"))
open(out, "w", encoding="utf-8").write("".join(sorted(c for c in chars if c.strip())))
PY
for w in Regular Bold; do
  pyftsubset "$SRC/ShipporiMincho-$w.ttf" --text-file="$TMP/chars.txt" --layout-features='kern,palt,vert,vrt2' --output-file="$OUT/ShipporiMincho-$w.ttf"
done
ls -l "$OUT"
