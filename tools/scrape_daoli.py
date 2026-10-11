# -*- coding: utf-8 -*-
"""抓取 daoli.zzhuangli.com 全年道历月页，解析 data-detail 事件，输出结构化 JSON。"""
import json
import re
import subprocess
import sys
import time
from pathlib import Path

sys.stdout = __import__("io").TextIOWrapper(sys.stdout.buffer, encoding="utf-8")

BASE = "https://daoli.zzhuangli.com"
OUT_DIR = Path(__file__).resolve().parent.parent / "data" / "raw" / "months"
OUT_JSON = Path(__file__).resolve().parent.parent / "data" / "scraped_days.json"
YEARS = [2024, 2025, 2026, 2027, 2028]

DAY_LI = re.compile(r'<li class="daoli-day[^"]*"[^>]*data-detail="([^"]+)"', re.S)
TERM = re.compile(r'data-detail="([^"]+)"[^>]*>.*?daoli-calendar-note">([^<]+)</small>', re.S)


def fetch(url: str) -> str | None:
    r = subprocess.run(
        ["curl", "-sL", "--max-time", "40", url],
        capture_output=True, text=True, encoding="utf-8",
    )
    return r.stdout if r.returncode == 0 and r.stdout else None


def main() -> None:
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    days = {}
    missing = []
    for y in YEARS:
        for m in range(1, 13):
            name = f"{y}-{m:02d}.html"
            path = OUT_DIR / name
            if path.exists() and path.stat().st_size > 5000:
                html = path.read_text(encoding="utf-8")
            else:
                html = fetch(f"{BASE}/index/{y}?m={m}")
                if not html or "404" in (html or "")[:400]:
                    missing.append((y, m))
                    time.sleep(0.8)
                    continue
                path.write_text(html, encoding="utf-8")
                time.sleep(0.8)
            count = 0
            for mday in DAY_LI.finditer(html):
                detail = mday.group(1)
                parts = [p.strip() for p in detail.split("/")]
                # 格式: N日(首日或为 YYYY年M月N日) / 农历日 / 事件...
                if not parts or not parts[0].endswith("日"):
                    continue
                dm = re.search(r"(\d+)日$", parts[0])
                if not dm:
                    continue
                solar_day = int(dm.group(1))
                lunar = parts[1] if len(parts) > 1 else ""
                events = [p for p in parts[2:] if p]
                days[f"{y:04d}-{m:02d}-{solar_day:02d}"] = {
                    "lunar_text": lunar,
                    "events": events,
                }
                count += 1
            print(f"{y}-{m:02d}: {count} days")

    # 节气标注（calendar-note 紧跟当日 li 之后）
    for term_m in TERM.finditer(open(OUT_DIR / "2026-09.html", encoding="utf-8").read()):
        pass  # 节气在其他流程用历法库计算，这里不依赖

    OUT_JSON.write_text(
        json.dumps(days, ensure_ascii=False, indent=1), encoding="utf-8"
    )
    print(f"total days: {len(days)}  missing pages: {missing}")


if __name__ == "__main__":
    main()
