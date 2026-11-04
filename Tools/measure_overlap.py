#!/usr/bin/env python3
"""ワイン版（姉妹アプリ）とのSwiftコードの一致率を測る。Appleの質問7（コード共有）に答える根拠。
使い方: python3 Tools/measure_overlap.py <ワイン版のWineQuizフォルダ>
空行を除いた行の最長一致で比べる。import・括弧・SwiftUIの標準的な修飾子など、定型の行も一致に数える（実際より高めに出る）。"""
import difflib, glob, os, sys
wine_dir = sys.argv[1].rstrip("/") + "/"
norm = lambda t: [l.strip() for l in t.splitlines() if l.strip()]
wine = {f: norm(open(f).read()) for f in glob.glob(wine_dir + "**/*.swift", recursive=True)}
tot = same = 0
for f in sorted(glob.glob("NihonshuQuiz/**/*.swift", recursive=True)):
    y = norm(open(f).read())
    best = max(sum(t.size for t in difflib.SequenceMatcher(None, x, y, autojunk=False).get_matching_blocks()) for x in wine.values())
    tot += len(y); same += best
    print(f"{os.path.basename(f):28s} {len(y):4d}行  {best * 100 // max(1, len(y)):3d}%")
print(f"合計 {same}/{tot} 行 = {same * 100 // tot}%")
