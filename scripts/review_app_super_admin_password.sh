#!/bin/bash

if (( $# == 0 )); then
  echo "Display the HTTP Basic password to access the super_admin section of a review app."
  echo "Usage: $0 <pr-number>"; exit
fi

REVIEW_APP=demo-rdv-solidarites-pr"$1"
REGION=osc-secnum-fr1
PASSWORD=$(scalingo env --region $REGION --app "$REVIEW_APP" | grep ADMIN_BASIC_AUTH_PASSWORD | sed 's/.*=//')
USERNAME=rdv-solidarites
URL=https://$USERNAME:$PASSWORD@$REVIEW_APP.$REGION.scalingo.io/super_admins

echo $URL
