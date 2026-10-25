<#
.SYNOPSIS
    Protect a branch (default: main): require a pull request + require status checks.

.DESCRIPTION
    Applies classic branch protection in one command, so a fresh project gets the
    rule instead of depending on someone clicking through Settings -> Branches.

    What it sets:
    - Require a pull request before merging -> no direct pushes to main (AGENTS.md rule 1).
    - Required approving reviews: 0. GitHub forbids authors from approving their own
      pull requests, so requiring even one approval would deadlock a solo repository.
    - Required status checks: the guard workflow's job name(s).
    - enforce_admins: true, so the rule applies to you too - that is the point.
    - strict: true, so branches must be up to date with main before merging. The
      `merge` skill already brings branches up to date, and this keeps check results
      fresh instead of green-on-a-stale-base.

    Escape hatch if a required check ever stops running and blocks every PR:
        gh api -X DELETE repos/<owner>/<repo>/branches/main/protection

.PARAMETER Branch
    Branch to protect. Default: main.

.PARAMETER Checks
    Required status check names. Default: "Shared docs guard" - the job name from
    .github/workflows/guard.yml. Pass an empty array to require no checks.

.PARAMETER Remove
    Delete the protection entirely.

.PARAMETER WhatIf
    Print the payload that would be sent, without applying it.

.EXAMPLE
    .\scripts\protect-main.ps1

.EXAMPLE
    .\scripts\protect-main.ps1 -WhatIf

.EXAMPLE
    .\scripts\protect-main.ps1 -Checks "Shared docs guard","tests"

.EXAMPLE
    .\scripts\protect-main.ps1 -Remove

.NOTES
    Needs the GitHub CLI (gh) with admin rights on the repository.
#>
param(
    [string]$Branch = "main",
    [string[]]$Checks = @("Shared docs guard"),
    [switch]$Remove,
    [switch]$WhatIf
)

$ErrorActionPreference = "Stop"

# gh writes progress and errors to stderr, which becomes a terminating error under
# EAP=Stop when redirected; swap it out around gh calls and check $LASTEXITCODE.
$oldEAP = $ErrorActionPreference
$ErrorActionPreference = "Continue"
$repo = gh repo view --json nameWithOwner -q .nameWithOwner 2>$null
$repoExit = $LASTEXITCODE
$ErrorActionPreference = $oldEAP

if ($repoExit -ne 0 -or -not $repo) {
    throw "Could not determine the GitHub repository. Is the GitHub CLI (gh) installed and authenticated?"
}

$endpoint = "repos/$repo/branches/$Branch/protection"

if ($Remove) {
    $ErrorActionPreference = "Continue"
    gh api -X DELETE $endpoint 2>$null
    $delExit = $LASTEXITCODE
    $ErrorActionPreference = $oldEAP
    if ($delExit -ne 0) { throw "Failed to remove protection from '$Branch' (HTTP $delExit)." }
    Write-Host "Protection removed from '$Branch'. Direct pushes are allowed again." -ForegroundColor Yellow
    return
}

if ($Checks.Count -eq 0) {
    $statusChecks = "null"
} else {
    $contexts = ($Checks | ForEach-Object { '"{0}"' -f $_ }) -join ", "
    $statusChecks = "{`"strict`": true, `"contexts`": [$contexts]}"
}

$payload = @"
{
  "required_status_checks": $statusChecks,
  "enforce_admins": true,
  "required_pull_request_reviews": { "required_approving_review_count": 0 },
  "restrictions": null
}
"@

if ($WhatIf) {
    Write-Host "[WhatIf] Repository: $repo" -ForegroundColor Magenta
    Write-Host "[WhatIf] Endpoint:    PUT $endpoint" -ForegroundColor Magenta
    Write-Host "[WhatIf] Payload:" -ForegroundColor Magenta
    $payload -split "`r?`n" | ForEach-Object { Write-Host "  $_" -ForegroundColor Magenta }
    return
}

Write-Host "Protecting '$Branch' in $repo ..." -ForegroundColor Cyan

$ErrorActionPreference = "Continue"
$payload | gh api -X PUT $endpoint --input - 2>$null | Out-Null
$putExit = $LASTEXITCODE
$ErrorActionPreference = $oldEAP
if ($putExit -ne 0) {
    throw "Failed to protect '$Branch' (HTTP $putExit). Run 'gh auth status' and check you are an admin on $repo."
}

# Confirm what GitHub actually stored rather than trusting the request.
$ErrorActionPreference = "Continue"
$statusJson = gh api $endpoint 2>$null
$getExit = $LASTEXITCODE
$ErrorActionPreference = $oldEAP
if ($getExit -ne 0) { throw "Protection applied, but could not read it back (HTTP $getExit)." }

$protection = $statusJson | ConvertFrom-Json
$requiredContexts = @()
if ($protection.required_status_checks) { $requiredContexts = @($protection.required_status_checks.contexts) }

Write-Host ""
Write-Host "Protected:              $Branch (repo: $repo)" -ForegroundColor Green
Write-Host "Pull requests required: yes (approvals: $($protection.required_pull_request_reviews.required_approving_review_count))"
Write-Host "Admins bound too:       $($protection.enforce_admins.enabled)"
Write-Host "Up-to-date required:    $($protection.required_status_checks.strict)"
Write-Host "Required checks:        $(if ($requiredContexts.Count) { $requiredContexts -join ', ' } else { '(none)' })"
Write-Host ""
Write-Host "Undo with: .\scripts\protect-main.ps1 -Remove" -ForegroundColor DarkGray
