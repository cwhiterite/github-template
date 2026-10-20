<#
.SYNOPSIS
    Merges a GitHub PR, deletes the remote branch, pulls latest main, and cleans up local branches.

.DESCRIPTION
    Human operator convenience script for completing the merge ritual:
    1. gh pr merge --<strategy> --delete-branch (merges PR and deletes branch on GitHub)
    2. Removes any linked agent worktree attached to the branch
    3. git switch main (when run from main worktree)
    4. git pull
    5. git branch -d <branch> (deletes local branch)
    6. git fetch --prune (cleans up stale remote references)
    7. Reminds user if unconsolidated doc fragments exist in docs/changes/

.EXAMPLE
    .\scripts\merge-pr.ps1                         # Merges PR associated with current branch (or single open PR)
    .\scripts\merge-pr.ps1 5                       # Merges PR #5 by number
    .\scripts\merge-pr.ps1 -Pr 5 -Strategy squash  # Squash-merges PR #5
    .\scripts\merge-pr.ps1 5 -WhatIf               # Previews actions without making changes
#>
param(
    [string]$Pr,
    [ValidateSet("merge", "squash", "rebase")]
    [string]$Strategy = "merge",
    [switch]$WhatIf
)

$ErrorActionPreference = "Stop"

# Ensure we are inside a git repo
$repoRoot = git rev-parse --show-toplevel 2>$null
if ($LASTEXITCODE -ne 0 -or -not $repoRoot) { throw "Not inside a git repository." }

# Strip leading '#' if provided
if ($Pr -and $Pr.StartsWith("#")) {
    $Pr = $Pr.Substring(1)
}

# Determine primary worktree vs linked worktree
$worktreeListRaw = git worktree list --porcelain
$primaryWorktree = $null
$branchWorktreeMap = @{}
$currentWtPath = $null

foreach ($line in ($worktreeListRaw -split "`r?`n")) {
    if ($line -match '^worktree\s+(.+)$') {
        $currentWtPath = $Matches[1].Trim()
        if (-not $primaryWorktree) {
            $primaryWorktree = $currentWtPath
        }
    }
    elseif ($line -match '^branch\s+refs/heads/(.+)$') {
        $bName = $Matches[1].Trim()
        if ($currentWtPath -and ($currentWtPath.Replace('\', '/').TrimEnd('/') -ne $primaryWorktree.Replace('\', '/').TrimEnd('/'))) {
            $branchWorktreeMap[$bName] = $currentWtPath
        }
    }
}

$isPrimaryWorktree = ($repoRoot.Replace('\', '/').TrimEnd('/') -eq $primaryWorktree.Replace('\', '/').TrimEnd('/'))

# Determine PR to merge
$currentBranch = git branch --show-current
$targetPr = $Pr

if (-not $targetPr) {
    if ($currentBranch -eq "main") {
        # Check open PRs
        $oldEAP = $ErrorActionPreference
        $ErrorActionPreference = "Continue"
        $openPrsJson = gh pr list --json number,title,headRefName 2>$null
        $listExit = $LASTEXITCODE
        $ErrorActionPreference = $oldEAP

        if ($listExit -ne 0 -or -not $openPrsJson) {
            Write-Host "Currently on 'main' and no open PRs found." -ForegroundColor Yellow
            return
        }
        $openPrs = $openPrsJson | ConvertFrom-Json
        if (-not $openPrs -or $openPrs.Count -eq 0) {
            Write-Host "Currently on 'main' and no open PRs found." -ForegroundColor Yellow
            return
        }
        if ($openPrs.Count -eq 1) {
            $targetPr = "$($openPrs[0].number)"
            Write-Host "Detected single open PR: #$targetPr ($($openPrs[0].title))" -ForegroundColor Cyan
        }
        else {
            Write-Host "Multiple open PRs found. Please specify PR number:" -ForegroundColor Yellow
            foreach ($p in $openPrs) {
                Write-Host "  #$($p.number) - $($p.title) ($($p.headRefName))"
            }
            Write-Host "`nUsage: .\scripts\merge-pr.ps1 <pr-number>" -ForegroundColor Cyan
            return
        }
    }
    else {
        $targetPr = $currentBranch
    }
}

# Fetch PR details
Write-Host "Fetching PR details for '$targetPr'..." -ForegroundColor Cyan
$oldEAP = $ErrorActionPreference
$ErrorActionPreference = "Continue"
$prJson = gh pr view $targetPr --json number,title,headRefName,state,body,url 2>$null
$viewExit = $LASTEXITCODE
$ErrorActionPreference = $oldEAP

if ($viewExit -ne 0 -or -not $prJson) {
    Write-Host "No open PR found for '$targetPr'. Make sure the PR has been created on GitHub." -ForegroundColor Yellow
    return
}

$prInfo = $prJson | ConvertFrom-Json
$prNumber = $prInfo.number
$prTitle = $prInfo.title
$branchName = $prInfo.headRefName
$state = $prInfo.state
$prUrl = $prInfo.url
$prBody = $prInfo.body

if ($state -ne "OPEN") {
    Write-Host "PR #$prNumber is already $state." -ForegroundColor Yellow
    return
}

if ($WhatIf) {
    Write-Host "`n[WhatIf] Target PR:       #$prNumber - '$prTitle'" -ForegroundColor Magenta
    if ($prUrl) {
        Write-Host "[WhatIf] URL:             $prUrl" -ForegroundColor Magenta
    }
    Write-Host "[WhatIf] Branch:          $branchName" -ForegroundColor Magenta
    Write-Host "[WhatIf] Strategy:        --$Strategy" -ForegroundColor Magenta
    if ($branchWorktreeMap.ContainsKey($branchName)) {
        Write-Host "[WhatIf] Linked Worktree: $($branchWorktreeMap[$branchName]) (would remove)" -ForegroundColor Magenta
    }
    Write-Host "[WhatIf] Actions to run:" -ForegroundColor Magenta
    Write-Host "  1. gh pr merge $prNumber --$Strategy --delete-branch"
    if ($branchWorktreeMap.ContainsKey($branchName)) {
        Write-Host "  2. git worktree remove `"$($branchWorktreeMap[$branchName])`""
    }
    if ($isPrimaryWorktree) {
        Write-Host "  3. git switch main && git pull"
    } else {
        Write-Host "  3. (Skipping switch to main; currently inside linked worktree $repoRoot)"
    }
    Write-Host "  4. git branch -d $branchName"
    Write-Host "  5. git fetch --prune"

    if ($prBody -and $prBody.Trim()) {
        Write-Host ("`n+-- PR Description " + ("-" * 50)) -ForegroundColor DarkGray
        foreach ($line in ($prBody -split "`r?`n")) {
            Write-Host "| $line"
        }
        Write-Host ("+-" + ("-" * 67) + "`n") -ForegroundColor DarkGray
    }
    return
}

Write-Host "Merging PR #${prNumber}: '$prTitle' (branch: $branchName) with --$Strategy..." -ForegroundColor Cyan

# 1. Merge PR on GitHub & delete remote branch
gh pr merge $prNumber "--$Strategy" --delete-branch
if ($LASTEXITCODE -ne 0) {
    throw "Failed to merge PR #$prNumber. Check GitHub checks or merge conflicts."
}
Write-Host "Merged PR #$prNumber and deleted remote branch '$branchName'." -ForegroundColor Green

# 2. Clean up linked worktree if one exists for this branch
if ($branchWorktreeMap.ContainsKey($branchName)) {
    $wtPath = $branchWorktreeMap[$branchName]
    Write-Host "Removing linked worktree at '$wtPath'..." -ForegroundColor Cyan
    git worktree remove $wtPath 2>$null
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Notice: Could not automatically remove worktree at '$wtPath' (may contain unstaged changes). You can remove it with: git worktree remove `"$wtPath`"" -ForegroundColor Yellow
    } else {
        Write-Host "Removed linked worktree '$wtPath'." -ForegroundColor Green
    }
}

# 3. Switch to main & pull (if in primary worktree)
if ($isPrimaryWorktree) {
    if ((git branch --show-current) -ne "main") {
        Write-Host "Switching to 'main'..." -ForegroundColor Cyan
        git switch main
    }
    Write-Host "Pulling latest 'main'..." -ForegroundColor Cyan
    git pull
} else {
    Write-Host "Note: Currently in a linked worktree ($repoRoot). Switch to the main worktree ($primaryWorktree) to pull latest main." -ForegroundColor Yellow
}

# 4. Delete local branch if it exists and isn't main
if ($branchName -and $branchName -ne "main") {
    git show-ref --verify --quiet "refs/heads/$branchName"
    if ($LASTEXITCODE -eq 0) {
        Write-Host "Deleting local branch '$branchName'..." -ForegroundColor Cyan
        git branch -d $branchName 2>$null
        if ($LASTEXITCODE -ne 0) {
            git branch -D $branchName
        }
    }
}

# 5. Prune remote references
git fetch --prune --quiet

Write-Host ""
Write-Host "Done! PR #$prNumber merged and cleaned up." -ForegroundColor Green

# 6. Check for unconsolidated fragments
$changesDir = Join-Path $primaryWorktree "docs\changes"
if (Test-Path $changesDir) {
    $fragments = @(Get-ChildItem -Path $changesDir -File | Where-Object { $_.Name -notin @("README.md", "_template.md") })
    if ($fragments.Count -gt 0) {
        Write-Host ""
        Write-Host "Notice: Found $($fragments.Count) unconsolidated doc fragment(s) in docs/changes/." -ForegroundColor Yellow
        Write-Host "Consider running the 'consolidate-docs' skill when your merge queue is empty." -ForegroundColor Yellow
    }
}
