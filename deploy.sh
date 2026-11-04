#!/usr/bin/env bash
# First-time setup of the Omnigent server on Deploio.
#
# Usage: DEPLOIO_ORG=<org> ./deploy.sh
#
# Fetches credentials with nctl and generates the cookie secret. Secrets are
# never printed, and only the admin password is typed in (hidden prompt).
# Safe to re-run if it fails before the app exists; it stops if the app already
# exists, so that it cannot replace the secrets of a running server.
set -euo pipefail

: "${DEPLOIO_ORG:?Set DEPLOIO_ORG to your Deploio organization}"
PROJECT="${PROJECT:-$DEPLOIO_ORG-omnigent}"
NAME="${NAME:-omnigent}"
BUCKET="${BUCKET:-$NAME}"
LOCATION="${LOCATION:-nine-es34}"
S3_ENDPOINT="${S3_ENDPOINT:-https://${LOCATION#nine-}.objects.nineapis.ch}"

ensure() { # ensure <kind> <name> [create flags...]
  local kind=$1 name=$2
  shift 2
  if nctl get "$kind" "$name" -p "$PROJECT" >/dev/null 2>&1; then
    echo "$kind/$name already exists"
  else
    nctl create "$kind" "$name" -p "$PROJECT" --wait "$@"
  fi
}

nctl auth whoami >/dev/null # stop early if not logged in

if ! nctl get projects "$PROJECT" >/dev/null 2>&1; then
  nctl create project "$PROJECT" --wait
fi

if nctl get application "$NAME" -p "$PROJECT" >/dev/null 2>&1; then
  echo "App $NAME already exists in $PROJECT. Stopping so its secrets stay unchanged." >&2
  exit 1
fi

ensure postgresdatabase "$NAME" --location="$LOCATION"
ensure bucketuser "$NAME" --location="$LOCATION"
ensure bucket "$BUCKET" --location="$LOCATION" --permissions="writer=$NAME"

DATABASE_URL=$(nctl get postgresdatabase "$NAME" -p "$PROJECT" --print-connection-string)
case "$DATABASE_URL" in
  *sslmode=*) ;;
  *\?*) DATABASE_URL="$DATABASE_URL&sslmode=require" ;;
  *) DATABASE_URL="$DATABASE_URL?sslmode=require" ;;
esac
AWS_ACCESS_KEY_ID=$(nctl get bucketuser "$NAME" -p "$PROJECT" --print-access-key)
AWS_SECRET_ACCESS_KEY=$(nctl get bucketuser "$NAME" -p "$PROJECT" --print-secret-key)
COOKIE_SECRET=$(openssl rand -hex 32)

read -rsp "Admin password for Omnigent: " ADMIN_PASSWORD
echo
[ -n "$ADMIN_PASSWORD" ] || { echo "The admin password must not be empty." >&2; exit 1; }

# nctl splits env values on ';', which would silently corrupt a secret.
for value in "$DATABASE_URL" "$AWS_ACCESS_KEY_ID" "$AWS_SECRET_ACCESS_KEY" "$ADMIN_PASSWORD"; do
  case "$value" in
    *\;*) echo "A secret contains ';', which nctl cannot pass. Nothing was created for the app." >&2; exit 1 ;;
  esac
done

nctl create application "$NAME" -p "$PROJECT" \
  --git-url=https://github.com/rnestler/omnigent-deploio.git \
  --dockerfile --port=8000 --size=mini --replicas=1 \
  --env="OMNIGENT_AUTH_ENABLED=1" \
  --env="OMNIGENT_ARTIFACT_URI=s3://$BUCKET/omnigent" \
  --env="AWS_DEFAULT_REGION=us-east-1" \
  --env="AWS_ENDPOINT_URL=$S3_ENDPOINT" \
  --sensitive-env="DATABASE_URL=$DATABASE_URL" \
  --sensitive-env="OMNIGENT_ACCOUNTS_COOKIE_SECRET=$COOKIE_SECRET" \
  --sensitive-env="OMNIGENT_ACCOUNTS_INIT_ADMIN_PASSWORD=$ADMIN_PASSWORD" \
  --sensitive-env="AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID" \
  --sensitive-env="AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY"

# Deploio generates the default host when the app is created, so the base URL
# can only be set afterwards.
nctl get application "$NAME" -p "$PROJECT"
read -rp "App host from HOSTS above, without https:// (if empty, re-check with nctl get app): " APP_HOST
[ -n "$APP_HOST" ] || { echo "No host given. Set OMNIGENT_ACCOUNTS_BASE_URL yourself." >&2; exit 1; }

nctl update application "$NAME" -p "$PROJECT" --env="OMNIGENT_ACCOUNTS_BASE_URL=https://$APP_HOST"
nctl update application "$NAME" -p "$PROJECT" --retry-release

echo "Done. Follow startup with: nctl logs app $NAME -p $PROJECT -f"
