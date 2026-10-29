#!/usr/bin/env python3
"""Check only tracked product files, without printing possible secret values."""
from pathlib import Path
import re
import subprocess
import sys
ROOT = Path(__file__).resolve().parents[1]
files = subprocess.check_output(["git", "ls-files", "-z"], cwd=ROOT).decode().split("\0")
bad = []
secret = re.compile(rb"gh[pousr]_[A-Za-z0-9]{20,}|github_pat_[A-Za-z0-9_]{20,}|sk-[A-Za-z0-9]{25,}|-----BEGIN (?:RSA |EC |OPENSSH )?PRIVATE KEY-----")
for name in filter(None, files):
    p = Path(name)
    if set(p.parts) & {"doc", "docs", ".codex", ".claude", ".godot", "work", "outputs"} or name.startswith(("assets/pet/", "assets/local/")) or re.search(r"(?i)(^|/)(AGENTS\.md|find\.md|.*plan.*\.md|.*report.*\.md)$", name) or p.suffix in {".exe", ".pck", ".import", ".log", ".key", ".pem"}:
        bad.append(name)
    content = (ROOT / name).read_bytes()
    if p.suffix not in {".otf", ".png"} and secret.search(content):
        bad.append(name + " (secret pattern)")
if bad:
    sys.exit("Repository audit failed:\n" + "\n".join(bad))
print("Repository audit passed: tracked files contain no forbidden paths or secret patterns.")
