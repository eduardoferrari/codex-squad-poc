param(
    [Parameter(Mandatory = $true)]
    [string]$Repository,

    [Parameter(Mandatory = $true)]
    [int]$IssueNumber,

    [Parameter(Mandatory = $true)]
    [string]$WorkspaceRoot,

    [Parameter(Mandatory = $true)]
    [string]$LogRoot
)

$ErrorActionPreference = "Stop"

$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"

$normalizedRepoName = $Repository.Replace("/", "_")

$logDirectory = Join-Path $LogRoot $normalizedRepoName
$logFile = Join-Path $logDirectory "issue-$IssueNumber-$timestamp.log"

$workspaceName = "$normalizedRepoName-issue-$IssueNumber-$timestamp"
$workspacePath = Join-Path $WorkspaceRoot $workspaceName

New-Item -ItemType Directory -Force -Path $workspacePath | Out-Null
New-Item -ItemType Directory -Force -Path $logDirectory | Out-Null

Start-Transcript -Path $logFile

try {

    Write-Host "========================================"
    Write-Host "Codex Issue Worker"
    Write-Host "Repository: $Repository"
    Write-Host "Issue: #$IssueNumber"
    Write-Host "Workspace: $workspacePath"
    Write-Host "========================================"
    Write-Host ""

    # --------------------------------------------------
    # Load issue
    # --------------------------------------------------

    Write-Host "Loading GitHub issue..."

    $issue = gh issue view $IssueNumber `
        --repo $Repository `
        --json number,title,body,state | ConvertFrom-Json

    if ($issue.state -ne "OPEN") {
        throw "Issue #$IssueNumber is not open."
    }

    Write-Host "Title: $($issue.title)"
    Write-Host ""

    # --------------------------------------------------
    # Clone repository
    # --------------------------------------------------

    Write-Host "Cloning repository..."

    git clone "https://github.com/$Repository.git" $workspacePath

    if ($LASTEXITCODE -ne 0) {
        throw "Git clone failed."
    }

    Set-Location $workspacePath

    # --------------------------------------------------
    # Determine default branch
    # --------------------------------------------------

    $defaultBranch = gh repo view `
        --json defaultBranchRef `
        --jq ".defaultBranchRef.name"

    Write-Host "Default branch: $defaultBranch"

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
        --repo $Repository `
        --remove-label "status:queued" `
        --add-label "status:in-progress"

    # --------------------------------------------------
    # Codex prompt
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
    # Run tests
    # --------------------------------------------------

    Write-Host ""
    Write-Host "Running test suite..."

    python3 -m pytest

    if ($LASTEXITCODE -ne 0) {
        throw "Test suite failed with exit code $LASTEXITCODE."
    }

    # --------------------------------------------------
    # Check changes
    # --------------------------------------------------

    $changes = git status --porcelain

    if (-not $changes) {
        throw "No changes were produced."
    }

    Write-Host ""
    Write-Host "Changes:"
    git status --short

    # --------------------------------------------------
    # Commit
    # --------------------------------------------------

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
    # Create PR
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
        --repo $Repository `
        --base $defaultBranch `
        --head $branchName `
        --title $issue.title `
        --body $prBody

    if ($LASTEXITCODE -ne 0) {
        throw "Pull Request creation failed."
    }

    Write-Host "Pull Request: $prUrl"

    # --------------------------------------------------
    # Comment
    # --------------------------------------------------

    $comment = @"
The implementation has been completed by the Codex agent.

Pull Request: $prUrl

The automated test suite passed successfully.

Status: Ready for Review.
"@

    gh issue comment $IssueNumber `
        --repo $Repository `
        --body $comment

    if ($LASTEXITCODE -ne 0) {
        throw "Failed to comment on GitHub issue."
    }

    # --------------------------------------------------
    # Final status
    # --------------------------------------------------

    gh issue edit $IssueNumber `
        --repo $Repository `
        --remove-label "status:in-progress" `
        --add-label "status:ready-for-review"

    Write-Host ""
    Write-Host "========================================"
    Write-Host "SUCCESS"
    Write-Host "========================================"
    Write-Host "Issue: #$IssueNumber"
    Write-Host "Repository: $Repository"
    Write-Host "Branch: $branchName"
    Write-Host "PR: $prUrl"

}
catch {

    Write-Host ""
    Write-Host "========================================"
    Write-Host "FAILED"
    Write-Host "========================================"
    Write-Host $_.Exception.Message

    try {

        gh issue edit $IssueNumber `
            --repo $Repository `
            --remove-label "status:in-progress" `
            --remove-label "status:queued" `
            --add-label "status:failed"

    }
    catch {

        Write-Host "Failed to update GitHub issue status."
    }

    exit 1
}
finally {

    Set-Location $PSScriptRoot

    Write-Host ""
    Write-Host "Cleaning workspace..."

    if (Test-Path $workspacePath) {
        Remove-Item `
            -Path $workspacePath `
            -Recurse `
            -Force
    }

    Write-Host "Workspace removed."
    Write-Host ""

    Stop-Transcript
}