param(
    [int]$IntervalSeconds = 30
)

$ErrorActionPreference = "Stop"

Write-Host "========================================"
Write-Host "Codex Issue Watcher"
Write-Host "========================================"
Write-Host ""
Write-Host "Polling interval: $IntervalSeconds seconds"
Write-Host ""

while ($true) {

    Write-Host ""
    Write-Host "[$(Get-Date)] Checking for queued issues..."

    try {

        $issues = gh issue list `
            --state open `
            --label "status:queued" `
            --json number,title `
            --limit 10 | ConvertFrom-Json

        if (-not $issues -or $issues.Count -eq 0) {
            Write-Host "No queued issues found."
        }
        else {

            foreach ($issue in $issues) {

                Write-Host ""
                Write-Host "Found issue #$($issue.number): $($issue.title)"

                Write-Host "Starting worker..."

                & "$PSScriptRoot\run-issue.ps1" $issue.number

                if ($LASTEXITCODE -eq 0) {
                    Write-Host "Issue #$($issue.number) completed successfully."
                }
                else {
                    Write-Host "Issue #$($issue.number) failed."
                }
            }
        }

    }
    catch {

        Write-Host "Watcher error:"
        Write-Host $_.Exception.Message
    }

    Write-Host ""
    Write-Host "Sleeping for $IntervalSeconds seconds..."

    Start-Sleep -Seconds $IntervalSeconds
}