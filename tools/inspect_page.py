import re, sys, io
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')
html = open('data/raw/2026-09.html', encoding='utf-8').read()

rows = re.findall(r'<tr[^>]*>(.*?)</tr>', html, re.S)
print('total <tr> rows:', len(rows))
seen = set()
for r in rows:
    cells = re.findall(r'<t[dh][^>]*>(.*?)</t[dh]>', r, re.S)
    cells = [re.sub(r'<[^>]+>', ' ', c).strip() for c in cells]
    line = ' | '.join(cells)
    if line not in seen:
        seen.add(line)
        print(line[:180])
