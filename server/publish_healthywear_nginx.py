"""Publish the HealthyWear route inside the existing apiict03 TLS vhost."""
import difflib
import os
import re
import stat
import subprocess
import sys
import tempfile
from datetime import datetime, timezone
from pathlib import Path

SITE = Path("/etc/nginx/sites-enabled/apiict03.etsii.upm.es")
HOST = "apiict03.etsii.upm.es"
ROUTE = """
    # HealthyWear Sensoria settings and password-protected editor.
    location ^~ /healthywear/ {
        proxy_pass http://127.0.0.1:8097;
        proxy_set_header Host $host;
        client_max_body_size 4k;
        proxy_read_timeout 10s;
    }
"""


def add_route(source):
    if ROUTE.strip() in source:
        return source
    if re.search(r"(?m)^\s*location\s+[^;\n{]*\/healthywear(?:\/|\s|\{)", source):
        raise SystemExit("A HealthyWear location already exists. Review the existing route first.")
    blocks = list(re.finditer(r"(?m)^\s*server\s*\{[^\n]*\n", source))
    matches = []
    for index, block in enumerate(blocks):
        end = blocks[index + 1].start() if index + 1 < len(blocks) else len(source)
        body = source[block.end():end]
        header = re.search(r"(?m)^\s*server_name\s+" + re.escape(HOST) + r"\s*;[^\n]*\n", body)
        if header and re.search(r"(?m)^\s*listen\s+443\s+[^;\n]*\bssl\b", body[:header.end()]):
            matches.append(block.end() + header.end())
    if len(matches) != 1:
        raise SystemExit("Expected exactly one matching TLS server block. No changes made.")
    index = matches[0]
    return source[:index] + ROUTE + source[index:]


def replace(path, content, previous):
    with tempfile.NamedTemporaryFile("w", dir=path.parent, delete=False) as handle:
        temporary = Path(handle.name)
        try:
            os.fchown(handle.fileno(), previous.st_uid, previous.st_gid)
            os.fchmod(handle.fileno(), stat.S_IMODE(previous.st_mode))
            handle.write(content)
            handle.flush()
            os.fsync(handle.fileno())
            os.replace(temporary, path)
        finally:
            temporary.unlink(missing_ok=True)


def main():
    if sys.argv[1:] not in ([], ["--preview"]):
        raise SystemExit("Usage: publish_healthywear_nginx.py [--preview]")
    path = SITE.resolve(strict=True)
    source = path.read_text()
    updated = add_route(source)
    if sys.argv[1:] == ["--preview"]:
        print("".join(difflib.unified_diff(source.splitlines(True), updated.splitlines(True),
                                          fromfile=str(path), tofile=str(path), n=0)) or "Route already present.")
        return
    if os.geteuid() != 0:
        raise SystemExit("Run this script with sudo from your interactive SSH session.")
    if source == updated:
        print("HealthyWear route already present. Testing and reloading Nginx.")
        subprocess.run(["/usr/sbin/nginx", "-t"], check=True)
        subprocess.run(["/usr/bin/systemctl", "reload", "nginx"], check=True)
        return
    timestamp = datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%S%fZ")
    backup = Path("/var/backups") / f"apiict03.nginx-before-healthywear-{timestamp}"
    with backup.open("x") as handle:
        os.fchmod(handle.fileno(), 0o600)
        handle.write(source)
    previous = path.stat()
    replace(path, updated, previous)
    try:
        subprocess.run(["/usr/sbin/nginx", "-t"], check=True)
        subprocess.run(["/usr/bin/systemctl", "reload", "nginx"], check=True)
    except (OSError, subprocess.CalledProcessError):
        replace(path, source, previous)
        print(f"Restored the original site configuration. Backup: {backup}", file=sys.stderr)
        raise
    print(f"Published HealthyWear. Backup: {backup}")


if __name__ == "__main__":
    main()
