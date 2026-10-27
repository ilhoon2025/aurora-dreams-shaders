"""Upload the 1.8.9 legacy zip to the CurseForge project 'aurora-dreams-legacy' (id 1768642).

  CURSEFORGE_TOKEN=<upload token (UUID)> python publish_legacy_curseforge.py 1.0.0
"""
import json, os, pathlib, sys, urllib.request, uuid

PROJECT_ID = 1768642
VERSION = sys.argv[1] if len(sys.argv) > 1 else "1.0.0"
NAMES = ["1.8.9", "OptiFine"]
TOKEN = os.environ["CURSEFORGE_TOKEN"]
ZIP = pathlib.Path(__file__).parent / "dist" / f"AuroraDreams-Legacy-1.8.9-{VERSION}.zip"
BASE = "https://minecraft.curseforge.com/api"

def req(method, path, body=None, ctype=None):
    r = urllib.request.Request(BASE + path, data=body, method=method,
                               headers={"X-Api-Token": TOKEN, **({"Content-Type": ctype} if ctype else {})})
    try:
        with urllib.request.urlopen(r) as resp: return json.loads(resp.read())
    except urllib.error.HTTPError as e:
        sys.exit(f"{method} {path} -> {e.code}: {e.read().decode()[:500]}")

versions = req("GET", "/game/versions")
ids = [v["id"] for v in versions if v["name"] in NAMES and v["gameVersionTypeID"] != 1]
found = sorted({v["name"] for v in versions if v["id"] in ids})
print("game version ids", ids, found)
if "1.8.9" not in found: sys.exit("no CurseForge game version named 1.8.9")

meta = {"changelog": "First release for Minecraft 1.8.9 + OptiFine HD U M5. Tested: all shader programs load with zero errors (Java 8, NVIDIA MX450).",
        "changelogType": "markdown", "displayName": f"Aurora Dreams Legacy {VERSION} (1.8.9)",
        "gameVersions": ids, "releaseType": "release"}
b = uuid.uuid4().hex
body = (f'--{b}\r\nContent-Disposition: form-data; name="metadata"\r\n\r\n{json.dumps(meta)}\r\n'
        f'--{b}\r\nContent-Disposition: form-data; name="file"; filename="{ZIP.name}"\r\n'
        f'Content-Type: application/zip\r\n\r\n').encode() + ZIP.read_bytes() + f"\r\n--{b}--\r\n".encode()
print("uploaded file id:", req("POST", f"/projects/{PROJECT_ID}/upload-file", body, f"multipart/form-data; boundary={b}").get("id"))
