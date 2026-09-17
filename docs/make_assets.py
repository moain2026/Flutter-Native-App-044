#!/usr/bin/env python3
"""
YECO - توليد أصول التطبيق (يُشغَّل مرة واحدة وقت التطوير، ليس جزءاً من التطبيق)

  1) تقسيم لوحات المنتجات (2x2) إلى 24 صورة منتج 512x512 (JPEG مضغوطة لحجم APK صغير)
  2) صورة مصغّرة لكل تصنيف (أول منتج في اللوحة)
  3) شعار العلامة (assets/brand/logo.png) من أيقونة التطبيق
  4) أيقونة إطلاق أندرويد متكيّفة (mipmap-anydpi-v26 + طبقتا خلفية/مقدمة) بلا مربعات سوداء

الاستخدام:
  python3 docs/make_assets.py <sheets_dir> <app_icon.png>
"""
import os
import sys

from PIL import Image, ImageDraw

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SHEETS = sys.argv[1] if len(sys.argv) > 1 else '/home/user/assets/sheets'
ICON = sys.argv[2] if len(sys.argv) > 2 else '/home/user/assets/icons/app_icon.png'

CATEGORIES = ['furniture', 'grocery', 'electronics', 'fashion', 'kitchen', 'sports']
PRODUCT_SIZE = 512
THUMB_SIZE = 256
BG = (245, 246, 248)


def split_sheets():
    out = os.path.join(ROOT, 'assets', 'products')
    cats = os.path.join(ROOT, 'assets', 'categories')
    os.makedirs(out, exist_ok=True)
    os.makedirs(cats, exist_ok=True)
    idx = 1
    for cat in CATEGORIES:
        sheet = Image.open(os.path.join(SHEETS, f'{cat}.png')).convert('RGB')
        w, h = sheet.size
        cw, ch = w // 2, h // 2
        cells = [(0, 0), (cw, 0), (0, ch), (cw, ch)]
        for i, (x, y) in enumerate(cells):
            # نقص 12px من كل حافة لإزالة الفواصل البيضاء بين الخلايا
            cell = sheet.crop((x + 12, y + 12, x + cw - 12, y + ch - 12))
            cell = cell.resize((PRODUCT_SIZE, PRODUCT_SIZE), Image.LANCZOS)
            cell.save(os.path.join(out, f'p{idx:02d}.jpg'), 'JPEG', quality=82, optimize=True)
            if i == 0:
                cell.resize((THUMB_SIZE, THUMB_SIZE), Image.LANCZOS).save(
                    os.path.join(cats, f'{cat}.jpg'), 'JPEG', quality=80, optimize=True)
            idx += 1
    print(f'✔ {idx - 1} product images + {len(CATEGORIES)} category thumbs')


def brand():
    out = os.path.join(ROOT, 'assets', 'brand')
    os.makedirs(out, exist_ok=True)
    icon = Image.open(ICON).convert('RGBA')
    # الأيقونة المولَّدة فيها هامش رمادي حول المربع؛ نقصّ إلى المربع الأخضر فقط
    bbox = _green_bbox(icon)
    sq = icon.crop(bbox)
    sq.resize((512, 512), Image.LANCZOS).save(os.path.join(out, 'logo.png'), optimize=True)
    # شعار بخلفية شفافة ومستديرة للاستخدام داخل التطبيق
    mask = Image.new('L', (512, 512), 0)
    ImageDraw.Draw(mask).rounded_rectangle((0, 0, 511, 511), radius=112, fill=255)
    rounded = sq.resize((512, 512), Image.LANCZOS)
    rounded.putalpha(mask)
    rounded.save(os.path.join(out, 'logo_rounded.png'), optimize=True)
    print('✔ brand logo')
    return sq


def _green_bbox(img):
    """يجد حدود المربع الملوّن (غير الرمادي) في الأيقونة المولَّدة"""
    px = img.convert('RGB')
    w, h = px.size
    data = px.load()
    xs, ys = [], []
    for y in range(0, h, 4):
        for x in range(0, w, 4):
            r, g, b = data[x, y]
            if g > r + 30 and g > b - 10:  # أخضر/تركوازي
                xs.append(x)
                ys.append(y)
    if not xs:
        return (0, 0, w, h)
    return (min(xs), min(ys), max(xs) + 4, max(ys) + 4)


def launcher_icons(square):
    """أيقونة متكيّفة: خلفية ملوّنة + مقدمة (الرمز الأبيض) + legacy"""
    res = os.path.join(ROOT, 'android', 'app', 'src', 'main', 'res')
    densities = {'mdpi': 48, 'hdpi': 72, 'xhdpi': 96, 'xxhdpi': 144, 'xxxhdpi': 192}
    src = square.convert('RGBA')
    for d, size in densities.items():
        folder = os.path.join(res, f'mipmap-{d}')
        os.makedirs(folder, exist_ok=True)
        # legacy: المربع كاملاً بزوايا مستديرة
        mask = Image.new('L', (size, size), 0)
        ImageDraw.Draw(mask).rounded_rectangle((0, 0, size - 1, size - 1), radius=size // 5, fill=255)
        legacy = src.resize((size, size), Image.LANCZOS)
        legacy.putalpha(mask)
        legacy.save(os.path.join(folder, 'ic_launcher.png'))
        # adaptive: 108dp بحيث تشغل الأيقونة الأصلية منطقة الأمان (72dp)
        full = int(size * 108 / 48)
        bg = Image.new('RGBA', (full, full), (16, 125, 96, 255))
        bg.save(os.path.join(folder, 'ic_launcher_background.png'))
        fg = Image.new('RGBA', (full, full), (0, 0, 0, 0))
        inner = int(full * 0.80)
        icon = src.resize((inner, inner), Image.LANCZOS)
        fg.paste(icon, ((full - inner) // 2, (full - inner) // 2), icon)
        fg.save(os.path.join(folder, 'ic_launcher_foreground.png'))
    any_dir = os.path.join(res, 'mipmap-anydpi-v26')
    os.makedirs(any_dir, exist_ok=True)
    xml = ('<?xml version="1.0" encoding="utf-8"?>\n'
           '<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">\n'
           '    <background android:drawable="@mipmap/ic_launcher_background"/>\n'
           '    <foreground android:drawable="@mipmap/ic_launcher_foreground"/>\n'
           '</adaptive-icon>\n')
    for name in ('ic_launcher.xml', 'ic_launcher_round.xml'):
        with open(os.path.join(any_dir, name), 'w', encoding='utf-8') as f:
            f.write(xml)
    print('✔ adaptive launcher icons')


if __name__ == '__main__':
    split_sheets()
    launcher_icons(brand())
