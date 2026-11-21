"""Reject private Android signing files without displaying their contents."""

import argparse
from pathlib import PurePosixPath
import re
import subprocess
import sys


def is_private_signing_file(name):
    path = PurePosixPath(name)
    basename = path.name.lower()
    return (
        path.suffix.lower() in {".jks", ".keystore", ".p12", ".pfx"}
        or basename == "key.properties"
        or ("keystore" in basename and basename.endswith(".properties"))
    )


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--history", action="store_true", help="Also inspect all reachable Git history")
    args = parser.parse_args()
    names = set(subprocess.check_output(["git", "ls-files", "-z"]).decode().split("\0"))
    historical_gradle = []
    if args.history:
        objects = subprocess.check_output(["git", "rev-list", "--objects", "--all"], text=True)
        names.update(line.partition(" ")[2] for line in objects.splitlines())
        historical_gradle = [line.partition(" ") for line in objects.splitlines()
                             if line.endswith((".gradle", ".gradle.kts"))]
    blocked = sorted(name for name in names if name and is_private_signing_file(name))
    literal_password = re.compile(rb'''(?m)^\s*(?:storePassword|keyPassword)\s*(?:=\s*)?["']([^"']+)["']''')

    def has_password(data):
        return any(value not in {b"REMOVED_SIGNING_PASSWORD", b"REPLACE_LOCALLY"}
                   for value in literal_password.findall(data))

    inline = set()
    for name in names:
        if name.endswith((".gradle", ".gradle.kts")):
            result = subprocess.run(["git", "show", ":" + name], capture_output=True)
            if result.returncode == 0 and has_password(result.stdout):
                inline.add(name)
    for oid, _, name in historical_gradle:
        if subprocess.check_output(["git", "cat-file", "-t", oid]).strip() != b"blob":
            continue
        if has_password(subprocess.check_output(["git", "cat-file", "blob", oid])):
            inline.add(name)
    if blocked or inline:
        print("Signing secrets found in Git" + (" history" if args.history else "") + ":", file=sys.stderr)
        for name in blocked:
            print("  " + name, file=sys.stderr)
        for name in sorted(inline):
            print("  " + name + " (hard-coded signing password)", file=sys.stderr)
        return 1
    print("No signing files or hard-coded signing passwords found in " +
          ("tracked files or reachable history." if args.history else "tracked files."))
    return 0


if __name__ == "__main__":
    sys.exit(main())
