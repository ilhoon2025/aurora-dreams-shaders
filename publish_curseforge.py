"""Upload a release zip to the existing CurseForge project.

  CURSEFORGE_TOKEN=<upload token from authors.curseforge.com > API tokens (UUID form)> \
  python publish_curseforge.py 1.3.0

The token is read from the environment only. The project (id below) must already exist.
"""
import json, os, pathlib, sys, urllib.request, uuid

PROJECT_ID = 1759474
VERSION = sys.argv[1] if len(sys.argv) > 1 else "1.3.0"
GAME_VERSION_NAMES = ["26.3"]
TOKEN = os.environ["CURSEFORGE_TOKEN"]
ROOT = pathlib.Path(__file__).parent
ZIP = ROOT / "dist" / f"AuroraDreams-{VERSION}.zip"
BASE = "https://minecraft.curseforge.com/api"


def req(method, path, body=None, ctype=None):
    r = urllib.request.Request(BASE + path, data=body, method=method,
                               headers={"X-Api-Token": TOKEN, **({"Content-Type": ctype} if ctype else {})})
    try:
        with urllib.request.urlopen(r) as resp:
            return json.loads(resp.read())
    except urllib.error.HTTPError as e:
        sys.exit(f"{method} {path} -> {e.code}: {e.read().decode()[:500]}")


versions = req("GET", "/game/versions")
ids = [v["id"] for v in versions if v["name"] in GAME_VERSION_NAMES]
if not ids:
    sys.exit(f"No CurseForge game version matches {GAME_VERSION_NAMES}")

meta = {"changelog": "See https://github.com/ilhoon2025/aurora-dreams-shaders/releases",
        "changelogType": "markdown", "displayName": f"Aurora Dreams {VERSION}",
        "gameVersions": ids, "releaseType": "release"}
b = uuid.uuid4().hex
body = (f'--{b}\r\nContent-Disposition: form-data; name="metadata"\r\n\r\n{json.dumps(meta)}\r\n'
        f'--{b}\r\nContent-Disposition: form-data; name="file"; filename="{ZIP.name}"\r\n'
        f'Content-Type: application/zip\r\n\r\n').encode() + ZIP.read_bytes() + f"\r\n--{b}--\r\n".encode()
print("uploaded file id:", req("POST", f"/projects/{PROJECT_ID}/upload-file", body,
                               f"multipart/form-data; boundary={b}").get("id"))
