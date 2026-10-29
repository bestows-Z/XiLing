#!/usr/bin/env python3
"""Run import and every actual Godot test; an engine exit code alone is insufficient."""
from pathlib import Path
import os
import shutil
import subprocess
import sys
import tempfile

ROOT = Path(__file__).resolve().parents[1]
engine = os.environ.get("GODOT_BIN") or shutil.which("godot") or shutil.which("godot4")
if not engine:
    sys.exit("Godot was not found; set GODOT_BIN to the Godot 4.7.2 executable.")
with tempfile.TemporaryDirectory(prefix="xiling-check-") as log_dir:
    commands = [("import", ["--editor", "--quit"])]
    commands += [(p.stem, ["--script", str(p.relative_to(ROOT))]) for p in sorted((ROOT / "tests").glob("*_tests.gd"))]
    for name, args in commands:
        try:
            result = subprocess.run([engine, "--headless", "--path", str(ROOT), "--log-file", str(Path(log_dir) / (name + ".log")), *args], capture_output=True, text=True, timeout=120)
        except subprocess.TimeoutExpired:
            sys.exit(f"FAIL {name}: timed out")
        output = result.stdout + result.stderr
        failed = result.returncode != 0 or "ERROR:" in output or "SCRIPT ERROR" in output
        print(("FAIL " if failed else "PASS ") + name)
        if name != "import" or failed:
            print(output.strip())
        if failed:
            sys.exit(1)
print("All Godot checks passed.")
