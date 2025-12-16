# ML Service Health Check Test
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "ML Service Health Check" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$mlServiceUrl = "http://localhost:8000"

# Test 1: Health Check
Write-Host "1. Testing ML Service Health Endpoint..." -ForegroundColor Yellow
for ($i = 1; $i -le 20; $i++) {
    try {
        $response = Invoke-RestMethod -Uri "$mlServiceUrl/" -Method GET -TimeoutSec 2 -ErrorAction Stop
        Write-Host "   SUCCESS: ML Service is running!" -ForegroundColor Green
        Write-Host "   Message: $($response.message)" -ForegroundColor Green
        break
    }
    catch {
        if ($i -eq 20) {
            Write-Host "   FAILED: ML Service not responding" -ForegroundColor Red
            Write-Host "   Error: $($_.Exception.Message)" -ForegroundColor Red
            exit 1
        }
        else {
            Write-Host "." -NoNewline -ForegroundColor Gray
            Start-Sleep -Seconds 2
        }
    }
}
Write-Host ""

# Test 2: Predict Endpoint (with test image)
Write-Host "2. Testing Predict Endpoint (without image data - fallback)..." -ForegroundColor Yellow
try {
    # Read test image and convert to base64
    if (Test-Path "test_image.jpg") {
        $imageBytes = [System.IO.File]::ReadAllBytes("test_image.jpg")
        $base64Image = [Convert]::ToBase64String($imageBytes)
        $scanId = [System.Guid]::NewGuid().ToString()
        
        $body = @{
            scan_id    = $scanId
            image_data = $base64Image
        } | ConvertTo-Json
        
        $response = Invoke-RestMethod -Uri "$mlServiceUrl/predict" -Method POST -Body $body -ContentType "application/json" -TimeoutSec 120
        Write-Host "   SUCCESS: Prediction received!" -ForegroundColor Green
        Write-Host "   Scan ID: $($response.scan_id)" -ForegroundColor Cyan
        Write-Host "   Prediction: $($response.prediction)" -ForegroundColor Cyan
        Write-Host "   Confidence: $($response.confidence_score)" -ForegroundColor Cyan
        Write-Host "   Status: $($response.status)" -ForegroundColor Cyan
    }
    else {
        Write-Host "   WARNING: test_image.jpg not found, testing with scan_id only..." -ForegroundColor Yellow
        $body = @{
            scan_id     = "test-123"
            mri_scan_id = 123
        } | ConvertTo-Json
        
        try {
            $response = Invoke-RestMethod -Uri "$mlServiceUrl/predict" -Method POST -Body $body -ContentType "application/json" -TimeoutSec 120
            Write-Host "   SUCCESS: Prediction received (fallback mode)!" -ForegroundColor Green
            Write-Host "   Prediction: $($response.prediction)" -ForegroundColor Cyan
        }
        catch {
            Write-Host "   ERROR: $($_.Exception.Message)" -ForegroundColor Red
        }
    }
}
catch {
    Write-Host "   ERROR: $($_.Exception.Message)" -ForegroundColor Red
}
Write-Host ""

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "ML Service Testing Complete!" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan





