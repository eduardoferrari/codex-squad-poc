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
# Track running workers
# --------------------------------------------------

$workers = @()

# --------------------------------------------------
# Main loop
# --------------------------------------------------

while ($true) {

    Write-Host ""
    Write-Host "[$(Get-Date)] Watcher cycle"

    # --------------------------------------------------
    # Remove completed workers
    # --------------------------------------------------

    $completedWorkers = @()

    foreach ($worker in $workers) {

        if ($worker.Process.HasExited) {

            Write-Host ""
            Write-Host "Worker finished:"
            Write-Host "Repository: $($worker.Repository)"
            Write-Host "Issue: #$($worker.IssueNumber)"
            Write-Host "Exit code: $($worker.Process.ExitCode)"

            $completedWorkers += $worker
        }
    }

    foreach ($worker in $completedWorkers) {
        $workers = $workers | Where-Object {
            $_ -ne $worker
        }
    }

    # --------------------------------------------------
    # Current capacity
    # --------------------------------------------------

    $runningCount = $workers.Count
    $availableSlots = $maxConcurrency - $runningCount

    Write-Host ""
    Write-Host "Running workers: $runningCount / $maxConcurrency"

    if ($availableSlots -le 0) {

        Write-Host "No worker slots available."
        Start-Sleep -Seconds $pollIntervalSeconds
        continue
    }

    # --------------------------------------------------
    # Discover queued issues
    # --------------------------------------------------

    $queuedIssues = @()

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

    if ($queuedIssues.Count -eq 0) {

        Write-Host ""
        Write-Host "No queued issues found."

        Start-Sleep -Seconds $pollIntervalSeconds
        continue
    }

    # --------------------------------------------------
    # Start workers
    # --------------------------------------------------

    $issuesToProcess = $queuedIssues |
    Select-Object -First $availableSlots

    foreach ($issue in $issuesToProcess) {

        Write-Host ""
        Write-Host "Reserving issue:"
        Write-Host "Repository: $($issue.Repository)"
        Write-Host "Issue: #$($issue.IssueNumber)"

        try {

            # --------------------------------------------------
            # Reserve issue
            # --------------------------------------------------

            gh issue edit $issue.IssueNumber `
                --repo $issue.Repository `
                --remove-label "status:queued" `
                --add-label "status:in-progress"

            if ($LASTEXITCODE -ne 0) {
                throw "Failed to reserve issue."
            }

            Write-Host "Issue reserved."
        
            # --------------------------------------------------
            # Start worker
            # --------------------------------------------------

            $arguments = @(
                "-NoProfile"
                "-ExecutionPolicy"
                "Bypass"
                "-File"
                "`"$PSScriptRoot\run-issue.ps1`""
                "-Repository"
                "`"$($issue.Repository)`""
                "-IssueNumber"
                "$($issue.IssueNumber)"
                "-WorkspaceRoot"
                "`"$workspaceRoot`""
                "-LogRoot"
                "`"$logRoot`""
            )

            $process = Start-Process `
                -FilePath "pwsh.exe" `
                -ArgumentList $arguments `
                -PassThru

            $workers += [PSCustomObject]@{
                Process     = $process
                Repository  = $issue.Repository
                IssueNumber = $issue.IssueNumber
                Title       = $issue.Title
                StartedAt   = Get-Date
            }

            Write-Host "Worker PID: $($process.Id)"
        }
        catch {

            Write-Host ""
            Write-Host "Failed to start worker:"
            Write-Host $_.Exception.Message

            try {

                gh issue edit $issue.IssueNumber `
                    --repo $issue.Repository `
                    --remove-label "status:in-progress" `
                    --add-label "status:queued"

            }
            catch {

                Write-Host "Failed to restore queued status."
            }
        }
    }

    Start-Sleep -Seconds $pollIntervalSeconds
}