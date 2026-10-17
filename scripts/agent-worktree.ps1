<#
.SYNOPSIS
    Create or remove an isolated git worktree + branch for an agent.

.DESCRIPTION
    Each agent gets its own folder and branch (agent/<Name>), so 2-3 agents can
    work in parallel without touching each other's files or main.
    Worktrees are created next to the repo in "<repo>-wt\<Name>".
    New branches start from a freshly fetched origin/main (see docs/workflow.md).

.EXAMPLE
    .\scripts\agent-worktree.ps1 -Name 42-login-form
    .\scripts\agent-worktree.ps1 -Name 42-login-form -Base main   # offline: use local main
    .\scripts\agent-worktree.ps1 -Name 42-login-form -Remove
    .\scripts\agent-worktree.ps1 -List
#>
param(
    [string]$Name,
    [string]$Base = "origin/main",
    [switch]$Remove,
    [switch]$List
)

$ErrorActionPreference = "Stop"

if ($List) {
    git worktree list
    return
}

if (-not $Name) { throw "Provide -Name (e.g. -Name 42-login-form) or use -List." }

$repoRoot = git rev-parse --show-toplevel 2>$null
if ($LASTEXITCODE -ne 0 -or -not $repoRoot) { throw "Not inside a git repository." }

$repoName = Split-Path $repoRoot -Leaf
$branch   = "agent/$Name"
$path     = Join-Path (Split-Path $repoRoot -Parent) "$repoName-wt\$Name"

if ($Remove) {
    git worktree remove $path
    if ($LASTEXITCODE -ne 0) { throw "Failed to remove worktree at $path (uncommitted changes?)." }
    Write-Host "Removed worktree: $path"
    Write-Host "Branch '$branch' kept. Delete after merge with: git branch -d $branch"
    return
}

git show-ref --verify --quiet "refs/heads/$branch"
if ($LASTEXITCODE -eq 0) {
    git worktree add $path $branch
} else {
    if ($Base -like "origin/*") {
        git fetch origin --quiet
        if ($LASTEXITCODE -ne 0) { throw "git fetch failed. Check your connection, or use -Base main to start from local main." }
    }
    # --no-track: the new branch must not use origin/main as its upstream.
    git worktree add --no-track -b $branch $path $Base
}
if ($LASTEXITCODE -ne 0) { throw "git worktree add failed." }

Write-Host ""
Write-Host "Worktree ready: $path"
Write-Host "Branch:         $branch"
Write-Host "Open that folder in a separate IDE window and point the agent at it."
Write-Host "First push:     git push -u origin $branch"
