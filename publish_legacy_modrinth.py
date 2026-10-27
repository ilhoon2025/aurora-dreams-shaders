"""Create the Modrinth project 'aurora-dreams-legacy' (draft), upload icon, version and gallery.

  MODRINTH_TOKEN=<PAT> python publish_legacy_modrinth.py 1.0.0
"""
import json, os, pathlib, sys, urllib.parse, urllib.request, uuid
VERSION = sys.argv[1] if len(sys.argv) > 1 else "1.0.0"
TOKEN = os.environ["MODRINTH_TOKEN"]
UA = "ilhoon2025/aurora-dreams-publisher/legacy (manager4ut@gmail.com)"
ROOT = pathlib.Path(__file__).parent
SLUG = "aurora-dreams-legacy"
ZIP = ROOT / "dist" / f"AuroraDreams-Legacy-1.8.9-{VERSION}.zip"
GAL = ROOT / "assets" / "gallery-legacy"

def call(method, path, body=None, ctype=None):
    req = urllib.request.Request("https://api.modrinth.com/v2" + path, data=body, method=method,
                                 headers={"Authorization": TOKEN, "User-Agent": UA, **({"Content-Type": ctype} if ctype else {})})
    try:
        with urllib.request.urlopen(req) as r:
            raw = r.read(); return json.loads(raw) if raw else {}
    except urllib.error.HTTPError as e:
        if method == "GET" and e.code == 404: return None
        sys.exit(f"{method} {path} -> {e.code}: {e.read().decode()[:500]}")

def multipart(fields, files):
    b = uuid.uuid4().hex; out = b""
    for k, v in fields.items():
        out += f'--{b}\r\nContent-Disposition: form-data; name="{k}"\r\n\r\n{v}\r\n'.encode()
    for k, (name, data, ct) in files.items():
        out += (f'--{b}\r\nContent-Disposition: form-data; name="{k}"; filename="{name}"\r\nContent-Type: {ct}\r\n\r\n').encode() + data + b"\r\n"
    return out + f"--{b}--\r\n".encode(), f"multipart/form-data; boundary={b}"

readme = (ROOT / "README.md").read_text(encoding="utf-8")
start = readme.index("## Legacy edition"); end = readme.index("## Building the zip")
body = "# Aurora Dreams Legacy (Minecraft 1.8.9)\n\n" + readme[start:end].split("\n", 1)[1] + \
       "\nSource and the main (26.x / Iris) edition: https://github.com/ilhoon2025/aurora-dreams-shaders\n"

project = call("GET", f"/project/{SLUG}")
if project is None:
    data = {"slug": SLUG, "title": "Aurora Dreams Legacy (1.8.9)", "project_type": "shader",
            "description": "Aurora Dreams for Minecraft 1.8.9 + OptiFine: aurora sky, volumetric clouds, soft shadows, SSR water, bloom.",
            "body": body, "categories": ["semi-realistic"],
            "additional_categories": ["atmosphere", "bloom", "colored-lighting", "reflections", "shadows", "medium"],
            "client_side": "required", "server_side": "unsupported", "license_id": "MIT",
            "source_url": "https://github.com/ilhoon2025/aurora-dreams-shaders",
            "is_draft": True, "initial_versions": [], "organization_id": None}
    b, ct = multipart({"data": json.dumps(data)}, {})
    project = call("POST", "/project", b, ct); print("created project", project["id"])
    call("PATCH", f"/project/{SLUG}/icon?ext=png", (GAL / "icon.png").read_bytes(), "image/png"); print("icon uploaded")

if not any(v["version_number"] == VERSION for v in call("GET", f"/project/{SLUG}/version") or []):
    vdata = {"name": f"Aurora Dreams Legacy {VERSION}", "version_number": VERSION,
             "changelog": "First release for Minecraft 1.8.9 + OptiFine HD U M5. Tested: all shader programs load with zero errors (Java 8, NVIDIA MX450).",
             "dependencies": [], "game_versions": ["1.8.9"], "version_type": "release", "loaders": ["optifine"],
             "featured": True, "project_id": project["id"], "file_parts": ["file"], "primary_file": "file"}
    b, ct = multipart({"data": json.dumps(vdata)}, {"file": (ZIP.name, ZIP.read_bytes(), "application/zip")})
    print("uploaded version", call("POST", "/version", b, ct)["id"])

if not project.get("gallery"):
    meta = [("01-ocean-day.jpg", "Ocean (1.8.9)", "Water ripples, foam and clouds on Minecraft 1.8.9.", True),
            ("02-sunset-godrays.jpg", "Sunset god rays (1.8.9)", "Sun glow, god rays and bloom over the sea.", False),
            ("03-aurora-night.jpg", "Aurora night (1.8.9)", "Aurora borealis, stars and night clouds.", False)]
    for i, (f, t, d, feat) in enumerate(meta):
        q = urllib.parse.urlencode({"ext": "jpg", "featured": str(feat).lower(), "title": t, "description": d, "ordering": i})
        call("POST", f"/project/{SLUG}/gallery?{q}", (GAL / f).read_bytes(), "image/jpeg")
    print("gallery uploaded")

p = call("GET", f"/project/{SLUG}")
print("status", p["status"], "| tags", p["categories"] + p["additional_categories"],
      "| total", len(p["categories"]) + len(p["additional_categories"]), "| gallery", len(p["gallery"]),
      "| versions", [(v["version_number"], v["game_versions"], v["loaders"]) for v in call("GET", f"/project/{SLUG}/version")])
