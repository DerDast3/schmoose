# Schmoose

**Schmoose** — *to schmooze: to chat, to talk* — a self-hosted group messenger
for small teams (up to ~500 members) in the spirit of Mattermost.

This repository contains the **deployment files** for running Schmoose on
your own server. The application itself is shipped as prebuilt container
images.

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
| `OIDC_CLAIM_SHORTNAME` | *(empty)* | Kürzel on avatar chips + people search; empty = initials invented from the display name |
| `OIDC_CLAIM_PHOTO` | `picture,photoUrl` | profile image (fetched for accounts without an own upload) |
| `OIDC_CLAIM_EMAIL` | `email,mail,upn` | account mapping key (must contain `@`) |
| `OIDC_CLAIM_USERNAME` | `preferred_username` | account name candidate for JIT provisioning |

The first claim of the chain present in the ID token wins. For the
DIaLOGIKa realm set `OIDC_CLAIM_USERNAME=Krzl,preferred_username` and
`OIDC_CLAIM_SHORTNAME=Krzl` — accounts are named and shown by the Kürzel
(`dast`), while the display name stays the full name (`Daniel Stephan`).
If a login fails with *OIDC token invalid* / *lacks an email claim*, the
server log lists the exact claim names the realm actually sent
(`[oidc] token claims present: …`) — set the chains accordingly.

**SSO accounts and profile management.** Accounts created via SSO have no
local password — the profile dialog hides password change and two-factor
setup (the APIs reject them), and optionally shows an external link when
`OIDC_ACCOUNT_URL` is set (e.g. the Keycloak account console). The IdP
profile photo is applied automatically as long as the user has not
uploaded an own avatar.

**Checklist when SSO fails:**

1. `OIDC_ISSUER` must match the token `iss` claim **verbatim** —
   including scheme, port and realm case (e.g.
   `https://winkc.dialogika.de:5443/realms/DIaLOGIKaSSO`). If unsure,
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
