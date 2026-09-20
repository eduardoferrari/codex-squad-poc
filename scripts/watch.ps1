param(
    [string]$ConfigPath = "$PSScriptRoot\..\config.json"
)

$ErrorActionPreference = "Stop"

# --------------------------------------------------
# Load configuration
# --------------------------------------------------

if (-not (Test-Path $ConfigPath)) {
    throw "Configuration file not found: $ConfigPath"
}

$config = Get-Content $ConfigPath -Raw | ConvertFrom-Json

$pollIntervalSeconds = $config.pollIntervalSeconds
$maxConcurrency = $config.maxConcurrency
$workspaceRoot = $config.workspaceRoot
$logRoot = $config.logRoot

Write-Host "========================================"
Write-Host "Codex Issue Watcher"
Write-Host "========================================"
Write-Host ""

Write-Host "Poll interval : $pollIntervalSeconds seconds"
Write-Host "Concurrency   : $maxConcurrency"
Write-Host "Workspace root: $workspaceRoot"
Write-Host "Log root      : $logRoot"
Write-Host ""

Write-Host "Repositories:"

foreach ($repository in $config.repositories) {
    Write-Host " - $($repository.name): $($repository.repository)"
}

Write-Host ""

# --------------------------------------------------
# Ensure directories exist
# --------------------------------------------------

New-Item `
    -ItemType Directory `
    -Force `
    -Path $workspaceRoot | Out-Null

New-Item `
    -ItemType Directory `
    -Force `
    -Path $logRoot | Out-Null

# --------------------------------------------------
# Main loop
# --------------------------------------------------

while ($true) {

    Write-Host ""
    Write-Host "[$(Get-Date)] Checking repositories..."

    try {

        $queuedIssues = @()

        # --------------------------------------------------
        # Discover queued issues
        # --------------------------------------------------

        foreach ($repository in $config.repositories) {

            Write-Host ""
            Write-Host "Checking $($repository.name)..."

            $issues = gh issue list `
                --repo $repository.repository `
                --state open `
                --label "status:queued" `
                --json number,title `
                --limit 10 |
                ConvertFrom-Json

            foreach ($issue in $issues) {

                $queuedIssues += [PSCustomObject]@{
                    RepositoryName = $repository.name
                    Repository     = $repository.repository
                    IssueNumber    = $issue.number
                    Title          = $issue.title
                }
            }
        }

        # --------------------------------------------------
        # Nothing to process
        # --------------------------------------------------

        if ($queuedIssues.Count -eq 0) {

            Write-Host ""
            Write-Host "No queued issues found."
        }
        else {

            Write-Host ""
            Write-Host "Queued issues found: $($queuedIssues.Count)"

            foreach ($issue in $queuedIssues) {

                Write-Host ""
                Write-Host "#$($issue.IssueNumber) - $($issue.Title)"
                Write-Host "Repository: $($issue.Repository)"
            }

            # --------------------------------------------------
            # Limit concurrency
            # --------------------------------------------------

            $availableSlots = $maxConcurrency

            $issuesToProcess = $queuedIssues |
                Select-Object -First $availableSlots

            foreach ($issue in $issuesToProcess) {

                Write-Host ""
                Write-Host "Starting worker:"
                Write-Host "Repository: $($issue.Repository)"
                Write-Host "Issue: #$($issue.IssueNumber)"

                & "$PSScriptRoot\run-issue.ps1" `
                    -Repository $issue.Repository `
                    -IssueNumber $issue.IssueNumber `
                    -WorkspaceRoot $workspaceRoot `
                    -LogRoot $logRoot

                if ($LASTEXITCODE -eq 0) {

                    Write-Host ""
                    Write-Host "Worker completed successfully."
                }
                else {

                    Write-Host ""
                    Write-Host "Worker failed."
                }
            }
        }

    }
    catch {

        Write-Host ""
        Write-Host "Watcher error:"
        Write-Host $_.Exception.Message
    }

    Write-Host ""
    Write-Host "Sleeping for $pollIntervalSeconds seconds..."

    Start-Sleep -Seconds $pollIntervalSeconds
}