<#
.SYNOPSIS
    Merges a GitHub PR, deletes the remote branch, pulls latest main, and cleans up local branches.

.DESCRIPTION
    Automates the 5-step post-PR cleanup:
    1. gh pr merge --merge --delete-branch (merges PR and deletes branch on GitHub)
    2. git switch main
    3. git pull
    4. git branch -d <branch> (deletes local copy)
    5. git fetch --prune (cleans up stale remote references)
    6. Reminds user if unconsolidated doc fragments exist in docs/changes/

.EXAMPLE
    .\scripts\merge-pr.ps1            # Merges the PR associated with current branch (or single open PR)
    .\scripts\merge-pr.ps1 5          # Merges PR #5 by number
    .\scripts\merge-pr.ps1 -Pr 5
#>
param(
    [string]$Pr
)

$ErrorActionPreference = "Stop"

# Ensure we are inside a git repo
$repoRoot = git rev-parse --show-toplevel 2>$null
if ($LASTEXITCODE -ne 0 -or -not $repoRoot) { throw "Not inside a git repository." }

# Strip leading '#' if provided
if ($Pr -and $Pr.StartsWith("#")) {
    $Pr = $Pr.Substring(1)
}

# Determine PR to merge
$currentBranch = git branch --show-current
$targetPr = $Pr

if (-not $targetPr) {
    if ($currentBranch -eq "main") {
        # Check open PRs
        $openPrs = gh pr list --json number,title,headRefName | ConvertFrom-Json
        if (-not $openPrs -or $openPrs.Count -eq 0) {
            Write-Host "Currently on 'main' and no open PRs found." -ForegroundColor Yellow
            return
        }
        if ($openPrs.Count -eq 1) {
            $targetPr = "$($openPrs[0].number)"
            Write-Host "Detected single open PR: #$targetPr ($($openPrs[0].title))" -ForegroundColor Cyan
        } else {
            Write-Host "Multiple open PRs found. Please specify PR number:" -ForegroundColor Yellow
            foreach ($p in $openPrs) {
                Write-Host "  #$($p.number) - $($p.title) ($($p.headRefName))"
            }
            Write-Host "`nUsage: .\scripts\merge-pr.ps1 <pr-number>" -ForegroundColor Cyan
            return
        }
    } else {
        $targetPr = $currentBranch
    }
}

# Fetch PR details
Write-Host "Fetching PR details for '$targetPr'..." -ForegroundColor Cyan
$prJson = gh pr view $targetPr --json number,title,headRefName,state 2>$null
if ($LASTEXITCODE -ne 0 -or -not $prJson) {
    throw "Could not find PR '$targetPr'. Make sure the PR exists on GitHub."
}

$prInfo = $prJson | ConvertFrom-Json
$prNumber = $prInfo.number
$prTitle = $prInfo.title
$branchName = $prInfo.headRefName
$state = $prInfo.state

if ($state -ne "OPEN") {
    Write-Host "PR #$prNumber is already $state." -ForegroundColor Yellow
    return
}

Write-Host "Merging PR #${prNumber}: '$prTitle' (branch: $branchName)..." -ForegroundColor Cyan

# 1. Merge PR on GitHub & delete remote branch
gh pr merge $prNumber --merge --delete-branch
if ($LASTEXITCODE -ne 0) {
    throw "Failed to merge PR #$prNumber. Check GitHub checks/conflicts."
}
Write-Host "Merged PR #$prNumber and deleted remote branch '$branchName'." -ForegroundColor Green

# 2. Switch to main
if ((git branch --show-current) -ne "main") {
    Write-Host "Switching to 'main'..." -ForegroundColor Cyan
    git switch main
}

# 3. Pull latest main
Write-Host "Pulling latest 'main'..." -ForegroundColor Cyan
git pull

# 4. Delete local branch if it exists and isn't main
if ($branchName -and $branchName -ne "main") {
    git show-ref --verify --quiet "refs/heads/$branchName"
    if ($LASTEXITCODE -eq 0) {
        Write-Host "Deleting local branch '$branchName'..." -ForegroundColor Cyan
        git branch -d $branchName
        if ($LASTEXITCODE -ne 0) {
            git branch -D $branchName
        }
    }
}

# 5. Prune remote references
git fetch --prune --quiet

Write-Host ""
Write-Host "Done! 'main' is up to date and '$branchName' has been cleaned up." -ForegroundColor Green

# 6. Check for unconsolidated fragments
$changesDir = Join-Path $repoRoot "docs\changes"
if (Test-Path $changesDir) {
    $fragments = @(Get-ChildItem -Path $changesDir -File | Where-Object { $_.Name -notin @("README.md", "_template.md") })
    if ($fragments.Count -gt 0) {
        Write-Host ""
        Write-Host "Notice: Found $($fragments.Count) unconsolidated doc fragment(s) in docs/changes/." -ForegroundColor Yellow
        Write-Host "Consider running the 'consolidate-docs' skill when your merge queue is empty." -ForegroundColor Yellow
    }
}
