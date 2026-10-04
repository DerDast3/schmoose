# Schmoose

**Schmoose** — *to schmooze: to chat, to talk* — a self-hosted group messenger
for small teams (up to ~500 members) in the spirit of Mattermost.

Schmoose is for teams that want their chat **on their own metal** — no
subscription, no telemetry, no lock-in. Messages live in your Postgres,
attachments in your filesystem, logins come from your identity provider.
Your colleagues sign in with the company single sign-on, your phone turns
into a chat device with one QR scan, and the newest message is always —
always — at the bottom.

This repository contains the **deployment files** for running Schmoose on
your own server. The application itself is shipped as prebuilt container
images.

## What you get

- **Real-time everything** — WebSocket live updates, typing indicators,
  presence dots, unread badges, favorites with drag & drop.
- **@Mentions** — type `@`, pick a colleague (search by Kürzel *or* full
  name). Mention someone in a public chat and they join it; their own name
  glows only for them.
- **Reactions** — 👍 ❌ 🅰️ at a click, any emoji via the picker; counters
  count up and down live for everyone in the room.
- **Markdown, rendered server-side** — the same HTML for every reader,
  `:tada:` shortcodes, syntax-highlighted code blocks with a copy button,
  and ten color themes to argue about.
- **Files** — drag & drop attachments, magic-byte type validation, image
  previews, stable numbering (links survive edits).
- **Group life** — public channels with self-join, private groups with
  owner roles, invites, renames, and a real (confirmed) delete.
- **Installable PWA** — Android, iOS and desktop; safe-area aware, with
  its own session storage.
- **QR device pairing** — scan, approve, done: your phone signs in with a
  single tap from then on (see below).
- **Identity done properly** — OIDC single sign-on with claim-mapping
  chains for corporate realms, JIT provisioning, IdP profile photos, and
  optional local accounts with TOTP two-factor + recovery codes.

## What runs

| Service | Image | Source | Exposure |
|---|---|---|---|
| Web (nginx, TLS, static chat UI, API/WS proxy) | `ghcr.io/derdast3/messenger-web` | this registry | **443** (public) |
| Backend (Fastify API, WebSocket hub) | `ghcr.io/derdast3/messenger-server` | this registry | loopback only |
| Database | `postgres:17-alpine` | Docker Hub | loopback only |

The images are distributed privately — pulling them requires a
`ghcr.io` login with a `read:packages` token (issued individually).

Authentication is provided via **OIDC single sign-on** (Keycloak or any
compliant provider); accounts are created automatically on first login from
the identity provider's email claim.

## Requirements

- Ubuntu server (or any host) with **Docker + Compose plugin**
- A public hostname with DNS pointing to the server (a wildcard
  `*.schmoose.ms` certificate covers every sub-hostname)
- TLS certificate files in PEM format (`fullchain.pem` + `privkey.pem`)
- A `ghcr.io` login (read access) for pulling the images
- An OIDC provider (e.g. Keycloak) — see *Single sign-on* below

## Quick start

```sh
# 1. Layout
mkdir -p /srv/schmoose/nginx/templates /srv/schmoose/certs
cd /srv/schmoose

# 2. Get the deployment files (this repository)
git clone https://github.com/DerDast3/schmoose.git repo
cp repo/docker-compose.yml .
cp repo/nginx/messenger.conf.template nginx/templates/
cp repo/.env.sample .env

# 3. Certificates (PEM)
cp /path/to/fullchain.pem certs/fullchain.pem
cp /path/to/privkey.pem   certs/privkey.pem
chmod 600 certs/privkey.pem

# 4. Configure — fill in every value, see the comments in the file
$EDITOR .env

# 5. Pull the images and start
docker login ghcr.io -u <username>       # read:packages token
docker compose pull && docker compose up -d

# 6. Verify
curl -s https://<PUBLIC_HOST>/api/health
docker compose logs server | grep -E "migrate|seed"
```

The database starts empty: the server creates the complete schema on first
boot and records the version in `schema_migrations`. A seed admin account is
created on first boot (its password is printed to the server log — change it
after login).

**Note on the layout:** the repository clone under `repo/` is only the source
of the deployment files. Run everything from `/srv/schmoose` — that directory
holds the compose file, `.env`, the nginx template, certificates and all
persistent state (`postgres/`, `attachments/`). Never start the stack inside
`repo/`, or the bind mounts would write into the clone.

## Schema migrations (automatic)

Later image updates ship their SQL files with them. On boot the server
applies **only the missing versions** (1→2→3→…), recorded in the
`schema_migrations` table — downgrades are ignored. Current state:

```sh
docker compose exec postgres psql -U messenger -d messenger \
  -c "SELECT max(id) FROM schema_migrations;"              # database version
docker compose exec server ls /app/dist/db/migrations     # versions in the image
```

## User management — three ways

Schmoose does not lock you into one identity story. Pick what fits:

**1. Your own OIDC provider (Keycloak or any compliant IdP).** The full
SSO experience: your accounts live where your other services live, JIT
provisioning creates them on first login. Configure the `OIDC_*` block in
`.env` — details in the *Single sign-on* section below.

**2. The built-in IDP — no Keycloak needed.** A lightweight OIDC provider
is included, backed by a single JSON file:

```sh
cp userdata.example.json userdata.json     # then edit: users + initial passwords
chmod 600 userdata.json
$EDITOR .env                               # uncomment the OIDC_* block pointing
                                           # at https://<PUBLIC_HOST>/realms/myrealm
docker login ghcr.io -u <username>
docker compose --profile idp up -d
```

- **Adding/removing users = editing the file.** `userdata.json` is
  re-read on every login — no restart, no admin UI.
- Initial passwords sit in **cleartext** in the file and are hashed
  (scrypt) automatically on each user's **first successful login**.
  Treat the file like a password list: `chmod 600`, never commit it.
- The optional per-user `claims` dict replaces the default token claims
  entirely (handy for display name, short name or a profile photo).
- The login screen shows *Sign in with SSO*; accounts are created on
  first login from the file.

**3. Local accounts only.** Set `OIDC_ENABLED=false` and skip the OIDC
block — users log in with username/email + password, and (optional,
per-account) TOTP two-factor with recovery codes. The seed admin starts
you off; profiles are managed in the app.

All three ways mix freely with the **QR device pairing** for phones —
see below.

## Single sign-on (OIDC)

Point the `OIDC_*` variables in `.env` at your provider (Keycloak works out
of the box):

| Keycloak client setting | Value |
|---|---|
| Client type | **public** (no client secret) |
| Standard flow | enabled |
| PKCE | S256 (always sent by Schmoose) |
| Valid redirect URIs | `https://<PUBLIC_HOST>/api/auth/oidc/callback` |
| Signing | RS256, keys public via JWKS |
| Token claims | `email` (required — the account mapping key), `preferred_username` |

**Claim mapping for corporate realms.** Keycloak instances that front an
Active Directory often emit non-standard claim names. Schmoose resolves
every identity value through configurable fallback chains in `.env`:

| Variable | Default | Meaning |
|---|---|---|
| `OIDC_CLAIM_DISPLAYNAME` | `name` | full name shown in chats |
| `OIDC_CLAIM_SHORTNAME` | *(empty)* | short name (Kürzel) on avatar chips + people search; empty = initials invented from the display name |
| `OIDC_CLAIM_PHOTO` | `picture,photoUrl` | profile image (fetched for accounts without an own upload) |
| `OIDC_CLAIM_EMAIL` | `email,mail,upn` | account mapping key (must contain `@`) |
| `OIDC_CLAIM_USERNAME` | `preferred_username` | account name candidate for JIT provisioning |

The first claim of the chain present in the ID token wins. If your realm
uses a custom short-name claim, list it FIRST in the username chain —
accounts are then named and shown by the short name, while the display
name stays the full name. If a login fails with *OIDC token invalid* /
*lacks an email claim*, the server log lists the exact claim names the
realm actually sent (`[oidc] token claims present: …`) — set the chains
accordingly.

**SSO accounts and profile management.** Accounts created via SSO have no
local password — the profile dialog hides password change and two-factor
setup (the APIs reject them), and optionally shows an external link when
`OIDC_ACCOUNT_URL` is set (e.g. the Keycloak account console). The IdP
profile photo is applied automatically as long as the user has not
uploaded an own avatar.

**Checklist when SSO fails:**

1. `OIDC_ISSUER` must match the token `iss` claim **verbatim** —
   including scheme, port and realm case (e.g.
   `https://idp.example.com:8443/realms/MyRealm`). If unsure,
   copy the `issuer` field from
   `https://<keycloak>/realms/<realm>/.well-known/openid-configuration`.
2. The **server container** needs outbound access to the `OIDC_JWKS_URL`
   (non-standard ports can be filtered):
   ```sh
   docker compose exec server node -e \
     "fetch(process.env.OIDC_JWKS_URL).then(r=>console.log('JWKS:',r.status))"
   # expected: JWKS: 200
   ```
3. Clock sync (`timedatectl`) — tokens are only valid for minutes.
4. `docker compose logs server | grep '\[oidc\]'` shows the diagnosis.

Accounts are created automatically on first SSO login (JIT) with the
provider's email as their identity; such accounts have no local password and
sign in via SSO only.

## Firewall

Only port 443 is public. Host-level protection (fail2ban, iptables,
provider firewalls) is the operator's responsibility and intentionally
not part of these files.

## Troubleshooting

- `docker compose logs server | grep -iE "error|seed|migrate"` — application log
- `docker compose ps` + `docker compose exec postgres pg_isready -U messenger` — stack state
- Deployment problems: report to the maintainer.

## Install as a mobile app (PWA)

On phones/tablets the login page offers installation: Android/Chrome shows
a real install dialog, iOS/Safari explains *Share ▸ Add to Home Screen*.
**Install before signing in** — the installed app has its own session
storage, so a login done in the regular browser does not carry over.

The installed app is also where the QR scanner lives — next step below.

## Connecting your phone — QR device pairing, step by step

For everyone doing this the first time — no technical knowledge needed.
You need your computer and your phone, and about two minutes:

1. **On your computer:** open your Schmoose website in the browser and
   sign in as usual.
2. **On your computer:** open the profile menu (top right ▸ *Profile &
   security*) and find **Devices ▸ Add device**. A QR code appears —
   leave this window open.
3. **On your phone:** open the Schmoose website **in the phone browser**
   and tap **Install app** (Android) or follow the *Add to Home Screen*
   hint (iOS). This installs Schmoose as an app — you only do this once.
4. **On your phone:** open the installed Schmoose app, and on the login
   screen tap **Sign in with QR**. Allow camera access when asked, then
   point the camera at the QR code on your computer's screen.
5. **On your computer:** a prompt appears — *"…wants to sign in to your
   account"* — approve it. Your phone logs in by itself.
6. **Forever after:** the phone's login screen shows **Sign in with this
   device** — highlighted for you — and one tap signs you in. **Never
   scan the QR again**; the pairing stays until you remove the device in
   the profile (or the sliding 42-day-unused window quietly expires it).

**Why it is safe — the short version:**

- **A photographed QR is worthless on its own.** Pairing only completes
  when someone approves it *on the desktop that showed the code*. A
  shoulder-surfer who photographs the screen gets a pending request and
  nothing else.
- The QR carries only the origin, a server-generated device ID and an
  ephemeral ECDH public key. The pairing secret reaches the phone **only
  in wrapped form** (ECDH + HKDF + AES-256-GCM) and never travels in the
  clear; the server keeps it like session material. The device ID travels
  in the URL **fragment** (`#d=…`) — browsers never send that part to any
  server, so it stays out of logs.
- On the phone the pairing lives as a **non-extractable HMAC key** in the
  browser's IndexedDB: page JavaScript can *use* it to answer a login
  challenge, but can never read it — an XSS bug finds nothing to steal.
- Device logins are ordinary sessions: a password change, a logout-everywhere
  or a device revoke ends them like any other session.

---

Schmoose is built to be boring to operate: one compose file, three
containers (four with the built-in IDP), automatic schema migrations,
images pulled from ghcr. Pull, restart, done — now go schmooze.
