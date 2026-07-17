# machin-herald

> **Run a command. Email its output. On a schedule.**
> A scheduled report mailer as one static binary — no Node, no template engine, no scheduler.

```sh
$ machin-herald -c herald.json send --target hart-weekly
{"ok":true,"target":"hart-weekly","sent":true,"id":"899fdef1-...","to":["you@your-domain"],"bytes":2413}
```

`machin-herald` is a **pipe, not a framework**. Each target names a shell command; whatever
that command prints becomes the email body. It's built in
[machin](https://github.com/javimosch/machin) (MFL) and delivers through
[Resend](https://resend.com) with your own key.

---

## Two decisions that keep it small

**1. The source owns the rendering.** herald never templates anything. Your command prints
HTML (or text) and herald ships it. That means *anything* is a report source — a CLI that
already speaks JSON, a shell one-liner, a script you wrote in five minutes:

```jsonc
{ "command": "df -h",                     "format": "text" }   // disk report
{ "command": "hart admin digest --days 7 | my-renderer", "format": "html" }
{ "command": "/opt/reports/weekly.sh",    "format": "html" }
```

**2. There is no scheduler.** systemd timers and cron already do this correctly —
persistent, catch-up after downtime, logged, restartable. Reimplementing that inside the
app is how these tools bloat. herald is a one-shot `send`; you point a timer at it.

## Quickstart

```sh
./build.sh                       # needs `machin` on PATH  ->  ./machin-herald
cp herald.json.example herald.json && $EDITOR herald.json
export RESEND_API_KEY=re_...     # BYO key — never in the config file
./machin-herald -c herald.json send --dry-run   # preview: no email sent
./machin-herald -c herald.json send             # deliver every target
```

## Config

```json
{
  "from": "hart digest <digest@your-domain.tld>",
  "targets": [
    {
      "name": "hart-weekly",
      "to": ["you@your-domain.tld"],
      "subject": "hart — weekly digest",
      "command": "hart admin digest --days 7 | my-renderer",
      "format": "html"
    }
  ]
}
```

| field | meaning |
|---|---|
| `from` | sender — must be on a **Resend-verified domain** |
| `targets[].name` | id for `send --target <name>` |
| `targets[].to` | recipients (array) |
| `targets[].subject` | email subject |
| `targets[].command` | shell command; its **stdout is the body**. Non-zero exit = failure (nothing sent) |
| `targets[].format` | `html` (default) or `text` |

`RESEND_API_KEY` comes from the environment — the config file holds no secrets, so it's
safe to commit.

## Scheduling (systemd timer)

```ini
# /etc/systemd/system/herald-weekly.service
[Service]
Type=oneshot
EnvironmentFile=/etc/herald/herald.env      # RESEND_API_KEY=...
ExecStart=/usr/local/bin/machin-herald -c /etc/herald/herald.json send --target hart-weekly
```
```ini
# /etc/systemd/system/herald-weekly.timer
[Timer]
OnCalendar=Mon 08:00
Persistent=true
[Install]
WantedBy=timers.target
```
```sh
systemctl enable --now herald-weekly.timer
```
`Persistent=true` means a missed run (box was off) fires on the next boot. Daily, weekly,
monthly — it's all just `OnCalendar=`.

## Commands

| cmd | does |
|---|---|
| `send [--target <name>] [--dry-run]` | run the command(s), email the output. `--dry-run` previews (size, recipients) without sending |
| `list` | the configured targets (JSON) |
| `help` | usage (JSON) |

## Agent-first

JSON on stdout, structured errors on stderr, semantic exit codes — an agent can drive it
blind and parse the result:

```
0    ok
80-89   input (bad config, missing RESEND_API_KEY, unknown flag)
90-99   resource (no such target)
100-109 integration (command failed, Resend rejected/unreachable)
```

## Build

```sh
./build.sh          # machin encode + build -> ./machin-herald (one static binary)
```
Needs [machin](https://github.com/javimosch/machin) on PATH. No Node, no bundler, nothing
to install at runtime.

## Why it exists

I built [hart](https://github.com/javimosch/machin-hart) (an agent-first artifact host) and
wanted its weekly operator digest in my inbox. Every option was either a SaaS that wanted
my data, or a pile of cron + Python + an SMTP library. herald is the small, boring,
self-hosted alternative: a config file, a command, a key you own.

MIT.
