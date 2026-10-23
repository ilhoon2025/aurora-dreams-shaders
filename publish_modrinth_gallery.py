"""Upload assets/gallery/*.jpg to the Modrinth project gallery (token from env MODRINTH_TOKEN)."""
import json, os, pathlib, sys, urllib.parse, urllib.request
TOKEN = os.environ["MODRINTH_TOKEN"]; SLUG = "aurora-dreams"
UA = "ilhoon2025/aurora-dreams-publisher/1.3.2 (manager4ut@gmail.com)"
ROOT = pathlib.Path(__file__).parent
META = {  # file -> (title, description, featured)
 "01-ocean-sunset.jpg": ("Ocean at sunset", "Rippling water, sun glitter, SSR reflections and god rays.", True),
 "02-sunrise-godrays.jpg": ("Sunrise god rays", "Volumetric-style sky, bloom and warm light shafts over the forest.", False),
 "03-cave-glowing-ores.jpg": ("Glowing ores", "Ores glow in their own colour; soul lantern and redstone torch tint the light.", False),
 "04-aurora-night.jpg": ("Aurora night", "Procedural aurora borealis, stars and moody night clouds.", False),
 "05-forest-day.jpg": ("Forest hills", "Soft shadows, waving leaves and a bright cinematic daytime sky.", False),
}
for order, (name, (title, desc, feat)) in enumerate(META.items()):
    q = urllib.parse.urlencode({"ext": "jpg", "featured": str(feat).lower(), "title": title, "description": desc, "ordering": order})
    req = urllib.request.Request(f"https://api.modrinth.com/v2/project/{SLUG}/gallery?{q}", method="POST",
        data=(ROOT / "assets" / "gallery" / name).read_bytes(),
        headers={"Authorization": TOKEN, "User-Agent": UA, "Content-Type": "image/jpeg"})
    try:
        with urllib.request.urlopen(req) as r: print("ok", name, r.status)
    except urllib.error.HTTPError as e:
        sys.exit(f"{name} -> {e.code}: {e.read().decode()[:300]}")
