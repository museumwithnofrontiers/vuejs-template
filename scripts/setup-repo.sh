#!/usr/bin/env bash
# Finishes the repository setup that "Use this template" and the built-in
# GITHUB_TOKEN cannot do themselves (see .github/workflows/bootstrap.yml for
# why: repository administration is not a permission GITHUB_TOKEN can ever
# hold, confirmed empirically). Run this once, as yourself, after using the
# template:
#
#   ./scripts/setup-repo.sh
#
# Requires the GitHub CLI (gh), already logged in as a user with admin
# rights on this repository: gh auth login
#
# This script never sees or stores a token of its own -- every command
# below runs as YOU, through your own `gh auth` session. Safe to re-run: it
# checks the current state before changing anything and only ever tells you
# what it did or already found in place.
set -euo pipefail

REPO=$(gh repo view --json nameWithOwner --jq .nameWithOwner)
echo "Setting up $REPO ..."
echo

if ! gh api "repos/$REPO/pages" >/dev/null 2>&1; then
  gh api -X POST "repos/$REPO/pages" -f build_type=workflow >/dev/null
  echo "[Pages]        enabled (build_type=workflow)."
else
  echo "[Pages]        already enabled -- nothing to do."
fi

if [ -z "$(gh api "repos/$REPO/rulesets" --jq '.[] | select(.name=="main-requires-pr") | .id')" ]; then
  gh api -X POST "repos/$REPO/rulesets" --input - >/dev/null <<'JSON'
{
  "name": "main-requires-pr",
  "target": "branch",
  "enforcement": "active",
  "conditions": { "ref_name": { "include": ["~DEFAULT_BRANCH"], "exclude": [] } },
  "rules": [
    { "type": "deletion" },
    { "type": "non_fast_forward" },
    {
      "type": "pull_request",
      "parameters": {
        "required_approving_review_count": 0,
        "dismiss_stale_reviews_on_push": false,
        "required_reviewers": [],
        "require_code_owner_review": false,
        "dismissal_restriction": { "enabled": false, "allowed_actors": [] },
        "require_last_push_approval": false,
        "required_review_thread_resolution": false,
        "require_extra_approval_for_unattributed_changes": false,
        "allowed_merge_methods": ["merge", "squash", "rebase"]
      }
    },
    {
      "type": "required_status_checks",
      "parameters": {
        "strict_required_status_checks_policy": false,
        "required_status_checks": [ { "context": "CodeQL", "integration_id": 57789 } ]
      }
    }
  ]
}
JSON
  echo "[Ruleset]      created: PR required, no review required, CodeQL required, force-push/deletion blocked."
else
  echo "[Ruleset]      already exists -- nothing to do."
fi

current=$(gh api "repos/$REPO" --jq '"\(.allow_auto_merge) \(.delete_branch_on_merge)"')
if [ "$current" != "true true" ]; then
  gh api -X PATCH "repos/$REPO" -f allow_auto_merge=true -F delete_branch_on_merge=true >/dev/null
  echo "[Repo settings] allow_auto_merge and delete_branch_on_merge enabled."
else
  echo "[Repo settings] already enabled -- nothing to do."
fi

if gh api "repos/$REPO/automated-security-fixes" --jq '.enabled' 2>/dev/null | grep -q true; then
  echo "[Dependabot]   security updates already enabled -- nothing to do."
else
  gh api -X PUT "repos/$REPO/automated-security-fixes" >/dev/null
  echo "[Dependabot]   security updates enabled."
fi

has_js=$(gh api "repos/$REPO/code-scanning/default-setup" --jq '.languages | index("javascript-typescript") != null' 2>/dev/null || echo false)
if [ "$has_js" = "true" ]; then
  echo "[CodeQL]       already scans javascript-typescript -- nothing to do."
else
  gh api -X PATCH "repos/$REPO/code-scanning/default-setup" \
    -f state=configured -f query_suite=extended \
    -F 'languages[]=actions' -F 'languages[]=javascript-typescript' >/dev/null
  echo "[CodeQL]       extended to scan javascript-typescript too (takes about a minute to take effect)."
fi

# Last step, on purpose -- and not a rubber stamp. set -e aborts on the
# first real failure above, but a step could still have silently no-opped
# against a state that was misread, so before promising anything we re-read
# all six settings fresh and check them for real. GitHub's API can also
# legitimately still be catching up with a change this very script just made
# a moment ago (CodeQL's language list, extended above, is the one this
# repeatedly shows up on) -- that isn't a failure, so the check below keeps
# re-reading for a while before it gives up, rather than condemning a run
# that actually did everything right. The "Verify repository settings"
# workflow (.github/workflows/bootstrap.yml) cannot read allow_auto_merge,
# delete_branch_on_merge, Dependabot's security-fixes setting, or CodeQL's
# language list under GITHUB_TOKEN -- three of those reads 403 outright, and
# the other two fields are silently omitted from the API response for a
# non-admin reader even when true. This marker stands in for all three so
# that workflow can tell "verified done" from "never run" -- so it must only
# be written when every assertion below actually passes.

check_final_settings() {
  # Re-reads all six settings fresh and (re-)populates the global
  # "failures" array with what's still wrong (empty if everything checks
  # out). Safe, cheap, and idempotent to call repeatedly -- that's the
  # point.
  failures=()

  if ! gh api "repos/$REPO/pages" >/dev/null 2>&1; then
    failures+=("Pages is not enabled.")
  fi

  if [ -z "$(gh api "repos/$REPO/rulesets" --jq '.[] | select(.name=="main-requires-pr") | .id')" ]; then
    failures+=("Ruleset 'main-requires-pr' is missing.")
  fi

  current=$(gh api "repos/$REPO" --jq '"\(.allow_auto_merge) \(.delete_branch_on_merge)"')
  if [ "$current" != "true true" ]; then
    failures+=("allow_auto_merge and/or delete_branch_on_merge is not enabled.")
  fi

  if ! gh api "repos/$REPO/automated-security-fixes" --jq '.enabled' 2>/dev/null | grep -q true; then
    failures+=("Dependabot security updates are not enabled.")
  fi

  has_js_final=$(gh api "repos/$REPO/code-scanning/default-setup" --jq '.languages | index("javascript-typescript") != null' 2>/dev/null || echo false)
  if [ "$has_js_final" != "true" ]; then
    failures+=("CodeQL default setup does not include javascript-typescript.")
  fi
}

echo
echo "Verifying final state before marking setup complete ..."

# Give GitHub's side a chance to catch up rather than failing a run that
# actually did everything right; a setting that is genuinely missing will
# still be missing once this runs out, and gets reported below exactly as
# before.
deadline=$(( $(date -u +%s) + 90 ))
poll_interval_seconds=5
check_final_settings
wait_message_shown=false
while [ "${#failures[@]}" -gt 0 ] && [ "$(date -u +%s)" -lt "$deadline" ]; do
  if [ "$wait_message_shown" = false ]; then
    echo "Some settings (most often CodeQL's language list) can take a little while to catch up on GitHub's side after being set -- waiting and checking again, this is normal ..."
    wait_message_shown=true
  fi
  sleep "$poll_interval_seconds"
  check_final_settings
done

if [ "${#failures[@]}" -gt 0 ]; then
  echo
  echo "ERROR: setup is not actually complete -- refusing to set the completion marker:"
  for f in "${failures[@]}"; do
    echo "  - $f"
  done
  echo
  echo "Re-run this script after checking the messages above."
  exit 1
fi

gh variable set VUEJS_TEMPLATE_SETUP_COMPLETE --body "$(date -u +%Y-%m-%dT%H:%M:%SZ)" >/dev/null
echo "[Marker]       VUEJS_TEMPLATE_SETUP_COMPLETE repository variable set."

echo
echo "Done. If your repository is private, note that CodeQL only runs on"
echo "public repositories on this organization's GitHub Free plan -- make it"
echo "public (Settings > General > Danger Zone) or pull requests can never"
echo "satisfy the required check."
