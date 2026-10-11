# -*- coding: utf-8 -*-
"""道历规则反推引擎：
1. 读入抓取的逐日事件（data/raw/months 解析产物 scraped_days.json）
2. 用 lunar_python 计算农历/干支/节气
3. 归纳规律：农历年节（M-D）、每月下降日（D）、暗戊表、八会干支锚、天赦、三会三元五腊、八节
4. 输出 analysis_report.md + rules_draft.json
"""
import json
import sys
import io
from collections import defaultdict
from pathlib import Path

from lunar_python import Solar

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8")
ROOT = Path(__file__).resolve().parent.parent
DAYS = json.loads((ROOT / "data" / "scraped_days.json").read_text(encoding="utf-8"))

GZ60 = [g + z for g in "甲乙丙丁戊己庚辛壬癸" for z in "子丑寅卯辰巳午未申酉戌亥"]
# 甲子起，交替推进
GAN = "甲乙丙丁戊己庚辛壬癸"
ZHI = "子丑寅卯辰巳午未申酉戌亥"
SEX60 = [GAN[i % 10] + ZHI[i % 12] for i in range(60)]


def cal(date_str: str) -> dict:
    y, m, d = map(int, date_str.split("-"))
    solar = Solar.fromYmd(y, m, d)
    lunar = solar.getLunar()
    return {
        "ly": lunar.getYear(), "lm": lunar.getMonth(), "ld": lunar.getDay(),
        "leap": lunar.getMonth() < 0,
        "yearGZ": lunar.getYearInGanZhi(), "monthGZ": lunar.getMonthInGanZhi(),
        "dayGZ": lunar.getDayInGanZhi(),
        "term": lunar.getJieQi() if lunar.getJieQi() else "",
        "lm_abs": abs(lunar.getMonth()),
    }


def norm(name: str) -> str:
    return name.strip().strip("、，。 ")


def main() -> None:
    # ---- 1. 合并去重 ----
    merged = {}
    conflicts = []
    for date, info in DAYS.items():
        if date in merged:
            old = set(merged[date]["events"])
            new = set(info["events"])
            if old != new:
                conflicts.append(date)
                merged[date]["events"] = sorted(old | new)
        else:
            merged[date] = {"events": list(info["events"])}
    print(f"days: {len(merged)}, dup-conflicts: {len(conflicts)}")

    # ---- 2. 附加历法信息 ----
    for date in merged:
        merged[date].update(cal(date))

    # ---- 3. 事件索引 ----
    ev_dates = defaultdict(list)  # name -> [date]
    for date, info in merged.items():
        for e in info["events"]:
            ev_dates[norm(e)].append(date)
    print(f"unique events: {len(ev_dates)}")

    # ---- 4. 规则归纳 ----
    monthly = defaultdict(lambda: defaultdict(int))   # name -> lunarD -> count
    annual = defaultdict(lambda: defaultdict(int))    # name -> (M,D) -> count
    monthly_years = defaultdict(lambda: defaultdict(set))
    annual_years = defaultdict(lambda: defaultdict(set))
    other = defaultdict(list)
    for name, dates in ev_dates.items():
        for dt in dates:
            i = merged[dt]
            if i["leap"]:
                continue
            monthly[name][i["ld"]] += 1
            monthly_years[name][i["ld"]].add(i["ly"])
            annual[name][(i["lm_abs"], i["ld"])] += 1
            annual_years[name][(i["lm_abs"], i["ld"])].add(i["ly"])
    rules_monthly = {}   # name -> D
    rules_annual = {}    # name -> (M, D)
    unmatched = []
    for name in ev_dates:
        if name in ("明戊日", "暗戊日", "天赦日"):
            continue
        best_m, best_c = None, 0
        for d, c in monthly[name].items():
            if c > best_c:
                best_m, best_c = d, c
        if best_m is not None and best_c >= 10 and len(monthly[name]) <= 4:
            rules_monthly[name] = {"day": best_m, "hits": best_c,
                                   "total": len(ev_dates[name])}
            continue
        best_a, best_c = None, 0
        for k, c in annual[name].items():
            if c > best_c:
                best_a, best_c = k, c
        if best_a is not None and len(annual_years[name].get(best_a, set())) >= 3:
            rules_annual[name] = {"month": best_a[0], "day": best_a[1], "hits": best_c,
                                  "total": len(ev_dates[name])}
            continue
        unmatched.append(name)
    print(f"monthly rules: {len(rules_monthly)}, annual rules: {len(rules_annual)}, unmatched: {len(unmatched)}")

    # ---- 5. 戊日/天赦/八会/三会三元五腊 ----
    ming, an, she, hui, misc_tags = [], [], [], defaultdict(list), defaultdict(list)
    for dt, i in merged.items():
        for e in i["events"]:
            e = norm(e)
            if e == "明戊日":
                ming.append((dt, i["dayGZ"]))
            elif e == "暗戊日":
                an.append((dt, i["lm_abs"], i["ld"], i["ly"], i["dayGZ"]))
            elif e == "天赦日":
                she.append((dt, i["dayGZ"]))
            elif e.endswith("会") and e not in ("社会",):
                hui[e].append((dt, i["dayGZ"]))
            elif e in ("三会日", "三元日", "五腊日", "八节日", "八会日"):
                misc_tags[e].append((dt, i["lm_abs"], i["ld"]))
    an_table = defaultdict(set)
    an_by_month_branch = defaultdict(lambda: defaultdict(int))
    an_gz_set = set()
    for dt, lm, ld, ly, gz in an:
        an_table[lm].add(ld)
        an_by_month_branch[lm][gz[1]] += 1
        an_gz_set.add(gz)
    print("\n== 暗戊日 ==")
    print("  total:", len(an), " distinct ganzhi:", len(an_gz_set))
    for lm in sorted(an_by_month_branch):
        branches = an_by_month_branch[lm]
        mode = max(branches.items(), key=lambda kv: kv[1])
        print(f"  month {lm:2d}: mode={mode[0]} ({mode[1]}/{sum(branches.values())})  days={sorted(an_table[lm])}")
    print("  ganzhi set:", sorted(an_gz_set))
    print("  明戊 stems:", {g for _, g in ming} and {g[0] for _, g in ming},
          " count:", len(ming))
    print("  天赦:", she[:8])
    print("  八会:", {k: sorted({g for _, g in v}) for k, v in sorted(hui.items())})
    print("  misc:", {k: sorted({(m, d) for _, m, d in v}) for k, v in misc_tags.items()})

    # ---- 6. 保存 ----
    report = {
        "monthly": {k: v for k, v in sorted(rules_monthly.items())},
        "annual": {k: v for k, v in sorted(rules_annual.items())},
        "unmatched": sorted(unmatched),
        "anwu": {str(k): sorted(v) for k, v in sorted(an_table.items())},
        "hui": {k: sorted({g for _, g in v}) for k, v in sorted(hui.items())},
        "tianshe": she,
        "misc_tags": {k: sorted([list(x) for x in {tuple(p) for p in [(m, d) for _, m, d in v]}])
                      for k, v in misc_tags.items()},
    }
    (ROOT / "data" / "analysis_report.json").write_text(
        json.dumps(report, ensure_ascii=False, indent=1), encoding="utf-8")
    print("\n== monthly rules ==")
    for k, v in sorted(rules_monthly.items()):
        print(f"  每月初{v['day']:>2}  {k}  ({v['hits']}/{v['total']})")
    print("== unmatched ==")
    for k in sorted(unmatched):
        dates = sorted(ev_dates[k])[:6]
        print(f"  {k}  {dates}")
    (ROOT / "data" / "merged_days.json").write_text(
        json.dumps(merged, ensure_ascii=False, indent=0), encoding="utf-8")
    print("\nsaved: analysis_report.json / merged_days.json")


if __name__ == "__main__":
    main()
