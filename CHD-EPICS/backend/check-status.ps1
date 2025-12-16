Start-Sleep -Seconds 3
$java = Get-Process -Name java -ErrorAction SilentlyContinue
$port = Test-NetConnection -ComputerName localhost -Port 8080 -InformationLevel Quiet -WarningAction SilentlyContinue

Write-Host "`n=== APPLICATION STATUS ===" -ForegroundColor Cyan
if ($java) { 
    Write-Host "Java process running" -ForegroundColor Green 
}
else { 
    Write-Host "Java process not found" -ForegroundColor Red 
}

if ($port) { 
    Write-Host "Port 8080 is open" -ForegroundColor Green
    Write-Host "APPLICATION IS RUNNING!" -ForegroundColor Green
    Write-Host "`nTesting health endpoint..." -ForegroundColor Yellow
    try { 
        $h = Invoke-RestMethod -Uri "http://localhost:8080/api/health" -Method GET -TimeoutSec 2
        Write-Host "Health check PASSED! Status: $($h.status)" -ForegroundColor Green
    }
    catch { 
        Write-Host "Health endpoint error: $($_.Exception.Message)" -ForegroundColor Yellow
    }
}
else { 
    Write-Host "Port 8080 not open" -ForegroundColor Red
}
