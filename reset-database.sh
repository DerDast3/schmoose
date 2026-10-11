#!/bin/sh
# reset-database.sh — wipe the Schmoose database and attachment store, then
# let the next boot re-run schema migrations + the seed (bootstrap admin).
# Typical use: a fresh start before re-running the Mattermost history
# import (see README, "Migrating history from Mattermost").
#
# DANGER: this deletes EVERYTHING — all accounts (including real users and
# their sessions), chats, messages, attachments, favorites, API keys.
# Users come back with the import (or their first OIDC login); the local
# bootstrap admin is re-created from ADMIN_PASSWORD in .env.
#
# Run it in the RUNTIME directory (next to docker-compose.yml), never in
# a repo clone. It refuses to do anything without --i-know-this-wipes-everything.
set -eu

if [ "${1:-}" != "--i-know-this-wipes-everything" ]; then
  echo "reset-database: this WIPES all accounts, chats, messages and attachment files."
  echo "Usage: sh reset-database.sh --i-know-this-wipes-everything"
  exit 1
fi

if [ -d .git ] || [ ! -f docker-compose.yml ]; then
  echo "reset-database: run this in the RUNTIME directory (next to docker-compose.yml)," >&2
  echo "not inside a repository clone." >&2
  exit 1
fi

for d in ./postgres ./attachments; do
  [ -d "$d" ] || { echo "reset-database: '$d' not found — wrong directory?" >&2; exit 1; }
done

echo "[reset] stopping the stack ..."
docker compose down

# postgres:17-alpine runs as uid 70 — the data dir is owned by it, so a
# non-root operator needs sudo here. Attachments may be deploy-user-owned
# (see README troubleshooting) — same story.
RM="rm"
if [ "$(id -u)" != "0" ] && command -v sudo >/dev/null 2>&1; then RM="sudo rm"; fi

echo "[reset] wiping ./postgres ..."
$RM -rf ./postgres
echo "[reset] wiping ./attachments ..."
$RM -rf ./attachments

echo "[reset] starting the stack (migrations + seed run at boot) ..."
docker compose up -d
sleep 5
docker compose logs server 2>&1 | grep -E "\[seed\]|\[migr\]" | tail -6 || true
echo "[reset] done — empty database, bootstrap admin re-created from ADMIN_PASSWORD."
