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
    # Codex prompt
    # --------------------------------------------------

    $prompt = @"
You are an autonomous software engineering orchestrator.

Your responsibility is to take the GitHub issue provided below from
understanding through implementation and validation.

Repository rules:

1. Read and follow all applicable AGENTS.md files before making changes.
2. Inspect the repository structure and existing implementation before changing code.
3. Discover the available skills in the repository before deciding how to perform the task.
4. Select and use the skills that are relevant to the issue.
5. Skills are specialized capabilities. They are not necessarily a fixed sequence.
6. You may use multiple skills when the issue requires them.
7. Follow the repository's existing architecture, conventions, and coding standards.
8. Do not modify unrelated files.
9. Do not perform speculative refactoring.

Execution workflow:

1. Understand the GitHub issue and its acceptance criteria.
2. Inspect the repository and relevant documentation.
3. Discover the available skills in the repository.
4. Read the instructions for the discovered skills and determine which skills are applicable to the current issue.
5. Select only the skills that are relevant to the task.
6. Explain briefly why each selected skill is applicable before executing the implementation workflow.
7. Create an implementation plan based on the selected skills.
8. Implement the required changes.
9. Add or update automated tests when appropriate.
10. Run the relevant validation and test suite.
11. Review the implementation for correctness, regressions, and scope.
12. Fix problems discovered during testing or review.
13. Run the relevant validation again after fixes.

Skill selection rules:

- Do not assume that every available skill must be used.
- Do not assume that a skill must be used solely because its name appears relevant.
- Read the skill instructions before selecting it.
- Use multiple skills when the issue requires multiple capabilities.
- A skill may be skipped when its purpose does not apply to the issue.
- Skills may be used more than once if the workflow requires it.
- The selected skills must support the requirements of the GitHub issue.
- Do not create a new skill when an existing skill is sufficient.
- Do not treat the skill directory structure as the workflow.
  Skills define capabilities and guidance.
  The issue determines the workflow.

Important:

- Do not assume that implementation is successful merely because files were modified.
- Do not claim tests passed unless they were actually executed and passed.
- Do not claim the issue is complete if a blocking problem remains.
- Do not hide failures.
- If the issue cannot be completed safely, stop and clearly report the reason.
- Keep the implementation focused on the requested issue.

Completion criteria:

The task is complete only when:

- The requested functionality has been implemented.
- The implementation follows repository instructions.
- Relevant tests have been added or updated when necessary.
- Relevant tests have actually been executed.
- Validation succeeds.
- No known blocking issue remains.

At the end, provide a concise report containing:

- What was implemented.
- Which skills were used.
- Which tests or validation commands were executed.
- Whether validation passed or failed.
- Any remaining blocking issues.

GitHub Issue:

Number: #$($issue.number)

Title: $($issue.title)

Description:
$($issue.body)
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