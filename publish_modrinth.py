"""Create the Modrinth project (first run) and upload a version.

  MODRINTH_TOKEN=<PAT with create-project/create-version/write-project scopes> \
  python publish_modrinth.py 1.3.0

Tokens are read from the environment only and never written to disk.
"""
import json, os, pathlib, sys, urllib.request, uuid

VERSION = sys.argv[1] if len(sys.argv) > 1 else "1.3.0"
TOKEN = os.environ["MODRINTH_TOKEN"]
UA = "ilhoon2025/aurora-dreams-publisher/1.3.0 (manager4ut@gmail.com)"
ROOT = pathlib.Path(__file__).parent
ZIP = ROOT / "dist" / f"AuroraDreams-{VERSION}.zip"
GAME_VERSIONS = ["26.3"]
SLUG = "aurora-dreams"


def multipart(fields, files):
    b = uuid.uuid4().hex
    out = b""
    for k, v in fields.items():
        out += f'--{b}\r\nContent-Disposition: form-data; name="{k}"\r\n\r\n{v}\r\n'.encode()
    for k, (name, data, ctype) in files.items():
        out += (f'--{b}\r\nContent-Disposition: form-data; name="{k}"; filename="{name}"\r\n'
                f'Content-Type: {ctype}\r\n\r\n').encode() + data + b"\r\n"
    return out + f"--{b}--\r\n".encode(), f"multipart/form-data; boundary={b}"


def call(method, path, body=None, ctype=None):
    req = urllib.request.Request("https://api.modrinth.com/v2" + path, data=body, method=method,
                                 headers={"Authorization": TOKEN, "User-Agent": UA,
                                          **({"Content-Type": ctype} if ctype else {})})
    try:
        with urllib.request.urlopen(req) as r:
            raw = r.read()
            return json.loads(raw) if raw else {}
    except urllib.error.HTTPError as e:
        sys.exit(f"{method} {path} -> {e.code}: {e.read().decode()[:500]}")


def project_exists():
    try:
        urllib.request.urlopen(urllib.request.Request(
            f"https://api.modrinth.com/v2/project/{SLUG}", headers={"User-Agent": UA}))
        return True
    except urllib.error.HTTPError:
        return False


if not project_exists():
    data = {
        "slug": SLUG, "title": "Aurora Dreams", "project_type": "shader",
        "description": "A cinematic shader: aurora night sky, volumetric clouds, soft shadows, SSR water, coloured light.",
        "body": (ROOT / "README.md").read_text(encoding="utf-8"),
        "categories": ["fantasy", "semi-realistic"],
        "additional_categories": ["atmosphere", "bloom", "colored-lighting", "foliage", "reflections", "shadows", "medium"],
        "client_side": "required", "server_side": "unsupported",
        "license_id": "MIT", "source_url": "https://github.com/ilhoon2025/aurora-dreams-shaders",
        "is_draft": True, "initial_versions": [], "organization_id": None,
    }
    body, ct = multipart({"data": json.dumps(data)}, {})
    print("created project:", call("POST", "/project", body, ct).get("id"))

vdata = {
    "name": f"Aurora Dreams {VERSION}", "version_number": VERSION,
    "changelog": "See https://github.com/ilhoon2025/aurora-dreams-shaders/releases",
    "dependencies": [], "game_versions": GAME_VERSIONS, "version_type": "release",
    "loaders": ["iris", "optifine"], "featured": True, "project_id": SLUG,
    "file_parts": ["file"], "primary_file": "file",
}
body, ct = multipart({"data": json.dumps(vdata)}, {"file": (ZIP.name, ZIP.read_bytes(), "application/zip")})
print("uploaded version:", call("POST", "/version", body, ct).get("id"))
print("Project is a DRAFT. Review it on modrinth.com and submit for review there.")
