#!/usr/bin/env python3
"""Per-episode wallpapers for SOUL ASCENSION, derived from the project's own key art (assets/echo_key_art.png, the Episode 1 wallpaper, unchanged).
Episode 2 (Lantern Quarter): warm lantern split-tone (wine shadows, ember-rose mids, amber lights). Episode 3 (The Relay Keeper): cold relay split-tone (deep teal shadows, cyan mids, pale signal lights).
Same composition, same hero, same style; only the colour grade changes (blended with the original so detail and gold trim survive). No new art, no external assets, no paid service.
Run: python3 tools/make_wallpapers.py"""
import numpy as np
from PIL import Image
SRC = 'assets/echo_key_art.png'
def toned(img, shadow, mid, light, mix):
    a = np.asarray(img.convert('RGB'), dtype=np.float32) / 255.0
    lum = (0.2126*a[..., 0] + 0.7152*a[..., 1] + 0.0722*a[..., 2])[..., None]
    lum = np.clip((lum - 0.02) / 0.78, 0, 1) ** 0.85
    s, m, l = (np.array(c, dtype=np.float32) / 255.0 for c in (shadow, mid, light))
    lo = s + (m - s) * np.clip(lum*2, 0, 1)
    hi = m + (l - m) * np.clip(lum*2 - 1, 0, 1)
    t = np.where(lum < 0.5, lo, hi)
    out = a*(1-mix) + t*mix*(0.55 + 0.9*lum)           # keep the original's contrast; the tone follows brightness
    return Image.fromarray((np.clip(out, 0, 1)*255).astype(np.uint8))
src = Image.open(SRC)
toned(src, (30, 8, 22), (178, 76, 56), (255, 208, 132), 0.78).save('assets/wallpapers/wallpaper_ep2.webp', quality=92, method=6)
toned(src, (4, 20, 32), (34, 136, 150), (196, 244, 238), 0.66).save('assets/wallpapers/wallpaper_ep3.webp', quality=92, method=6)
print('wrote assets/wallpapers/wallpaper_ep2.webp, wallpaper_ep3.webp')
