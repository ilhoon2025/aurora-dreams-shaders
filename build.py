"""Zip the shaders/ folder into dist/AuroraDreams-<version>.zip (shaders/ at archive root)."""
import pathlib, sys, zipfile
VERSION = sys.argv[1] if len(sys.argv) > 1 else "1.0.0"
root = pathlib.Path(__file__).parent
out = root / "dist"; out.mkdir(exist_ok=True)
target = out / f"AuroraDreams-{VERSION}.zip"
with zipfile.ZipFile(target, "w", zipfile.ZIP_DEFLATED) as z:
    for f in sorted((root / "shaders").rglob("*")):
        if f.is_file():
            z.write(f, f.relative_to(root).as_posix())
    z.write(root / "LICENSE", "LICENSE")
print(target)
