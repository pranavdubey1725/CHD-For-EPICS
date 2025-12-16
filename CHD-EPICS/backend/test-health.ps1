# Simple Health Check Test
Write-Host "Testing Health Endpoint..." -ForegroundColor Cyan
for ($i = 1; $i -le 20; $i++) {
    try {
        $response = Invoke-RestMethod -Uri "http://localhost:8080/api/health" -Method GET -TimeoutSec 2 -ErrorAction Stop
        Write-Host "`nSUCCESS: Application is running!" -ForegroundColor Green
        Write-Host "Status: $($response.status)" -ForegroundColor Green
        Write-Host "Service: $($response.service)" -ForegroundColor Cyan
        Write-Host "Timestamp: $($response.timestamp)" -ForegroundColor Gray
        exit 0
    }
    catch {
        if ($i -eq 20) {
            Write-Host "`nFAILED: Application not responding" -ForegroundColor Red
            exit 1
        }
        else {
            Write-Host "." -NoNewline -ForegroundColor Gray
            Start-Sleep -Seconds 3
        }
    }
}









