#!/usr/bin/env bash
set -euo pipefail

REGION="osc-secnum-fr1"

log() {
  echo -e "\033[1;34m[INFO]\033[0m $*"
}

log "Fetching PR number..."
PR_NUMBER=$(gh pr view --json number --jq '.number')
if [[ -z "$PR_NUMBER" ]]; then
  echo "Error: Unable to get PR number."
  exit 1
fi

APP_NAME="rdv-service-public-review-app-pr${PR_NUMBER}"
log "Review app name: ${APP_NAME}"

log "Setting DISPLAY_LOGIN_CODES=true on review app..."
scalingo --region "$REGION" --app "$APP_NAME" env-set DISPLAY_LOGIN_CODES=true

log "Restarting web processes..."
scalingo --region "$REGION" --app "$APP_NAME" restart web

log "✅ Login code display enabled on ${APP_NAME}."
