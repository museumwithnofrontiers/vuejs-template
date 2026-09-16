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

# `gh` is a native command, not a PowerShell cmdlet. When a native command
# fails, PowerShell does NOT raise a terminating error for it -- try/catch
# will not see it, and neither $ErrorActionPreference = "Stop" nor
# $PSNativeCommandUseErrorActionPreference (which would fix this, but only
# exists from PowerShell 7.3 onward -- and this script must also work on the
# "Windows PowerShell" 5.1 the README tells people to use) changes that. The
# only reliable signal is $LASTEXITCODE, checked right after the call. Every
# `gh` invocation below goes through one of the two helpers so that check
# never gets forgotten.

function Invoke-GhCheck {
    # Runs `gh` and reports success/output without aborting the script --
    # for read-only probes where a non-zero exit (e.g. 404 "not found yet")
    # is an expected, normal result, not a failure.
    param([Parameter(Mandatory)][string[]]$GhArgs)
    $raw = & gh @GhArgs 2>&1
    $exitCode = $LASTEXITCODE
    [PSCustomObject]@{
        Success  = ($exitCode -eq 0)
        ExitCode = $exitCode
        Output   = ($raw | Out-String)
    }
}

function Invoke-GhRequired {
    # Runs `gh` and aborts the script with a clear, actionable message if it
    # fails -- for calls that must succeed for the setup to mean anything.
    param([Parameter(Mandatory)][string[]]$GhArgs)
    $result = Invoke-GhCheck $GhArgs
    if (-not $result.Success) {
        Write-Host ""
        Write-Host "ERROR: 'gh $($GhArgs -join ' ')' failed (exit code $($result.ExitCode)):" -ForegroundColor Red
        Write-Host $result.Output
        Write-Host ""
        Write-Host "Fix the problem above (often: run 'gh auth login' again, or you don't have admin rights on this repo) and re-run this script."
        exit 1
    }
    return $result.Output
}

$Repo = (Invoke-GhRequired @('repo', 'view', '--json', 'nameWithOwner', '--jq', '.nameWithOwner')).Trim()
Write-Host "Setting up $Repo ..."
Write-Host ""

$pagesCheck = Invoke-GhCheck @('api', "repos/$Repo/pages")
if (-not $pagesCheck.Success) {
    Invoke-GhRequired @('api', '-X', 'POST', "repos/$Repo/pages", '-f', 'build_type=workflow') | Out-Null
    Write-Host "[Pages]        enabled (build_type=workflow)."
} else {
    Write-Host "[Pages]        already enabled -- nothing to do."
}

$rulesetsCheck = Invoke-GhCheck @('api', "repos/$Repo/rulesets")
if (-not $rulesetsCheck.Success) {
    # Degrade the same way the "not found yet" case does (attempt to create
    # it), but say so honestly instead of pretending the read never happened.
    Write-Host "[Ruleset]      could not read existing rulesets (gh exited $($rulesetsCheck.ExitCode)) -- assuming none exist yet."
    $existingRuleset = $null
} else {
    $rulesets = $rulesetsCheck.Output | ConvertFrom-Json
    $existingRuleset = $rulesets | Where-Object { $_.name -eq "main-requires-pr" }
}
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
    Invoke-GhRequired @('api', '-X', 'POST', "repos/$Repo/rulesets", '--input', $rulesetFile) | Out-Null
    Remove-Item $rulesetFile -ErrorAction SilentlyContinue
    Write-Host "[Ruleset]      created: PR required, no review required, CodeQL required, force-push/deletion blocked."
} else {
    Write-Host "[Ruleset]      already exists -- nothing to do."
}

$repoInfoCheck = Invoke-GhCheck @('api', "repos/$Repo")
if (-not $repoInfoCheck.Success) {
    Write-Host "[Repo settings] could not read current settings (gh exited $($repoInfoCheck.ExitCode)) -- will attempt to set them anyway."
    $repoInfo = $null
} else {
    $repoInfo = $repoInfoCheck.Output | ConvertFrom-Json
}
if (-not ($repoInfo -and $repoInfo.allow_auto_merge -and $repoInfo.delete_branch_on_merge)) {
    Invoke-GhRequired @('api', '-X', 'PATCH', "repos/$Repo", '-f', 'allow_auto_merge=true', '-F', 'delete_branch_on_merge=true') | Out-Null
    Write-Host "[Repo settings] allow_auto_merge and delete_branch_on_merge enabled."
} else {
    Write-Host "[Repo settings] already enabled -- nothing to do."
}

$secFixesCheck = Invoke-GhCheck @('api', "repos/$Repo/automated-security-fixes")
if (-not $secFixesCheck.Success) {
    Write-Host "[Dependabot]   could not read current status (gh exited $($secFixesCheck.ExitCode)) -- assuming disabled."
    $secFixes = $null
} else {
    $secFixes = $secFixesCheck.Output | ConvertFrom-Json
}
if ($secFixes -and $secFixes.enabled) {
    Write-Host "[Dependabot]   security updates already enabled -- nothing to do."
} else {
    Invoke-GhRequired @('api', '-X', 'PUT', "repos/$Repo/automated-security-fixes") | Out-Null
    Write-Host "[Dependabot]   security updates enabled."
}

$defaultSetup = Invoke-GhRequired @('api', "repos/$Repo/code-scanning/default-setup") | ConvertFrom-Json
if ($defaultSetup.languages -contains "javascript-typescript") {
    Write-Host "[CodeQL]       already scans javascript-typescript -- nothing to do."
} else {
    Invoke-GhRequired @('api', '-X', 'PATCH', "repos/$Repo/code-scanning/default-setup", '-f', 'state=configured', '-f', 'query_suite=extended', '-F', 'languages[]=actions', '-F', 'languages[]=javascript-typescript') | Out-Null
    Write-Host "[CodeQL]       extended to scan javascript-typescript too (takes about a minute to take effect)."
}

# Last step, on purpose -- and not a rubber stamp. The steps above can fail
# partway (a real gh error now aborts immediately, per the helpers above,
# but a step could also have silently no-opped against a state we
# misread), so before promising anything we re-read all six settings fresh
# and check them for real. The "Verify repository settings" workflow
# (.github/workflows/bootstrap.yml) cannot read allow_auto_merge,
# delete_branch_on_merge, Dependabot's security-fixes setting, or CodeQL's
# language list under GITHUB_TOKEN -- three of those reads 403 outright, and
# the other two fields are silently omitted from the API response for a
# non-admin reader even when true. This marker stands in for all three so
# that workflow can tell "verified done" from "never run" -- so it must only
# be written when every assertion below actually passes.
Write-Host ""
Write-Host "Verifying final state before marking setup complete ..."

$failures = @()

$pagesFinal = Invoke-GhCheck @('api', "repos/$Repo/pages")
if (-not $pagesFinal.Success) { $failures += "Pages is not enabled." }

$rulesetsFinal = Invoke-GhRequired @('api', "repos/$Repo/rulesets") | ConvertFrom-Json
if (-not ($rulesetsFinal | Where-Object { $_.name -eq "main-requires-pr" })) {
    $failures += "Ruleset 'main-requires-pr' is missing."
}

$repoInfoFinal = Invoke-GhRequired @('api', "repos/$Repo") | ConvertFrom-Json
if (-not $repoInfoFinal.allow_auto_merge) { $failures += "allow_auto_merge is not enabled." }
if (-not $repoInfoFinal.delete_branch_on_merge) { $failures += "delete_branch_on_merge is not enabled." }

$secFixesFinal = Invoke-GhRequired @('api', "repos/$Repo/automated-security-fixes") | ConvertFrom-Json
if (-not $secFixesFinal.enabled) { $failures += "Dependabot security updates are not enabled." }

$defaultSetupFinal = Invoke-GhRequired @('api', "repos/$Repo/code-scanning/default-setup") | ConvertFrom-Json
if ($defaultSetupFinal.languages -notcontains "javascript-typescript") {
    $failures += "CodeQL default setup does not include javascript-typescript."
}

if ($failures.Count -gt 0) {
    Write-Host ""
    Write-Host "ERROR: setup is not actually complete -- refusing to set the completion marker:" -ForegroundColor Red
    foreach ($f in $failures) { Write-Host "  - $f" }
    Write-Host ""
    Write-Host "Re-run this script after checking the messages above."
    exit 1
}

$timestamp = [DateTime]::UtcNow.ToString("yyyy-MM-ddTHH:mm:ssZ")
Invoke-GhRequired @('variable', 'set', 'VUEJS_TEMPLATE_SETUP_COMPLETE', '--body', $timestamp) | Out-Null
Write-Host "[Marker]       VUEJS_TEMPLATE_SETUP_COMPLETE repository variable set."

Write-Host ""
Write-Host "Done. If your repository is private, note that CodeQL only runs on"
Write-Host "public repositories on this organization's GitHub Free plan -- make it"
Write-Host "public (Settings > General > Danger Zone) or pull requests can never"
Write-Host "satisfy the required check."
