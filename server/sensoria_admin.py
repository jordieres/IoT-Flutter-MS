"""Password-protected editor for the HealthyWear connection profile."""
import getpass
import hashlib
import hmac
import json
import os
import secrets
import sys
import tempfile
import time
from collections import deque
from http.server import BaseHTTPRequestHandler, HTTPServer
from http.cookies import CookieError, SimpleCookie
from pathlib import Path
from urllib.parse import parse_qs

from sensoria_views import ADMIN, change_password_page, login_page, settings_page

ROOT = Path(__file__).resolve().parent
PROFILE = ROOT / "sensoria-settings.json"
PASSWORD = ROOT / ".sensoria-admin-password"
API = "/healthywear/sensoria-settings.json"
SECRET = secrets.token_bytes(32)
COOKIE = "healthywear_admin"
SESSION_SECONDS = 8 * 60 * 60
SESSIONS = {}
FAILED_LOGINS = deque(maxlen=12)
PUBLIC_HOST = "apiict03.etsii.upm.es"
LOCAL_HOSTS = {"localhost:8097", "127.0.0.1:8097"}
MOTION = (0, 13, 26, 52, 104, 208, 416, 833, 1660)
GROUPS = (
    ("Accelerometer", (("accelerometerG", "Range", "g", (2, 4, 8, 16)),
                       ("accelerometerHz", "Sampling rate", "Hz", MOTION))),
    ("Gyroscope", (("gyroscopeDps", "Range", "°/s", (245, 500, 1000, 2000)),
                   ("gyroscopeHz", "Sampling rate", "Hz", MOTION))),
    ("Magnetometer", (("magnetometerGauss", "Range", "gauss", (4, 8, 12, 16)),
                      ("magnetometerHz", "Sampling rate", "Hz", (0, 5, 10, 20, 40, 80)))),
    ("Bluetooth stream", (("streamPeriodMs", "Packet period", "ms", (0, 10, 20, 25, 32, 40, 50, 100, 200)),)),
)
FIELDS = tuple(field for _, fields in GROUPS for field in fields)


def save(path, content):
    with tempfile.NamedTemporaryFile(mode="w", encoding="utf-8", dir=ROOT, delete=False) as tmp:
        tmp.write(content)
    os.replace(tmp.name, path)


def digest(password, salt):
    return hashlib.scrypt(password.encode(), salt=salt, n=16384, r=8, p=1).hex()


def password_matches(password):
    try:
        salt, expected = PASSWORD.read_text().strip().split(":")
        return len(password) <= 256 and hmac.compare_digest(
            digest(password, bytes.fromhex(salt)), expected)
    except (OSError, ValueError):
        return False


def store_password(password):
    salt = secrets.token_bytes(16)
    save(PASSWORD, f"{salt.hex()}:{digest(password, salt)}\n")


def password_attempts_limited(now):
    while FAILED_LOGINS and now - FAILED_LOGINS[0] >= 60:
        FAILED_LOGINS.popleft()
    return len(FAILED_LOGINS) == FAILED_LOGINS.maxlen


def profile():
    data = json.loads(PROFILE.read_text())
    if type(data["schemaVersion"]) is not int or data["schemaVersion"] != 1:
        raise ValueError("Invalid schema")
    if type(data["revision"]) is not int or data["revision"] < 1:
        raise ValueError("Invalid revision")
    for key, _, _, options in FIELDS:
        value = data.setdefault(key, 0)
        if type(value) is not int or value not in options:
            raise ValueError(f"Invalid setting: {key}")
    return data


def token(session, action):
    return hmac.new(SECRET, f"{session}:{action}".encode(), "sha256").hexdigest()


def prune_sessions(now):
    expired = [key for key, (deadline, _) in SESSIONS.items() if now >= deadline]
    for key in expired:
        del SESSIONS[key]


class Handler(BaseHTTPRequestHandler):
    def setup(self):
        super().setup()
        self.connection.settimeout(8)

    def respond(self, status, body, mime="text/plain", **headers):
        encoded = body.encode()
        self.send_response(status)
        self.send_header("Content-Type", mime + "; charset=utf-8")
        self.send_header("Content-Length", str(len(encoded)))
        self.send_header("Cache-Control", "no-store")
        self.send_header("X-Content-Type-Options", "nosniff")
        self.send_header("Content-Security-Policy",
                         "default-src 'none'; style-src 'unsafe-inline'; form-action 'self'; frame-ancestors 'none'; base-uri 'none'")
        for key, value in headers.items():
            self.send_header(key.replace("_", "-"), value)
        self.end_headers()
        self.wfile.write(encoded)

    def request_origin(self):
        host = self.headers.get("Host", "").lower()
        if host == PUBLIC_HOST:
            return f"https://{host}"
        if host in LOCAL_HOSTS:
            return f"http://{host}"
        return None

    def cookie_header(self, value, age):
        secure = "" if self.headers.get("Host", "").lower() in LOCAL_HOSTS else "; Secure"
        return (f"{COOKIE}={value}; Path={ADMIN}; Max-Age={age}; "
                f"HttpOnly; SameSite=Strict{secure}")

    def session(self):
        try:
            cookie = SimpleCookie(self.headers.get("Cookie", "")).get(COOKIE)
            if not cookie:
                return None
            key = cookie.value
            entry = SESSIONS.get(key)
            if not entry:
                return None
            deadline, password_revision = entry
            if time.monotonic() >= deadline or PASSWORD.stat().st_mtime_ns != password_revision:
                SESSIONS.pop(key, None)
                return None
            return key
        except (CookieError, OSError):
            return None

    def read_form(self):
        size = int(self.headers.get("Content-Length", "0"))
        if not 0 < size <= 4096 or self.headers.get_content_type() != "application/x-www-form-urlencoded":
            raise ValueError
        return parse_qs(self.rfile.read(size).decode(), strict_parsing=True, max_num_fields=12)

    def editor(self, session, saved=False, error="", status=200):
        data = profile()
        self.respond(status, settings_page(
            data, GROUPS, token(session, data["revision"]), token(session, "logout"),
            saved=saved, error=error), "text/html")

    def do_GET(self):
        if self.path in ("/healthywear/", ADMIN + "/"):
            self.respond(303, "Open HealthyWear settings.", Location=ADMIN)
        elif self.path == API:
            self.respond(200, json.dumps(profile()) + "\n", "application/json")
        elif self.path in (ADMIN, ADMIN + "?saved=1", ADMIN + "?password-changed=1", ADMIN + "/password"):
            session = self.session()
            if session:
                if self.path == ADMIN + "/password":
                    self.password_editor(session)
                else:
                    self.editor(session, self.path.endswith("?saved=1"))
            elif PASSWORD.is_file():
                self.respond(200, login_page(changed=self.path.endswith("?password-changed=1")), "text/html")
            else:
                self.respond(503, login_page("The administrator password has not been set.", True), "text/html")
        else:
            self.respond(404, "Page not found.")

    def sign_in(self, form):
        if not PASSWORD.is_file():
            self.respond(503, login_page("The administrator password has not been set.", True), "text/html")
            return
        now = time.monotonic()
        if password_attempts_limited(now):
            self.respond(429, login_page("Too many attempts. Try again in a minute."),
                         "text/html", Retry_After="60")
            return
        try:
            user, = form["username"]
            password, = form["password"]
            valid = password_matches(password) and user == "admin"
        except (ValueError, KeyError, OSError):
            valid = False
        if not valid:
            FAILED_LOGINS.append(now)
            self.respond(401, login_page("Check your username and password and try again."), "text/html")
            return
        prune_sessions(now)
        old_session = self.session()
        if old_session:
            SESSIONS.pop(old_session, None)
        if len(SESSIONS) >= 64:
            del SESSIONS[next(iter(SESSIONS))]
        session = secrets.token_urlsafe(32)
        SESSIONS[session] = (now + SESSION_SECONDS, PASSWORD.stat().st_mtime_ns)
        self.respond(303, "Signed in.", Location=ADMIN,
                     Set_Cookie=self.cookie_header(session, SESSION_SECONDS))

    def password_editor(self, session, error="", status=200):
        self.respond(status, change_password_page(
            token(session, "password"), token(session, "logout"), error), "text/html")

    def change_password(self, session):
        try:
            form = self.read_form()
            submitted, = form["token"]
            current, = form["current"]
            new, = form["new"]
            confirm, = form["confirm"]
        except (ValueError, KeyError):
            self.password_editor(session, "Complete all three password fields.", 400)
            return
        if not hmac.compare_digest(submitted.encode(), token(session, "password").encode()):
            self.password_editor(session, "Reload this page and try again.", 403)
            return
        now = time.monotonic()
        if password_attempts_limited(now):
            self.password_editor(session, "Too many attempts. Try again in a minute.", 429)
            return
        if not password_matches(current):
            FAILED_LOGINS.append(now)
            self.password_editor(session, "The current password is incorrect.", 400)
            return
        if not 12 <= len(new) <= 256 or new != confirm:
            self.password_editor(session, "Use 12 to 256 characters and enter the same new password twice.", 400)
            return
        if new == current:
            self.password_editor(session, "Choose a different password.", 400)
            return
        try:
            store_password(new)
        except OSError:
            self.password_editor(session, "The password could not be saved. Try again.", 500)
            return
        SESSIONS.clear()
        FAILED_LOGINS.clear()
        self.respond(303, "Password changed.", Location=ADMIN + "?password-changed=1",
                     Set_Cookie=self.cookie_header("", 0))

    def do_POST(self):
        if self.path not in (ADMIN, ADMIN + "/login", ADMIN + "/logout", ADMIN + "/password"):
            self.respond(404, "Page not found.")
            return
        origin = self.request_origin()
        if not origin or self.headers.get("Origin") != origin:
            self.respond(403, "Open the HealthyWear page directly and try again.")
            return
        if self.path == ADMIN + "/login":
            try:
                form = self.read_form()
            except ValueError:
                self.respond(400, login_page("Enter your username and password."), "text/html")
                return
            self.sign_in(form)
            return
        session = self.session()
        if not session:
            self.respond(303, "Sign in to continue.", Location=ADMIN)
            return
        if self.path == ADMIN + "/password":
            self.change_password(session)
            return
        try:
            form = self.read_form()
            submitted, = form["token"]
            if self.path == ADMIN + "/logout":
                if not hmac.compare_digest(submitted, token(session, "logout")):
                    self.respond(403, "Reload the page before signing out.")
                    return
                SESSIONS.pop(session, None)
                self.respond(303, "Signed out.", Location=ADMIN, Set_Cookie=self.cookie_header("", 0))
                return
            data = profile()
            if not hmac.compare_digest(submitted, token(session, data["revision"])):
                self.editor(session, error="The saved settings changed. Review the current profile before saving.", status=409)
                return
            for key, _, _, options in FIELDS:
                value, = form[key]
                data[key] = int(value)
                if data[key] not in options:
                    raise ValueError
        except (ValueError, KeyError):
            self.editor(session, error="Choose a supported value for every setting.", status=400)
            return
        data["revision"] += 1
        save(PROFILE, json.dumps(data, indent=2) + "\n")
        self.respond(303, "Settings saved.", Location=ADMIN + "?saved=1")


if __name__ == "__main__":
    if sys.argv[1:] == ["--set-password"]:
        password = getpass.getpass("HealthyWear admin password: ")
        if not 12 <= len(password) <= 256 or password != getpass.getpass("Confirm password: "):
            raise SystemExit("Use 12–256 characters and enter the same password twice.")
        store_password(password)
    else:
        profile()
        HTTPServer(("127.0.0.1", 8097), Handler).serve_forever()
