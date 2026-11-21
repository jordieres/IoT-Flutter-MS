"""HTML views for the Sensoria study console."""
import html

CSS = """
:root{color-scheme:light;--paper:#f2f5fa;--white:#fff;--ink:#132a4d;--muted:#475a75;--line:#d3dceb;--blue:#173f77}
*{box-sizing:border-box}body{margin:0;background:var(--paper);color:var(--ink);font:16px/1.5 "Avenir Next","Segoe UI",system-ui,sans-serif}
h1,h2,p{margin:0}h1{font-size:clamp(2rem,5vw,3.4rem);line-height:1.08;letter-spacing:-.045em}h2{font-size:1.24rem;letter-spacing:-.022em}p{color:var(--muted)}
a{color:var(--blue);text-underline-offset:3px}.shell{width:min(1180px,100% - 48px);margin:auto}
header{background:var(--white);border-bottom:1px solid var(--line)}.masthead{display:flex;align-items:center;justify-content:space-between;min-height:66px;gap:16px}
.nav{display:flex;gap:10px;align-items:center}.nav a{font-weight:650;font-size:.9rem;white-space:nowrap}.brand{display:flex;align-items:center;gap:10px;font-weight:750;letter-spacing:-.025em}.brand svg{width:35px;height:35px;flex:none}
.product{font-size:.86rem;color:var(--muted);border-left:1px solid var(--line);padding-left:13px;margin-left:4px;letter-spacing:0;font-weight:500}
button,input,select{font:inherit}button{cursor:pointer}.primary{padding:11px 18px;border:1px solid var(--blue);border-radius:7px;background:var(--blue);color:#fff;font-weight:700;min-height:46px}.primary:hover{background:#102d58}.quiet{border:1px solid var(--line);border-radius:7px;background:var(--white);color:var(--ink);padding:7px 12px;font-weight:650;white-space:nowrap}
:focus-visible{outline:3px solid #226fb5;outline-offset:3px}label{display:block;font-size:.88rem;font-weight:700}
select,input:not([type=hidden]){display:block;width:100%;min-height:44px;margin-top:6px;border:1px solid #879ab7;border-radius:7px;background:#fff;color:var(--ink);padding:8px 10px}
.intro{padding:38px 0 24px}.workspace{max-width:920px;padding-bottom:45px}
.panel{background:var(--white);border:1px solid var(--line);border-radius:12px;overflow:hidden}.panel-title{padding:18px 21px;border-bottom:1px solid var(--line)}
.row{display:grid;grid-template-columns:minmax(160px,1.25fr) minmax(0,1fr) minmax(0,1.18fr);gap:15px;align-items:center;padding:16px 21px;margin:0;border:0;border-bottom:1px solid var(--line);min-width:0}
.row:last-of-type{border-bottom:0}.row-name{font-weight:750;display:block}.row-hint,.note{font-size:.86rem;color:var(--muted)}.stream .control{grid-column:2/4}.actions{display:flex;align-items:center;justify-content:space-between;gap:16px;padding:16px 21px;border-top:1px solid var(--line);background:#f8faff}
.notice{border:1px solid #a7c7ee;background:#e9f2ff;color:#123c73;border-radius:7px;padding:10px 13px;margin-bottom:16px}.error{background:#fff1e9;border-color:#e2bbab;color:#802d1a}
.login{display:grid;grid-template-columns:1.05fr 1fr;max-width:940px;margin:clamp(32px,9vh,100px) auto 42px;border-radius:16px;overflow:hidden;border:1px solid var(--line);background:var(--white)}
.signal{background:#102e59;color:#f1f6ff;padding:38px;display:flex;flex-direction:column;justify-content:space-between;gap:33px}.signal h1{font-size:clamp(2rem,4vw,3.25rem)}.signal p{color:#cfdef5;margin-top:12px}.signal svg{width:100%;height:auto}.signin{padding:clamp(24px,5vw,50px);align-self:center}.signin h2{font-size:1.8rem}.signin p{margin:8px 0 21px}.signin label{margin-bottom:15px}.signin .primary{width:100%;margin-top:3px}.signin .notice{margin:14px 0}.password-panel{max-width:510px;margin:32px auto;padding:24px}.password-panel h1{font-size:2rem;margin-bottom:8px}.password-panel label{margin:16px 0}.password-panel .primary{margin-top:7px}.password-panel .notice{margin-top:15px}
@media(max-width:650px){.shell{width:calc(100% - 28px)}.product{display:none}.intro{padding:26px 0 20px}.row{grid-template-columns:repeat(2,minmax(0,1fr));gap:8px 12px;padding:13px 15px}.row>div:first-child{grid-column:1/-1}.stream .control{grid-column:1/-1}.panel-title,.actions{padding:14px 15px}.actions{align-items:flex-start;flex-direction:column-reverse;gap:8px}.actions button{width:100%}.login{grid-template-columns:minmax(0,1fr)}.signal{padding:23px;gap:10px}.signal svg{max-height:93px}.signal p{margin-top:6px}.login{margin-top:24px}}
@media(max-width:440px){.masthead{flex-wrap:wrap;gap:8px 14px;padding:9px 0}.nav{margin-left:auto}.row{grid-template-columns:minmax(0,1fr)}}
@media(max-width:365px){.nav{gap:6px}.brand{font-size:.92rem}.brand svg{width:28px;height:28px}.quiet{padding:6px 8px}}
"""

MARK = """<svg viewBox="0 0 36 36" aria-hidden="true"><rect width="36" height="36" rx="8" fill="#173f77"/><path d="M6 20h6l3-8 5 14 3-6h7" fill="none" stroke="#c8e1ff" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"/></svg>"""
TRACE = """<svg viewBox="0 0 370 112" aria-hidden="true"><path d="M0 96h370M0 68h370M0 40h370M0 12h370M24 0v112m52-112v112m52-112v112m52-112v112m52-112v112m52-112v112m52-112v112" stroke="#7395c8" stroke-opacity=".32"/><path d="M0 84c25 0 32 2 44-5s15-48 27-57 14 44 27 45 18-25 35-23 16 35 36 38h24c24 0 31 2 43-5s15-48 27-57 14 44 27 45 18-25 35-23 16 35 36 38h9" fill="none" stroke="#a8d3ff" stroke-width="3" stroke-linecap="round"/><circle cx="71" cy="22" r="4" fill="#ffda91"/><circle cx="263" cy="20" r="4" fill="#ffda91"/></svg>"""
ADMIN = "/healthywear/admin"


def layout(title, body, signout=""):
    return f"""<!doctype html><html lang="en"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>{title} | HealthyWear</title><style>{CSS}</style></head><body>
<header><div class="masthead shell"><div class="brand">{MARK} HealthyWear
<span class="product">Gait study console</span></div>{signout}</div></header>
{body}</body></html>"""


def hidden(value):
    return f'<input type="hidden" name="token" value="{html.escape(value, quote=True)}">'


def login_page(message="", unavailable=False, changed=False):
    notice = f'<div role="alert" class="notice error">{html.escape(message)}</div>' if message else ""
    if changed:
        notice = '<p class="notice" role="status">Password changed. Sign in with your new password.</p>'
    form = "" if unavailable else f"""<form method="post" action="{ADMIN}/login">
<label for="username">Username<input id="username" name="username" autocomplete="username" required value="admin"></label>
<label for="password">Password<input id="password" name="password" type="password" autocomplete="current-password" required maxlength="256"></label>
<button class="primary">Sign in</button></form>"""
    return layout("Sign in", f"""<main class="shell"><div class="login"><section class="signal">
<div><h1>Sensoria study setup</h1><p>Manage the sensor profile used to collect walking data.</p></div>
{TRACE}</section><section class="signin"><h2>Staff sign in</h2>
<p>Use your HealthyWear administrator credentials.</p>{notice}{form}</section></div></main>""")


def settings_page(data, groups, csrf, logout_token, saved=False, error=""):
    descriptions = {
        "Accelerometer": "Linear acceleration",
        "Gyroscope": "Angular velocity",
        "Magnetometer": "Magnetic field",
        "Bluetooth stream": "Data sent to the phone",
    }
    rows = []
    for title, fields in groups:
        controls = []
        for key, label, unit, choices in fields:
            options = []
            for value in choices:
                text = ("Keep device setting" if not value else
                        f"{value} ms ({1000 / value:g} packets/s)" if key == "streamPeriodMs" else
                        f"±{value} {unit}" if key in ("accelerometerG", "gyroscopeDps", "magnetometerGauss")
                        else f"{value} {unit}")
                options.append(f'<option value="{value}"{" selected" if value == data[key] else ""}>{html.escape(text)}</option>')
            controls.append(f'<div class="control"><label for="{key}">{label}</label><select name="{key}" id="{key}">{"".join(options)}</select></div>')
        stream = " stream" if title == "Bluetooth stream" else ""
        rows.append(f'<section class="row{stream}" aria-label="{title}"><div><span class="row-name">{title}</span><span class="row-hint">{descriptions[title]}</span></div>{"".join(controls)}</section>')
    notice = ""
    if error:
        notice = f'<div class="notice error" role="alert">{html.escape(error)}</div>'
    elif saved:
        notice = '<div class="notice" role="status">Settings saved. They apply when a sock next connects.</div>'
    return layout("Sensoria settings", f"""<main class="shell workspace"><div class="intro"><h1>Sensoria settings</h1></div>{notice}
<form class="panel" action="{ADMIN}" method="post">{hidden(csrf)}
<div class="panel-title"><h2>Recording profile</h2></div>
{"".join(rows)}<div class="actions"><span class="note">Applies the next time a sock connects.</span><button class="primary">Save settings</button></div>
</form></main>""", navigation(logout_token))


def navigation(logout_token, password_page=False):
    link = f'<a href="{ADMIN}">Settings</a>' if password_page else f'<a href="{ADMIN}/password">Change password</a>'
    return f"""<div class="nav">{link}<form action="{ADMIN}/logout" method="post">
{hidden(logout_token)}<button class="quiet">Sign out</button></form></div>"""


def change_password_page(csrf, logout_token, error=""):
    notice = f'<div class="notice error" role="alert">{html.escape(error)}</div>' if error else ""
    return layout("Change password", f"""<main class="shell"><section class="panel password-panel">
<h1>Change password</h1><p>Use at least 12 characters. You’ll sign in again after saving.</p>{notice}
<form method="post" action="{ADMIN}/password">{hidden(csrf)}
<label for="current">Current password<input id="current" name="current" type="password" required maxlength="256" autocomplete="current-password"></label>
<label for="new">New password<input id="new" name="new" type="password" required minlength="12" maxlength="256" autocomplete="new-password"></label>
<label for="confirm">Confirm new password<input id="confirm" name="confirm" type="password" required minlength="12" maxlength="256" autocomplete="new-password"></label>
<button class="primary">Save new password</button></form></section></main>""", navigation(logout_token, True))
