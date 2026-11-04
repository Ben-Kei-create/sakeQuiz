#!/usr/bin/env python3
"""lessons_part*.py と問題から、lessons.json と seals.json を生成・検証する。"""
import json, os, sys
here = os.path.dirname(os.path.abspath(__file__)); sys.path.insert(0, here)
from lessons_part1 import L1
from lessons_part2 import L2
from lessons_part3 import L3
root = os.path.dirname(here)
questions = json.load(open(os.path.join(root, "NihonshuQuiz/Resources/nihonshu_quiz.json")))
sources = json.load(open(os.path.join(root, "Documentation/sources.json")))
CHECKED = "2026-11-04"

def qid(prefix):
    if len(prefix) == 4 and prefix[0] == "q" and prefix[1:].isdigit():
        assert any(q["id"] == prefix for q in questions), prefix
        return prefix
    hits = [q["id"] for q in questions if q["question"].startswith(prefix)]
    assert len(hits) == 1, (prefix, hits)
    return hits[0]

lessons, used = [], set()
for day, title, body, qs, src in L1 + L2 + L3:
    ids = [qid(p) for p in qs]
    assert not (set(ids) & used), f"問題の重複 {day}日目"
    used |= set(ids)
    s = sources[src]
    assert 1 <= len(ids) <= 6, day
    assert 60 <= len(body) <= 400, (day, len(body))
    lessons.append({"day": day, "title": title, "body": body, "questionIDs": ids,
                    "sourceTitle": s["title"], "sourceURL": s["url"], "checkedOn": CHECKED})
assert [l["day"] for l in lessons] == list(range(1, len(lessons) + 1))
json.dump(lessons, open(os.path.join(root, "NihonshuQuiz/Resources/lessons.json"), "w"), ensure_ascii=False, indent=2)

# 蔵印帳：地理的表示（GI）。指定の年月日は国税庁の一覧による。印は、対応する問題に正解すると押される。
seals = [
 {"id": "hakusan", "name": "白山", "place": "石川県白山市", "note": "清酒で最初のGI（2005年）", "questionPrefix": "清酒の地理的表示（GI）として、最初に指定された名称は？"},
 {"id": "nihonshu", "name": "日本酒", "place": "日本国", "note": "国産米を使い、国内で製造した清酒（2015年）", "questionPrefix": "地理的表示「日本酒」の産地は？"},
 {"id": "nada", "name": "灘五郷", "place": "兵庫県神戸市・芦屋市・西宮市", "note": "2018年指定", "questionPrefix": "灘五郷の位置として正しいのは？"},
 {"id": "harima", "name": "はりま", "place": "兵庫県播磨地域", "note": "兵庫県産山田錦で醸す", "questionPrefix": "GI「はりま」の清酒に使われる酒米は？"},
 {"id": "mie", "name": "三重", "place": "三重県", "note": "2020年指定", "questionPrefix": "国税庁の一覧で、令和2年に清酒として指定された地理的表示は？"},
 {"id": "niigata", "name": "新潟", "place": "新潟県", "note": "2022年指定", "questionPrefix": "国税庁の一覧で、清酒の地理的表示に含まれる都道府県名は？"},
 {"id": "iwate", "name": "岩手", "place": "岩手県", "note": "南部杜氏の技術", "questionPrefix": "GI「岩手」の紹介で、日本最大の杜氏集団として挙がるのは？"},
 {"id": "itami", "name": "伊丹", "place": "兵庫県伊丹市", "note": "2024年指定", "questionPrefix": "兵庫県伊丹市の地理的表示「伊丹」は、どの種類の酒？"},
]
for s in seals:
    s["questionID"] = qid(s.pop("questionPrefix"))
json.dump(seals, open(os.path.join(root, "NihonshuQuiz/Resources/seals.json"), "w"), ensure_ascii=False, indent=2)
print(len(lessons), "日分の読み物、", len(seals), "個の印")
