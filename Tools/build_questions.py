#!/usr/bin/env python3
"""questions_part*.py から、アプリ用JSON・出典一覧・確認記録を生成する。"""
import json, os, sys
here = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, here)
from questions_part1 import Q1
from questions_part2 import Q2
from questions_part3 import Q3
from questions_part4 import Q4
from questions_part5 import Q5

CHECKED = "2026-11-03"
SOURCES = {
    "hyoji": ("国税庁 — 「清酒の製法品質表示基準」の概要", "https://www.nta.go.jp/taxes/sake/hyoji/seishu/gaiyo/02.htm"),
    "kokuji": ("国税庁 — 清酒の製法品質表示基準を定める件（国税庁告示第8号）", "https://www.nta.go.jp/law/kokuji/891122/02.htm"),
    "history": ("国税庁 — 日本酒の歴史（造り・こうじ・酵母・酒米・酒造用水）", "https://www.nta.go.jp/taxes/sake/koujikin/pdf/0021012-102_03.pdf"),
    "gi": ("国税庁 — 酒類の地理的表示（GI）一覧", "https://www.nta.go.jp/taxes/sake/hyoji/chiri/ichiran.htm"),
    "jss_drink": ("日本酒造組合中央会 — 日本酒のおいしい飲み方", "https://japansake.or.jp/sake/enjoy-sake/how-to-drink-sake/"),
    "jss_flavor": ("日本酒造組合中央会 — 日本酒の味と香り", "https://japansake.or.jp/sake/enjoy-sake/flavor-and-aroma-of-sake/"),
    "jss_cups": ("日本酒造組合中央会 — 酒器で楽しむ日本酒", "https://japansake.or.jp/sake/enjoy-sake/sake-cups/"),
    "jss_season": ("日本酒造組合中央会 — 四季折々の楽しみ方", "https://japansake.or.jp/sake/enjoy-sake/season-to-sake/"),
    "jss_char": ("日本酒造組合中央会 — 日本酒の特徴", "https://japansake.or.jp/sake/about-sake/characteristics-of-sake/"),
    "jss_yawaragi": ("日本酒造組合中央会 — 和らぎ水のすすめ", "https://japansake.or.jp/sake/about-sake/yawaragi-mizu/"),
    "jss_class": ("日本酒造組合中央会 — 日本酒の分類", "https://japansake.or.jp/sake/about-sake/classification-of-sake/"),
    "jss_culture": ("日本酒造組合中央会 — 日本酒と文化", "https://japansake.or.jp/sake/about-sake/sake-culture/"),
    "jss_brew": ("日本酒造組合中央会 — 日本酒の製造工程", "https://japansake.or.jp/sake/about-sake/sake-brewing-processes/"),
    "jss_gi": ("日本酒造組合中央会 — 日本酒の地理的表示（GI）", "https://japansake.or.jp/sake/about-sake/gi/"),
    "jss_history": ("日本酒造組合中央会 — 日本酒の歴史", "https://japansake.or.jp/sake/about-sake/history-of-sake/"),
}
DIFF = {"E": ("Easy", "初級"), "M": ("Medium", "中級"), "H": ("Hard", "上級")}
CATNAME = {"rice": "米と酒米", "grade": "精米歩合と特定名称", "brewing": "醸造工程", "yeastWater": "酵母と水",
           "region": "産地と酒蔵の文化", "taste": "味わい・温度・酒器", "pairing": "ペアリング", "historyLabel": "歴史・表示・保存"}

rows = Q1 + Q2 + Q3 + Q4 + Q5
out, seen = [], set()
for i, (q, ans, wrong, trivia, d, cat, src) in enumerate(rows):
    q = q.replace("江戸時代の大坂（当時の記録）で、", "江戸前期の鴻池の酒造りを記した資料で、")
    assert q not in seen, q
    seen.add(q)
    assert len(wrong) == 3 and ans not in wrong, q
    pos = i % 4
    choices = wrong[:pos] + [ans] + wrong[pos:]
    title, url = SOURCES[src]
    out.append({"question": q, "choices": choices, "correctAnswerIndex": pos, "trivia": trivia,
                "difficulty": DIFF[d][0], "category": cat, "sourceTitle": title, "sourceURL": url, "checkedOn": CHECKED})

root = os.path.dirname(here)
json.dump(out, open(os.path.join(root, "NihonshuQuiz/Resources/nihonshu_quiz.json"), "w"), ensure_ascii=False, indent=2)
os.makedirs(os.path.join(root, "Documentation"), exist_ok=True)
json.dump({k: {"title": t, "url": u, "checkedOn": CHECKED} for k, (t, u) in SOURCES.items()},
          open(os.path.join(root, "Documentation/sources.json"), "w"), ensure_ascii=False, indent=2)

cnt = lambda f: sum(1 for o in out if f(o))
lines = ["# 問題の確認記録", "",
         f"確認日：2026年11月3日。全{len(out)}問（初級{cnt(lambda o:o['difficulty']=='Easy')}・中級{cnt(lambda o:o['difficulty']=='Medium')}・上級{cnt(lambda o:o['difficulty']=='Hard')}）。",
         "正解と解説を、国税庁と日本酒造組合中央会の公開資料の本文と照合。文章と選択肢は本アプリ用に作成し、原文の転載は行っていません。",
         "一般的な傾向は「一般に」などの表現を使い、規則で決まる事項は国税庁の基準を優先しています。",
         "特定名称の要件は、令和4年改正を反映した「清酒の製法品質表示基準」の概要（現行）を優先し、告示の原文（平成元年）は条文の定義の確認に使いました。", "",
         "分野別の問数：" + "、".join(f"{CATNAME[c]} {cnt(lambda o,c=c:o['category']==c)}" for c in CATNAME if cnt(lambda o,c=c:o['category']==c)), "",
         "|番号|難易度|分野|問題|正解|確認資料|", "|---|---|---|---|---|---|"]
for n, o in enumerate(out, 1):
    dj = [v[1] for v in DIFF.values() if v[0] == o["difficulty"]][0]
    lines.append(f"|{n:03d}|{dj}|{CATNAME[o['category']]}|{o['question']}|{o['choices'][o['correctAnswerIndex']]}|[{o['sourceTitle']}]({o['sourceURL']})|")
open(os.path.join(root, "Documentation/QUESTION_VERIFICATION.md"), "w").write("\n".join(lines) + "\n")
print(len(out), {c: cnt(lambda o, c=c: o["category"] == c) for c in CATNAME}, {k: cnt(lambda o, k=k: o["difficulty"] == k) for k in ("Easy", "Medium", "Hard")})
