#!/usr/bin/env bash
set -euo pipefail

# --- CONFIG ---
REGION="osc-secnum-fr1"
PROD_APP="production-rdv-mairie"

# --- FUNCTIONS ---
log() {
  echo -e "\033[1;34m[INFO]\033[0m $*"
}

# --- MAIN ---

log "Fetching PR number..."
PR_NUMBER=$(gh pr view --json number --jq '.number')
if [[ -z "$PR_NUMBER" ]]; then
  echo "Error: Unable to get PR number."
  exit 1
fi

APP_NAME="rdv-service-public-review-app-pr${PR_NUMBER}"
log "Review app name: ${APP_NAME}"

log "Fetching SMTP env vars from production app..."
SMTP_VARS=$(scalingo --region "$REGION" --app "$PROD_APP" env | grep '^SMTP')
if [[ -z "$SMTP_VARS" ]]; then
  echo "No SMTP variables found in production app."
  exit 1
fi

# Extract only variable names (keys)
SMTP_KEYS=$(echo "$SMTP_VARS" | cut -d '=' -f 1)

log "Found SMTP variables:"
echo "$SMTP_KEYS" | sed 's/^/  - /'

log "Setting SMTP variables on review app..."
# shellcheck disable=SC2086
scalingo --region "$REGION" --app "$APP_NAME" env-set $SMTP_VARS

log "Unsetting DISABLE_SENDING_EMAILS..."
scalingo --region "$REGION" --app "$APP_NAME" env-unset DISABLE_SENDING_EMAILS || true

log "Scaling up jobs process to 1..."
scalingo --region "$REGION" --app "$APP_NAME" scale jobs:1 || true

log "Restart web processes..."
scalingo --region "$REGION" --app "$APP_NAME" restart web

log "✅ Review app ${APP_NAME} configured successfully."

