# Finishes the repository setup that "Use this template" and the built-in
# GITHUB_TOKEN cannot do themselves (see .github/workflows/bootstrap.yml for
# why: repository administration is not a permission GITHUB_TOKEN can ever
# hold, confirmed empirically). Run this once, as yourself, after using the
# template:
#
#   ./scripts/setup-repo.ps1
#
# Requires the GitHub CLI (gh), already logged in as a user with admin
# rights on this repository: gh auth login
#
# This script never sees or stores a token of its own -- every command below
# runs as YOU, through your own `gh auth` session. Safe to re-run: it checks
# the current state before changing anything and only ever tells you what it
# did or already found in place.

$ErrorActionPreference = "Stop"

$Repo = gh repo view --json nameWithOwner --jq .nameWithOwner
Write-Host "Setting up $Repo ..."
Write-Host ""

try { gh api "repos/$Repo/pages" *>$null; $pagesExists = $true } catch { $pagesExists = $false }
if (-not $pagesExists) {
    gh api -X POST "repos/$Repo/pages" -f build_type=workflow *>$null
    Write-Host "[Pages]        enabled (build_type=workflow)."
} else {
    Write-Host "[Pages]        already enabled -- nothing to do."
}

$rulesets = gh api "repos/$Repo/rulesets" | ConvertFrom-Json
$existingRuleset = $rulesets | Where-Object { $_.name -eq "main-requires-pr" }
if (-not $existingRuleset) {
    $rulesetJson = @'
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
'@
    # Piping into `gh api --input -` over stdin is unreliable from PowerShell;
    # write to a temp file and pass that instead.
    $rulesetFile = New-TemporaryFile
    Set-Content -Path $rulesetFile -Value $rulesetJson -NoNewline
    gh api -X POST "repos/$Repo/rulesets" --input $rulesetFile *>$null
    Remove-Item $rulesetFile -ErrorAction SilentlyContinue
    Write-Host "[Ruleset]      created: PR required, no review required, CodeQL required, force-push/deletion blocked."
} else {
    Write-Host "[Ruleset]      already exists -- nothing to do."
}

$repoInfo = gh api "repos/$Repo" | ConvertFrom-Json
if (-not ($repoInfo.allow_auto_merge -and $repoInfo.delete_branch_on_merge)) {
    gh api -X PATCH "repos/$Repo" -f allow_auto_merge=true -F delete_branch_on_merge=true *>$null
    Write-Host "[Repo settings] allow_auto_merge and delete_branch_on_merge enabled."
} else {
    Write-Host "[Repo settings] already enabled -- nothing to do."
}

try {
    $secFixes = gh api "repos/$Repo/automated-security-fixes" | ConvertFrom-Json
} catch {
    $secFixes = $null
}
if ($secFixes -and $secFixes.enabled) {
    Write-Host "[Dependabot]   security updates already enabled -- nothing to do."
} else {
    gh api -X PUT "repos/$Repo/automated-security-fixes" *>$null
    Write-Host "[Dependabot]   security updates enabled."
}

$defaultSetup = gh api "repos/$Repo/code-scanning/default-setup" | ConvertFrom-Json
if ($defaultSetup.languages -contains "javascript-typescript") {
    Write-Host "[CodeQL]       already scans javascript-typescript -- nothing to do."
} else {
    gh api -X PATCH "repos/$Repo/code-scanning/default-setup" -f state=configured -f query_suite=extended -F 'languages[]=actions' -F 'languages[]=javascript-typescript' *>$null
    Write-Host "[CodeQL]       extended to scan javascript-typescript too (takes about a minute to take effect)."
}

Write-Host ""
Write-Host "Done. If your repository is private, note that CodeQL only runs on"
Write-Host "public repositories on this organization's GitHub Free plan -- make it"
Write-Host "public (Settings > General > Danger Zone) or pull requests can never"
Write-Host "satisfy the required check."
