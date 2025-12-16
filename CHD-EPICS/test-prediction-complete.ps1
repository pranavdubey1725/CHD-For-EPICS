# Complete End-to-End Prediction Test Script
# Tests: Login -> Create Patient -> Upload Scan -> Predict -> View Results

$baseUrl = "http://localhost:8080/api"
$accessToken = $null
$patientId = $null
$scanId = $null
$resultId = $null

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Complete Prediction Test" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Check prerequisites
Write-Host "Checking prerequisites..." -ForegroundColor Yellow
try {
    $backend = Invoke-RestMethod -Uri "$baseUrl/health" -Method Get -TimeoutSec 5
    Write-Host "  ✅ Backend: $($backend.status)" -ForegroundColor Green
} catch {
    Write-Host "  ❌ Backend not running!" -ForegroundColor Red
    exit 1
}

try {
    $ml = Invoke-RestMethod -Uri "http://localhost:8000/" -Method Get -TimeoutSec 5
    Write-Host "  ✅ ML Service: Running" -ForegroundColor Green
} catch {
    Write-Host "  ❌ ML Service not running!" -ForegroundColor Red
    exit 1
}

# Check MinIO
try {
    $minio = Invoke-WebRequest -Uri "http://localhost:9000/minio/health/live" -Method Get -TimeoutSec 3 -ErrorAction SilentlyContinue
    Write-Host "  ✅ MinIO: Running" -ForegroundColor Green
} catch {
    Write-Host "  ⚠️  MinIO not running (scan upload will fail)" -ForegroundColor Yellow
    Write-Host "     Start MinIO or the upload step will fail" -ForegroundColor Gray
}
Write-Host ""

# Step 1: Login/Register
Write-Host "Step 1: Authentication" -ForegroundColor Cyan
$testEmail = "prediction-test-$(Get-Random -Maximum 99999)@example.com"
$testPassword = "Test123!"

try {
    # Try registration first
    $regBody = @{
        email = $testEmail
        password = $testPassword
        fullName = "Dr. Prediction Test"
        phone = "+1234567890"
    } | ConvertTo-Json
    
    try {
        $regResponse = Invoke-RestMethod -Uri "$baseUrl/auth/register" -Method POST -Body $regBody -ContentType "application/json"
        Write-Host "  ✅ Registered: $testEmail" -ForegroundColor Green
    } catch {
        if ($_.Exception.Response.StatusCode.value__ -eq 409) {
            Write-Host "  ℹ️  User exists, using existing account" -ForegroundColor Yellow
            $testEmail = "mltest@example.com"
            $testPassword = "TestML123!"
        } else {
            throw
        }
    }
    
    # Login
    $loginBody = @{
        email = $testEmail
        password = $testPassword
    } | ConvertTo-Json
    
    $loginResponse = Invoke-RestMethod -Uri "$baseUrl/auth/login" -Method POST -Body $loginBody -ContentType "application/json"
    $accessToken = $loginResponse.data.accessToken
    Write-Host "  ✅ Logged in successfully" -ForegroundColor Green
    Write-Host "     Token: $($accessToken.Substring(0,30))..." -ForegroundColor Gray
} catch {
    Write-Host "  ❌ Authentication failed: $_" -ForegroundColor Red
    exit 1
}
Write-Host ""

# Step 2: Create Patient
Write-Host "Step 2: Create Patient" -ForegroundColor Cyan
try {
    $headers = @{"Authorization" = "Bearer $accessToken"}
    $patientBody = @{
        patientData = @{
            name = "Test Patient for Prediction"
            age = 45
            gender = "M"
            dateOfBirth = "1979-01-15"
            medicalHistory = "Cardiac evaluation"
            diagnosis = "CHD screening"
            notes = "Testing ML prediction integration"
        }
    } | ConvertTo-Json -Depth 10
    
    $patientResponse = Invoke-RestMethod -Uri "$baseUrl/patients" -Method POST -Body $patientBody -ContentType "application/json" -Headers $headers
    $patientId = $patientResponse.data.patientId
    Write-Host "  ✅ Patient created: $patientId" -ForegroundColor Green
} catch {
    Write-Host "  ❌ Patient creation failed: $_" -ForegroundColor Red
    if ($_.ErrorDetails) {
        Write-Host "     Details: $($_.ErrorDetails.Message)" -ForegroundColor Yellow
    }
    exit 1
}
Write-Host ""

# Step 3: Upload Scan
Write-Host "Step 3: Upload Scan Image" -ForegroundColor Cyan

# Find test image
$testImagePath = $null
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$possiblePaths = @(
    "$scriptDir\ml-service\test_image.jpg",
    "$PSScriptRoot\ml-service\test_image.jpg",
    "ml-service\test_image.jpg",
    "CHD-EPICS\ml-service\test_image.jpg",
    "C:\Users\EKTA\OneDrive\Desktop\JavaSpringbootBackend\CHD-EPICS\ml-service\test_image.jpg"
)

foreach ($path in $possiblePaths) {
    if (Test-Path $path) {
        $testImagePath = $path
        break
    }
}

if (-not $testImagePath) {
    Write-Host "  ⚠️  Test image not found in standard locations" -ForegroundColor Yellow
    Write-Host "     Please provide path to an image file:" -ForegroundColor Yellow
    $testImagePath = Read-Host "     Image file path"
    
    if (-not (Test-Path $testImagePath)) {
        Write-Host "  ❌ Image file not found: $testImagePath" -ForegroundColor Red
        Write-Host "     You can use any JPG or PNG image file" -ForegroundColor Yellow
        exit 1
    }
}

Write-Host "  Using image: $testImagePath" -ForegroundColor Gray
$fileInfo = Get-Item $testImagePath
Write-Host "  Image size: $([math]::Round($fileInfo.Length/1KB, 2)) KB" -ForegroundColor Gray

try {
    # Create multipart form data
    $boundary = [System.Guid]::NewGuid().ToString()
    $LF = "
"
    $fileBytes = [System.IO.File]::ReadAllBytes($testImagePath)
    $fileName = Split-Path $testImagePath -Leaf
    
    $bodyBuilder = New-Object System.Text.StringBuilder
    $bodyBuilder.Append("--$boundary$LF") | Out-Null
    $bodyBuilder.Append("Content-Disposition: form-data; name=`"file`"; filename=`"$fileName`"$LF") | Out-Null
    $bodyBuilder.Append("Content-Type: image/jpeg$LF$LF") | Out-Null
    $bodyBuilder.Append([System.Text.Encoding]::GetEncoding("ISO-8859-1").GetString($fileBytes)) | Out-Null
    $bodyBuilder.Append("$LF--$boundary--$LF") | Out-Null
    
    $bodyBytes = [System.Text.Encoding]::GetEncoding("ISO-8859-1").GetBytes($bodyBuilder.ToString())
    $headers["Content-Type"] = "multipart/form-data; boundary=$boundary"
    
    Write-Host "  Uploading to backend..." -ForegroundColor Gray
    $uploadResponse = Invoke-RestMethod -Uri "$baseUrl/scans/upload?patientId=$patientId" -Method POST -Body $bodyBytes -Headers $headers -TimeoutSec 30
    $scanId = $uploadResponse.data.scanId
    Write-Host "  ✅ Scan uploaded successfully!" -ForegroundColor Green
    Write-Host "     Scan ID: $scanId" -ForegroundColor Cyan
} catch {
    Write-Host "  ❌ Scan upload failed: $_" -ForegroundColor Red
    if ($_.Exception.Response) {
        $reader = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
        $responseBody = $reader.ReadToEnd()
        Write-Host "     Error details: $responseBody" -ForegroundColor Yellow
    }
    if ($_.Exception.Message -match "MinIO" -or $_.Exception.Message -match "9000") {
        Write-Host "     ⚠️  This error suggests MinIO is not running" -ForegroundColor Yellow
        Write-Host "     MinIO is required for scan storage" -ForegroundColor Yellow
    }
    exit 1
}
Write-Host ""

# Step 4: Request Prediction
if ($scanId) {
    Write-Host "Step 4: Request ML Prediction" -ForegroundColor Cyan
    try {
        $predictBody = @{
            modelVersion = "v1.0"
            threshold = 0.5
        } | ConvertTo-Json
        
        Write-Host "  Calling ML service for scan: $scanId..." -ForegroundColor Gray
        Write-Host "  (This may take 10-30 seconds)" -ForegroundColor Gray
        
        $predictResponse = Invoke-RestMethod -Uri "$baseUrl/ml/predict/$scanId" -Method POST -Body $predictBody -ContentType "application/json" -Headers $headers -TimeoutSec 120
        
        $resultId = $predictResponse.data.resultId
        Write-Host "  ✅✅✅ PREDICTION SUCCESSFUL! ✅✅✅" -ForegroundColor Green
        Write-Host ""
        Write-Host "  Results:" -ForegroundColor Cyan
        Write-Host "    Result ID: $resultId" -ForegroundColor White
        Write-Host "    Prediction: $($predictResponse.data.predictedLabel)" -ForegroundColor Yellow
        Write-Host "    Confidence: $($predictResponse.data.confidenceScore)" -ForegroundColor Yellow
        Write-Host "    Model Version: $($predictResponse.data.modelVersion)" -ForegroundColor White
        Write-Host ""
        Write-Host "  Class Probabilities:" -ForegroundColor Cyan
        $predictResponse.data.classProbabilities.PSObject.Properties | ForEach-Object {
            $percentage = [math]::Round([double]$_.Value * 100, 2)
            $percentStr = "$percentage%"
            Write-Host "    $($_.Name): $($_.Value) ($percentStr)" -ForegroundColor White
        }
    } catch {
        Write-Host "  ❌ Prediction failed: $_" -ForegroundColor Red
        if ($_.Exception.Response) {
            $reader = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
            $responseBody = $reader.ReadToEnd()
            Write-Host "     Error details: $responseBody" -ForegroundColor Yellow
        }
    }
    Write-Host ""
}

# Step 5: Get Result Details
if ($resultId) {
    Write-Host "Step 5: Retrieve Prediction Result" -ForegroundColor Cyan
    try {
        $resultResponse = Invoke-RestMethod -Uri "$baseUrl/ml/results/$resultId" -Method GET -Headers $headers
        Write-Host "  ✅ Result retrieved" -ForegroundColor Green
        Write-Host "     Created at: $($resultResponse.data.createdAt)" -ForegroundColor Gray
    } catch {
        Write-Host "  ⚠️  Could not retrieve result details: $_" -ForegroundColor Yellow
    }
    Write-Host ""
}

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Test Complete!" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

