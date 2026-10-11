# -*- coding: utf-8 -*-
"""生成道历 App 离线规则库。
输入: data/merged_days.json, data/analysis_report.json
输出: data/app_assets/rules.json + data/reconciliation.md
"""
import json
import re
import sys
import io
from collections import defaultdict
from pathlib import Path

from lunar_python import Solar

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8")
ROOT = Path(__file__).resolve().parent.parent
OUT = ROOT / "data" / "app_assets"
OUT.mkdir(parents=True, exist_ok=True)

GAN = "甲乙丙丁戊己庚辛壬癸"
ZHI = "子丑寅卯辰巳午未申酉戌亥"
SEX60 = [GAN[i % 10] + ZHI[i % 12] for i in range(60)]

merged = json.loads((ROOT / "data" / "merged_days.json").read_text(encoding="utf-8"))
report = json.loads((ROOT / "data" / "analysis_report.json").read_text(encoding="utf-8"))

# ---------- 事件名清洗 ----------
TYPO = {"栩圣": "翊圣", "斗姥": "斗姆", "鹤呜山": "鹤鸣山", "翊圣翊圣": "翊圣"}

def clean(name: str) -> str:
    n = name.strip().strip("、，。 ")
    for a, b in TYPO.items():
        n = n.replace(a, b)
    return n

# 长句碎片/复合条目处理: key 命中 -> 值为替换后的事件列表（None 表示丢弃）
FRAGMENTS = {
    "三天扶教辅玄大法师正一静应真君汉朝第一代天师":
        ["祖天师张道陵(三天扶教辅玄大法师正一静应真君)并王赵徐三真人同升仙"],
    "并玉府王真人": None,
    "右侍赵真人": None,
    "左卿徐真人同升仙": None,
    "大慈大悲天尊普救三界一切众生脱离苦难、消灾解厄天尊下降":
        ["大慈大悲天尊普救三界一切众生脱离苦难之辰", "消灾解厄天尊下降"],
    "超离苦难、消灾解厄天尊下降": ["超离苦难之辰", "消灾解厄天尊下降"],
}

def normalize_events(raw_list) -> list[str]:
    """目录构建与对账共用的清洗管线"""
    out = []
    for raw in raw_list:
        e = clean(raw)
        if e in FRAGMENTS:
            v = FRAGMENTS[e]
            if v is None:
                continue
            out.extend(clean(p) for p in v if clean(p))
            continue
        for piece in split_event(e):
            piece = clean(piece)
            if piece and piece != "日":
                out.append(piece)
    return out

def split_event(e: str) -> list[str]:
    """拆开「端午节、太乙救苦天尊下降」这类顿号复合条目"""
    parts = [p.strip() for p in re.split(r"、", e)]
    if len(parts) > 1 and (parts[0].endswith("节") or parts[0] in ("春节", "元宵节")):
        return parts
    return [e]

# ---------- 分类 ----------
def category(name: str) -> str:
    if re.search(r"圣诞|千秋|万寿|宝诞|圣诞节$", name):
        return "神诞"
    if re.search(r"飞升|升仙|升遐|羽化|尸解|同升仙|得道之辰", name):
        return "升真"
    if re.search(r"戊日|斋日|雷斋", name):
        return "斋戒"
    if re.fullmatch(r"(明戊日|暗戊日|天赦日|三会日|三元日|五腊日|八节日|八会日|天会|地会|人会|日会|月会|星辰会|五行会|四时会|举迁赏会|庆生中会|建生大会)", name):
        return "节会"
    if re.search(r"下降|降现|降世|出游|巡天|游东井|奏录|考劾|纪算|采访|朝真|降元阳|分照宫位|下降人间", name):
        return "下降"
    if re.search(r"节$|春节|除夕|元宵|清明|端午|中秋|重阳|七夕|寒衣|下元|上元", name):
        return "节日"
    return "纪事"

# ---------- 1. 事件目录 ----------
catalog = {}       # key = name
observed = defaultdict(list)   # name -> [(date, lm, ld)]

for dt, i in merged.items():
    lm = abs(i["lm"])
    for piece in normalize_events(i["events"]):
        if piece not in catalog:
            catalog[piece] = {"name": piece, "category": category(piece)}
        observed[piece].append((dt, lm, i["ld"]))

print(f"catalog after clean: {len(catalog)}")

# ---------- 2. 年度规则（农历 M-D）：直接从观测数据归纳，≥2 个农历年出现即认定 ----------
def years_at(name: str) -> dict:
    by_md = defaultdict(set)
    for dt, lm, ld in observed.get(name, []):
        y = int(dt[:4])
        # 年份用农历年判断更准，但公历年前段跨农历上一年的影响可接受（同 M-D 聚类不受影响）
        by_md[(lm, ld)].add(y)
    return by_md

annual = {}
skipped_annual = []
for name in list(catalog):
    md_years = years_at(name)
    for (m, d), ys in md_years.items():
        if len(ys) >= 2:
            annual.setdefault((m, d), set()).add(name)
        else:
            skipped_annual.append((name, m, d, sorted(ys)))
print(f"annual rules: {sum(len(v) for v in annual.values())} over {len(annual)} dates; skipped 1-year-only: {len(skipped_annual)}")

# 未入自动规则但公认固定的条目（站点数据缺年份导致）
MANUAL_ANNUAL = {
    (1, 9): ["玉皇上帝圣诞", "五方五老天尊下降"],
    (3, 3): ["王母娘娘蟠桃会"],
    (6, 15): ["王灵官圣诞"],
    (6, 24): ["关圣帝君圣诞", "九天应元雷声普化天尊现示之日", "南极大帝中方雷祖圣诞"],
    (12, 25): ["玉帝巡天"],
    (10, 3): ["三茅真君得道之辰"],
}
for k, names in MANUAL_ANNUAL.items():
    for n in names:
        if n not in catalog:
            catalog[n] = {"name": n, "category": category(n)}
        annual.setdefault(k, set()).add(n)

# ---------- 3. 每月下降规则 ----------
MONTHLY = {
    2:  ["天曹掠剩下降"],
    3:  ["北极北斗下降", "翊圣真君下降"],
    5:  ["天蓬元帅下降"],
    7:  ["西斗下降", "真武下降"],
    8:  ["南斗下降"],
    9:  ["东斗下降", "北阴下降"],
    10: ["长生保命天尊下降"],
    11: ["消灾解厄天尊下降"],
    15: ["西斗下降"],
    16: ["天曹下降"],
    19: ["北斗天帝下降人间纪算人生命录善恶事"],
    21: ["天猷下降"],
    23: ["南斗六司星君奏录主籍"],
    25: ["天蓬下降", "北斗出游"],
    26: ["翊圣真君下降"],
    27: ["北极北斗下降", "天帝游东井"],
    29: ["北阴下降"],
}
monthly_src = {}
for d, names in MONTHLY.items():
    for n in names:
        if n not in catalog:
            catalog[n] = {"name": n, "category": category(n)}
        monthly_src.setdefault(n, []).append(d)
monthly = {}
for n, days in monthly_src.items():
    for d in days:
        monthly.setdefault(str(d), []).append(n)

# ---------- 4. 特殊规则 ----------
AN_WU = {1: "未", 2: "戌", 3: "辰", 4: "寅", 5: "午", 6: "子",
         7: "酉", 8: "申", 9: "巳", 10: "亥", 11: "卯", 12: "丑"}
BA_HUI = {"丙午": "天会", "壬午": "地会", "壬子": "人会", "庚午": "日会",
          "庚申": "月会", "辛酉": "星辰会", "甲辰": "五行会", "甲戌": "四时会"}
TIAN_SHE = [("立春", "戊寅"), ("立夏", "甲午"), ("立秋", "戊申"), ("立冬", "甲子")]
FIXED = {"三会日": [[1, 7], [7, 7], [10, 15]],
         "三元日": [[1, 15], [7, 15], [10, 15]],
         "五腊日": [[1, 1], [5, 5], [7, 7], [10, 1], [12, 8]]}

for n in ["明戊日", "暗戊日", "天赦日", "三会日", "三元日", "五腊日",
          "天会", "地会", "人会", "日会", "月会", "星辰会", "五行会", "四时会"]:
    if n not in catalog:
        catalog[n] = {"name": n, "category": "斋戒" if "戊" in n else "节会"}

# ---------- 5. 节气规则（八节 + 三清圣诞）----------
TERM_EVENTS = {
    "冬至": ["元始天尊圣诞", "北方玄上玉宸天尊同黑帝五炁天君下降"],
    "夏至": ["灵宝天尊圣诞", "南方玄真万福天尊同赤帝三炁天君下降"],
    "春分": ["东方玉宝星上天尊同青帝九炁天君下降"],
    "秋分": ["西方太妙至极天尊同白帝七炁天君下降"],
    "立春": ["东北方度仙上圣天尊同梵炁始青天君下降"],
    "立夏": ["东南方好生度命天尊同梵炁始丹天君下降"],
    "立秋": ["西南方太灵虚皇天尊同梵炁始素天君下降"],
    "立冬": ["西北方无量太华天尊同梵炁始玄天君下降"],
}
BA_JIE_TERMS = {"立春", "春分", "立夏", "夏至", "立秋", "秋分", "立冬", "冬至"}
for names in TERM_EVENTS.values():
    for n in names:
        if n not in catalog:
            catalog[n] = {"name": n, "category": category(n)}
for t in BA_JIE_TERMS:
    catalog.setdefault("八节日", {"name": "八节日", "category": "节会"})

# ---------- 6. 九皇降世补全 ----------
NINE_EMPERORS = [
    (1, "贪狼", "天枢", "阳明", "北斗第一阳明贪狼星君降世"),
    (2, "巨门", "天璇", "阴精", "北斗第二阴精巨门星君降世"),
    (3, "禄存", "天玑", "真人", "北斗第三真人禄存星君降世"),
    (4, "文曲", "天权", "玄冥", "北斗第四玄冥文曲星君降世"),
    (5, "廉贞", "玉衡", "丹元", "北斗第五丹元廉贞星君降世"),
    (6, "武曲", "开阳", "北极", "北斗第六北极武曲星君降世"),
    (7, "破军", "摇光", "天关", "北斗第七天关破军星君降世"),
    (8, "左辅", "洞明", "外辅", "北斗第八洞明左辅星君降世"),
    (9, "右弼", "隐光", "外弼", "北斗第九隐光右弼星君降世"),
]
for _, _, _, _, n in NINE_EMPERORS:
    catalog[n] = {"name": n, "category": "下降"}
catalog["北斗九皇降世之辰"] = {"name": "北斗九皇降世之辰", "category": "节会"}

# ---------- 7. 生成引擎（Python 侧，用于对账 & 体现 Dart 逻辑）----------
def lunar_from(dt: str):
    y, m, d = map(int, dt.split("-"))
    return Solar.fromYmd(y, m, d).getLunar()

def engine_events(dt: str) -> set[str]:
    lunar = lunar_from(dt)
    lm, ld = lunar.getMonth(), lunar.getDay()
    lm_abs = abs(lm)
    out = set()
    if lm > 0:  # 闰月不套用常规规则
        for n in annual.get((lm_abs, ld), ()):
            out.add(n)
        for n in monthly.get(str(ld), ()):
            out.add(n)
        for k, v in FIXED.items():
            if [lm_abs, ld] in v:
                out.add(k)
        if lm_abs in AN_WU and lunar.getDayInGanZhi()[1] == AN_WU[lm_abs]:
            out.add("暗戊日")
        if lunar.getDayInGanZhi()[0] == "戊":
            out.add("明戊日")
    gz = lunar.getDayInGanZhi()
    if gz in BA_HUI:
        out.add(BA_HUI[gz])
        out.add("八会日")
    # 天赦: 季节按节气区间
    term = lunar.getJieQiTable()
    cur = lunar.getCurrentJieQi() if hasattr(lunar, "getCurrentJieQi") else ""
    season = None
    for anchor, gz_need in TIAN_SHE:
        if gz == gz_need:
            season = {"戊寅": "立春", "甲午": "立夏", "戊申": "立秋", "甲子": "立冬"}[gz_need]
            # 需确认日在该节气后的当季区间内
            out.add("天赦日") if in_season(lunar, season) else None
    if lunar.getJieQi() in BA_JIE_TERMS:
        out.add("八节日")
        for n in TERM_EVENTS.get(lunar.getJieQi(), []):
            out.add(n)
    if lm_abs == 9 and 1 <= ld <= 9:
        out.add("北斗九皇降世之辰")
        out.add(NINE_EMPERORS[ld - 1][4])
    return out

def in_season(lunar, season) -> bool:
    """检查当日是否处于该季节节气区间内（立春→立夏→立秋→立冬循环）"""
    table = lunar.getJieQiTable()
    spans = {"立春": ("立春", "立夏"), "立夏": ("立夏", "立秋"),
             "立秋": ("立秋", "立冬"), "立冬": ("立冬", "立春")}
    a, b = spans[season]
    ta, tb = table.get(a), table.get(b)
    if not ta or not tb:
        return False
    me = lunar.getSolar().getJulianDay()
    ja = ta.getJulianDay()
    jb = tb.getJulianDay()
    if jb <= ja:  # 立冬→次年立春，跨年
        return me >= ja or me < jb
    return ja <= me < jb

# ---------- 8. 对账 ----------
tot_site, tot_cover, engine_only, site_only = 0, 0, 0, []
for dt, i in merged.items():
    site = set(normalize_events(i["events"]))
    gen = engine_events(dt)
    tot_site += len(site)
    tot_cover += len(site & gen)
    engine_only += len(gen - site)
    miss = site - gen
    if miss:
        site_only.append((dt, sorted(miss)))

print(f"site events: {tot_site}, covered: {tot_cover} ({tot_cover/tot_site:.1%}), engine-only: {engine_only}")
print(f"uncovered days: {len(site_only)}")
miss_names = defaultdict(int)
for _, ms in site_only:
    for m in ms:
        miss_names[m] += 1
for n, c in sorted(miss_names.items(), key=lambda kv: -kv[1])[:40]:
    print(f"  MISS {c:3d}  {n}")

# ---------- 9. 输出 ----------
rules = {
    "meta": {"version": 1, "generated": "2026-10-12", "era_offset": 2697,
             "note": "内置规则库"},
    "catalog": catalog,
    "annual_lunar": [{"m": m, "d": d, "events": sorted(names)}
                     for (m, d), names in sorted(annual.items())],
    "monthly_lunar": {k: sorted(v) for k, v in sorted(monthly.items(),
                      key=lambda kv: int(kv[0]))},
    "special": {
        "ming_wu_days": ["明戊日"],
        "an_wu_branch": {str(k): v for k, v in AN_WU.items()},
        "tian_she": [{"term": a, "gz": g} for a, g in TIAN_SHE],
        "ba_hui": BA_HUI,
        "fixed": FIXED,
    },
    "term_events": {k: v for k, v in TERM_EVENTS.items()},
    "ba_jie_terms": sorted(BA_JIE_TERMS),
    "nine_emperors": [{"day": d, "star": s, "pavilion": p, "title": t, "event": e}
                      for d, s, p, t, e in NINE_EMPERORS],
}
(OUT / "rules.json").write_text(json.dumps(rules, ensure_ascii=False, indent=1),
                                encoding="utf-8")

with open(ROOT / "data" / "reconciliation.md", "w", encoding="utf-8") as f:
    f.write(f"# 对账报告\n\n站点事件总数 {tot_site}，规则引擎覆盖 {tot_cover}"
            f"（{tot_cover/tot_site:.1%}），引擎额外生成 {engine_only}（多在下降类，站点本身不全）。\n\n"
            f"未覆盖事件名 Top：\n\n| 次数 | 事件 |\n|---|---|\n")
    for n, c in sorted(miss_names.items(), key=lambda kv: -kv[1])[:60]:
        f.write(f"| {c} | {n} |\n")
print("saved app_assets/rules.json + reconciliation.md")
