"""Run search and logistics regressions in an isolated Factorio profile."""
import json
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile

root = Path(__file__).resolve().parents[1]
factorio = Path(sys.argv[1]).resolve()
save = Path(sys.argv[2]).resolve()
qa = Path(tempfile.mkdtemp(prefix="factory-palette-tests-"))
mods = qa / "mods"
mods.mkdir()
mod = mods / root.name
shutil.copytree(root, mod, ignore=shutil.ignore_patterns(".git", "dist"))
with (mod / "control.lua").open("a") as control:
    control.write('\nhandler.add_lib(require("tests.regression"))\n')
flib = max(root.parent.glob("flib_*.zip"), key=lambda p: tuple(map(int, p.stem.split("_")[-1].split("."))))
shutil.copy2(flib, mods / flib.name)
(mods / "mod-list.json").write_text(json.dumps({"mods": [{"name": name, "enabled": True} for name in ["base", "flib", "factory-palette"]]}))
config = qa / "config.ini"
config.write_text(f"[path]\nread-data=__PATH__system-read-data__\nwrite-data={qa}\n[other]\ncheck-updates=false\nautosave-interval=0\n")
command = [str(factorio), "--config", str(config), "--mod-directory", str(mods), "--benchmark", str(save), "--benchmark-ticks", "3", "--benchmark-runs", "1", "--disable-audio"]
result = subprocess.run(command, capture_output=True, text=True, timeout=120)
log = result.stdout + result.stderr
(qa / "test.log").write_text(log)
print("Test artifacts:", qa)
if result.returncode or "FACTORY PALETTE REGRESSION PASS" not in log:
    print(log[-5000:])
    raise SystemExit(1)
print("FACTORY PALETTE REGRESSION PASS")
