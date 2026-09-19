param(
    [Parameter(Mandatory = $true)]
    [int]$IssueNumber
)

$ErrorActionPreference = "Stop"

$repoRoot = git rev-parse --show-toplevel
$logsDirectory = Join-Path $repoRoot "logs"

New-Item -ItemType Directory -Force -Path $logsDirectory | Out-Null

$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$logFile = Join-Path $logsDirectory "issue-$IssueNumber-$timestamp.log"

Start-Transcript -Path $logFile

try {
    Write-Host "========================================"
    Write-Host "Codex Issue Worker"
    Write-Host "Issue: #$IssueNumber"
    Write-Host "Started: $(Get-Date)"
    Write-Host "========================================"
    Write-Host ""

    # --------------------------------------------------
    # Validate working tree
    # --------------------------------------------------

    $status = git status --porcelain

    if ($status) {
        throw "Working tree is not clean. Commit or discard existing changes before running the worker."
    }

    # --------------------------------------------------
    # Load issue
    # --------------------------------------------------

    Write-Host "Loading GitHub issue #$IssueNumber..."

    $issue = gh issue view $IssueNumber --json number, title, body, state | ConvertFrom-Json

    if ($issue.state -ne "OPEN") {
        throw "Issue #$IssueNumber is not open."
    }

    Write-Host "Title: $($issue.title)"
    Write-Host ""

    # --------------------------------------------------
    # Determine default branch
    # --------------------------------------------------

    $defaultBranch = gh repo view --json defaultBranchRef --jq ".defaultBranchRef.name"

    Write-Host "Default branch: $defaultBranch"

    # --------------------------------------------------
    # Update local default branch
    # --------------------------------------------------

    Write-Host "Updating $defaultBranch..."

    git checkout $defaultBranch
    git pull --ff-only origin $defaultBranch

    # --------------------------------------------------
    # Create agent branch
    # --------------------------------------------------

    $branchName = "agent/issue-$IssueNumber"

    Write-Host "Creating branch: $branchName"

    git checkout -b $branchName

    # --------------------------------------------------
    # Update issue status
    # --------------------------------------------------

    Write-Host "Marking issue as in progress..."

    gh issue edit $IssueNumber `
        --add-label "status:in-progress"

    # --------------------------------------------------
    # Build Codex prompt
    # --------------------------------------------------

    $prompt = @"
Implement GitHub issue #$($issue.number).

Title:
$($issue.title)

Description:
$($issue.body)

Requirements:
- Follow AGENTS.md.
- Follow the implement-issue skill.
- Implement the requested change.
- Add or update automated tests as required.
- Do not modify unrelated behavior.
- Run the complete test suite.
- Do not commit or push changes.
"@

    # --------------------------------------------------
    # Execute Codex
    # --------------------------------------------------

    Write-Host ""
    Write-Host "========================================"
    Write-Host "Starting Codex"
    Write-Host "========================================"
    Write-Host ""

    codex exec $prompt

    if ($LASTEXITCODE -ne 0) {
        throw "Codex execution failed with exit code $LASTEXITCODE."
    }

    # --------------------------------------------------
    # Run tests independently
    # --------------------------------------------------

    Write-Host ""
    Write-Host "========================================"
    Write-Host "Running test suite"
    Write-Host "========================================"
    Write-Host ""

    python3 -m pytest

    if ($LASTEXITCODE -ne 0) {
        throw "Test suite failed with exit code $LASTEXITCODE."
    }

    # --------------------------------------------------
    # Check changes
    # --------------------------------------------------

    Write-Host ""
    Write-Host "Checking Git changes..."

    $changes = git status --porcelain

    if (-not $changes) {
        throw "Codex completed successfully, but no changes were produced."
    }

    Write-Host ""
    Write-Host "Changes:"
    git status --short

    # --------------------------------------------------
    # Commit
    # --------------------------------------------------

    Write-Host ""
    Write-Host "Creating commit..."

    git add .

    git commit -m "Implement issue #$IssueNumber"

    if ($LASTEXITCODE -ne 0) {
        throw "Git commit failed."
    }

    # --------------------------------------------------
    # Push
    # --------------------------------------------------

    Write-Host ""
    Write-Host "Pushing branch..."

    git push --set-upstream origin $branchName

    if ($LASTEXITCODE -ne 0) {
        throw "Git push failed."
    }

    # --------------------------------------------------
    # Create Pull Request
    # --------------------------------------------------

    Write-Host ""
    Write-Host "Creating Pull Request..."

    $prBody = @"
## Summary

Automated implementation of GitHub issue #$IssueNumber.

## Issue

#$IssueNumber

## Validation

- Codex implementation completed
- Automated test suite passed

Generated by the Codex issue worker.
"@

    $prUrl = gh pr create `
        --base $defaultBranch `
        --head $branchName `
        --title $issue.title `
        --body $prBody

    if ($LASTEXITCODE -ne 0) {
        throw "Pull Request creation failed."
    }

    Write-Host ""
    Write-Host "Pull Request created:"
    Write-Host $prUrl

    # --------------------------------------------------
    # Comment on issue
    # --------------------------------------------------

    $comment = @"
The implementation has been completed by the Codex agent.

Pull Request: $prUrl

The automated test suite passed successfully.

Status: Ready for Review.
"@

    gh issue comment $IssueNumber --body $comment

    if ($LASTEXITCODE -ne 0) {
        throw "Failed to comment on GitHub issue."
    }

    # --------------------------------------------------
    # Update labels
    # --------------------------------------------------

    gh issue edit $IssueNumber `
        --remove-label "status:in-progress" `
        --add-label "status:ready-for-review"

    Write-Host ""
    Write-Host "========================================"
    Write-Host "SUCCESS"
    Write-Host "========================================"
    Write-Host "Issue: #$IssueNumber"
    Write-Host "Branch: $branchName"
    Write-Host "Pull Request: $prUrl"
    Write-Host "Log: $logFile"
    Write-Host ""

}
catch {
    Write-Host ""
    Write-Host "========================================"
    Write-Host "FAILED"
    Write-Host "========================================"
    Write-Host $_.Exception.Message

    try {
        gh issue edit $IssueNumber `
            --remove-label "status:in-progress" `
            --add-label "status:failed"
    }
    catch {
        Write-Host "Failed to update GitHub issue status."
    }

    exit 1
}
finally {
    Write-Host ""
    Write-Host "Finished: $(Get-Date)"
    Stop-Transcript
}