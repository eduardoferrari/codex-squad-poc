param(
    [Parameter(Mandatory = $true)]
    [int]$IssueNumber
)

$ErrorActionPreference = "Stop"

Write-Host "Loading GitHub issue #$IssueNumber..."

$issue = gh issue view $IssueNumber --json number,title,body,state | ConvertFrom-Json

if ($issue.state -ne "OPEN") {
    Write-Host "Issue #$IssueNumber is not open."
    exit 1
}

Write-Host "Marking issue as in progress..."

gh issue edit $IssueNumber --add-label "status:in-progress"

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

Write-Host ""
Write-Host "Starting Codex..."
Write-Host ""

codex exec $prompt

if ($LASTEXITCODE -ne 0) {
    Write-Host ""
    Write-Host "Codex execution failed."

    gh issue edit $IssueNumber --remove-label "status:in-progress"
    gh issue edit $IssueNumber --add-label "status:failed"

    exit $LASTEXITCODE
}

Write-Host ""
Write-Host "Codex execution completed."

gh issue edit $IssueNumber --remove-label "status:in-progress"
gh issue edit $IssueNumber --add-label "status:ready-for-review"

Write-Host ""
Write-Host "Issue #$IssueNumber is ready for review."
