#!/bin/sh

scalingo --region osc-secnum-fr1 --app demo-rdv-solidarites integration-link-manual-review-app `gh pr view --json number --jq '.number'` &&
gh pr edit -b "$(gh pr view --json body --jq '.body' | sed "1i\\
[Review app](https://demo-rdv-solidarites-pr`gh pr view --json number --jq '.number'`.osc-secnum-fr1.scalingo.io/)

")"