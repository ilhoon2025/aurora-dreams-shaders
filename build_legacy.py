"""Build the Minecraft 1.8.9 (OptiFine HD U M5) edition of Aurora Dreams from the main shaders/ tree.

  python build_legacy.py [version]   ->  dist/AuroraDreams-Legacy-1.8.9-<version>.zip

OptiFine 1.8.9 M5 supports colortex0-7, 16 composite passes, #include, RGBA16F, shadowLightPosition and
heldItemId, so only the block/item id mappings (1.8 has numeric ids, no namespaced names) differ.
"""
import pathlib, shutil, sys, zipfile
VERSION = sys.argv[1] if len(sys.argv) > 1 else "1.0.0"
ROOT = pathlib.Path(__file__).parent
STAGE = ROOT / "dist" / "legacy_stage"
if STAGE.exists(): shutil.rmtree(STAGE)
shutil.copytree(ROOT / "shaders", STAGE / "shaders")
for name in ("block.properties", "item.properties"):
    shutil.copy(ROOT / "legacy" / name, STAGE / "shaders" / name)
out = ROOT / "dist" / f"AuroraDreams-Legacy-1.8.9-{VERSION}.zip"
with zipfile.ZipFile(out, "w", zipfile.ZIP_DEFLATED) as z:
    for f in sorted((STAGE / "shaders").rglob("*")):
        if f.is_file(): z.write(f, f.relative_to(STAGE).as_posix())
    z.write(ROOT / "LICENSE", "LICENSE")
print(out)
