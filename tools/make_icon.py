# -*- coding: utf-8 -*-
"""生成道历 App 图标：宣纸底圆角、朱砂印章「道」字，输出到 android 各 mipmap。"""
from PIL import Image, ImageDraw, ImageFont
from pathlib import Path

APP = Path(__file__).resolve().parent.parent / "app"
S = 1024

img = Image.new("RGB", (S, S), (147, 72, 62))  # 朱砂
d = ImageDraw.Draw(img)

# 内框（仿印章边线）
m = 64
d.rounded_rectangle([m, m, S - m, S - m], radius=80, outline=(247, 244, 236), width=18)

# 「道」字
font = ImageFont.truetype("C:/Windows/Fonts/simhei.ttf", 620)
bbox = d.textbbox((0, 0), "道", font=font)
w, h = bbox[2] - bbox[0], bbox[3] - bbox[1]
d.text(((S - w) / 2 - bbox[0], (S - h) / 2 - bbox[1] - 10), "道",
       font=font, fill=(247, 244, 236))

# 圆角遮罩
mask = Image.new("L", (S, S), 0)
ImageDraw.Draw(mask).rounded_rectangle([0, 0, S, S], radius=180, fill=255)
out = Image.new("RGBA", (S, S), (0, 0, 0, 0))
out.paste(img, (0, 0), mask)

sizes = {"mdpi": 48, "hdpi": 72, "xhdpi": 96, "xxhdpi": 144, "xxxhdpi": 192}
base = APP / "android" / "app" / "src" / "main" / "res"
for dpi, size in sizes.items():
    out.resize((size, size), Image.LANCZOS).save(base / f"mipmap-{dpi}" / "ic_launcher.png")
    out.resize((size, size), Image.LANCZOS).save(base / f"mipmap-{dpi}" / "ic_launcher_foreground.png")

# 圆形自适应图标底色
bg = Image.new("RGB", (S, S), (147, 72, 62))
bg.save(base / "mipmap-xxxhdpi" / "ic_launcher_background.png")
print("icons written")
