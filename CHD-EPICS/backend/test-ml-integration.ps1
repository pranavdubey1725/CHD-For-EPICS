# Complete ML Integration Test Script
# This script tests the full flow: Register -> Login -> Create Patient -> Upload Scan -> Predict -> Get Result

$baseUrl = "http://localhost:8080/api"
$accessToken = $null
$patientId = $null
$scanId = $null
$resultId = $null

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "ML Integration Testing" -ForegroundColor Cyan  
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Wait for backend to be ready
Write-Host "Waiting for backend to be ready..." -ForegroundColor Yellow
for ($i = 1; $i -le 30; $i++) {
    try {
        $response = Invoke-RestMethod -Uri "$baseUrl/health" -Method GET -TimeoutSec 2 -ErrorAction Stop
        Write-Host "   Backend is ready!" -ForegroundColor Green
        break
    }
    catch {
        if ($i -eq 30) {
            Write-Host "   FAILED: Backend not responding after 60 seconds" -ForegroundColor Red
            exit 1
        }
        Write-Host "." -NoNewline -ForegroundColor Gray
        Start-Sleep -Seconds 2
    }
}
Write-Host ""

# Step 1: Register
Write-Host "1. Register Doctor..." -ForegroundColor Yellow
$randomEmail = "mltest$((Get-Random -Maximum 99999))@example.com"
try {
    $body = "{`"email`":`"$randomEmail`",`"password`":`"TestML123!`",`"fullName`":`"Dr. ML Test`",`"phone`":`"+1234567890`"}"
    $response = Invoke-RestMethod -Uri "$baseUrl/auth/register" -Method POST -Body $body -ContentType "application/json"
    Write-Host "   SUCCESS: Registered with email: $randomEmail" -ForegroundColor Green
}
catch {
    $statusCode = $_.Exception.Response.StatusCode.value__
    if ($statusCode -eq 409) {
        Write-Host "   INFO: User already exists, trying login..." -ForegroundColor Yellow
        $randomEmail = "mltest@example.com"
    }
    elseif ($statusCode -eq 400) {
        $reader = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
        $responseBody = $reader.ReadToEnd()
        Write-Host "   WARNING: Registration failed: $responseBody" -ForegroundColor Yellow
        Write-Host "   Attempting to use existing user..." -ForegroundColor Yellow
        $randomEmail = "mltest@example.com"
    }
    else {
        Write-Host "   ERROR: $($_.Exception.Message)" -ForegroundColor Red
        exit 1
    }
}
Write-Host ""

# Step 2: Login
Write-Host "2. Login..." -ForegroundColor Yellow
try {
    $body = "{`"email`":`"$randomEmail`",`"password`":`"TestML123!`"}"
    $response = Invoke-RestMethod -Uri "$baseUrl/auth/login" -Method POST -Body $body -ContentType "application/json"
    $accessToken = $response.data.accessToken
    Write-Host "   SUCCESS: Logged in as $randomEmail" -ForegroundColor Green
    Write-Host "   Token: $($accessToken.Substring(0,30))..." -ForegroundColor Gray
}
catch {
    Write-Host "   ERROR: Login failed - $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "   If user doesn't exist, registration may have failed. Trying default..." -ForegroundColor Yellow
    try {
        $body = '{"email":"mltest@example.com","password":"TestML123!"}'
        $response = Invoke-RestMethod -Uri "$baseUrl/auth/login" -Method POST -Body $body -ContentType "application/json"
        $accessToken = $response.data.accessToken
        $randomEmail = "mltest@example.com"
        Write-Host "   SUCCESS: Logged in with default user" -ForegroundColor Green
    }
    catch {
        Write-Host "   ERROR: Cannot login. Please register a user first." -ForegroundColor Red
        exit 1
    }
}
Write-Host ""

# Step 3: Create Patient
Write-Host "3. Create Patient..." -ForegroundColor Yellow
try {
    $body = '{"patientData":{"name":"Test Patient ML","age":50,"gender":"M","dateOfBirth":"1974-01-15","medicalHistory":"Cardiac evaluation needed","diagnosis":"CHD screening","notes":"ML integration test"}}'
    $headers = @{"Authorization" = "Bearer $accessToken" }
    $response = Invoke-RestMethod -Uri "$baseUrl/patients" -Method POST -Body $body -ContentType "application/json" -Headers $headers
    $patientId = $response.data.patientId
    Write-Host "   SUCCESS: Patient created - ID: $patientId" -ForegroundColor Green
}
catch {
    Write-Host "   ERROR: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}
Write-Host ""

# Step 4: Upload Scan (use test_image.jpg from ML service folder)
Write-Host "4. Upload ECG Scan..." -ForegroundColor Yellow
try {
    # Use the test_image.jpg from the ML service folder
    $scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
    $testImagePath = Join-Path (Split-Path -Parent $scriptDir) "ml-service\test_image.jpg"
    
    if (-not (Test-Path $testImagePath)) {
        Write-Host "   ERROR: Test image not found at: $testImagePath" -ForegroundColor Red
        throw "Test image file not found"
    }
    
    Write-Host "   Using test image: $testImagePath" -ForegroundColor Gray
    $fileInfo = Get-Item $testImagePath
    Write-Host "   Image size: $($fileInfo.Length) bytes" -ForegroundColor Gray
    
    # Use Invoke-WebRequest with -Form for proper multipart/form-data handling
    $headers = @{
        "Authorization" = "Bearer $accessToken"
    }
    
    # Create multipart form data
    $boundary = [System.Guid]::NewGuid().ToString()
    $LF = "`r`n"
    $fileBytes = [System.IO.File]::ReadAllBytes($testImagePath)
    
    # Build multipart body manually with correct encoding
    $bodyBuilder = New-Object System.Text.StringBuilder
    
    # File field
    $bodyBuilder.Append("--$boundary$LF") | Out-Null
    $bodyBuilder.Append("Content-Disposition: form-data; name=`"file`"; filename=`"test_image.jpg`"$LF") | Out-Null
    $bodyBuilder.Append("Content-Type: image/jpeg$LF$LF") | Out-Null
    $bodyBuilder.Append([System.Text.Encoding]::GetEncoding("ISO-8859-1").GetString($fileBytes)) | Out-Null
    $bodyBuilder.Append("$LF--$boundary--$LF") | Out-Null
    
    $bodyString = $bodyBuilder.ToString()
    $bodyBytes = [System.Text.Encoding]::GetEncoding("ISO-8859-1").GetBytes($bodyString)
    
    $headers["Content-Type"] = "multipart/form-data; boundary=$boundary"
    
    Write-Host "   Uploading scan to backend..." -ForegroundColor Gray
    $response = Invoke-RestMethod -Uri "$baseUrl/scans/upload?patientId=$patientId" -Method POST -Body $bodyBytes -Headers $headers
    $scanId = $response.data.scanId
    Write-Host "   SUCCESS: Scan uploaded - ID: $scanId" -ForegroundColor Green
}
catch {
    Write-Host "   ERROR: $($_.Exception.Message)" -ForegroundColor Red
    if ($_.Exception.Response) {
        $reader = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
        $responseBody = $reader.ReadToEnd()
        Write-Host "   Response: $responseBody" -ForegroundColor Red
    }
    # Continue anyway for testing
}
Write-Host ""

# Step 5: Predict (ML Service Call)
if ($scanId) {
    Write-Host "5. Request ML Prediction..." -ForegroundColor Yellow
    try {
        $headers = @{"Authorization" = "Bearer $accessToken" }
        $body = '{"modelVersion":"v1.0","threshold":0.5}'
        Write-Host "   Calling ML service for scan: $scanId..." -ForegroundColor Gray
        $response = Invoke-RestMethod -Uri "$baseUrl/ml/predict/$scanId" -Method POST -Body $body -ContentType "application/json" -Headers $headers -TimeoutSec 120
        $resultId = $response.data.resultId
        Write-Host "   SUCCESS: Prediction completed!" -ForegroundColor Green
        Write-Host "   Result ID: $resultId" -ForegroundColor Cyan
        Write-Host "   Prediction: $($response.data.predictedLabel)" -ForegroundColor Cyan
        Write-Host "   Confidence: $($response.data.confidenceScore)" -ForegroundColor Cyan
        Write-Host "   Status: COMPLETED" -ForegroundColor Green
    }
    catch {
        Write-Host "   ERROR: $($_.Exception.Message)" -ForegroundColor Red
        if ($_.Exception.Response) {
            $reader = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
            $responseBody = $reader.ReadToEnd()
            Write-Host "   Response: $responseBody" -ForegroundColor Red
        }
    }
    Write-Host ""
}

# Step 6: Get Prediction Result
if ($resultId) {
    Write-Host "6. Get Prediction Result..." -ForegroundColor Yellow
    try {
        $headers = @{"Authorization" = "Bearer $accessToken" }
        $response = Invoke-RestMethod -Uri "$baseUrl/ml/results/$resultId" -Method GET -Headers $headers
        Write-Host "   SUCCESS: Result retrieved!" -ForegroundColor Green
        Write-Host "   Prediction: $($response.data.predictedLabel)" -ForegroundColor Cyan
        Write-Host "   Confidence: $($response.data.confidenceScore)" -ForegroundColor Cyan
        Write-Host "   Model Version: $($response.data.modelVersion)" -ForegroundColor Cyan
    }
    catch {
        Write-Host "   ERROR: $($_.Exception.Message)" -ForegroundColor Red
    }
    Write-Host ""
}

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "ML Integration Testing Complete!" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan# Complete ML Integration Test Script
# This script tests the full flow: Register -> Login -> Create Patient -> Upload Scan -> Predict -> Get Result

$baseUrl = "http://localhost:8080/api"
$accessToken = $null
$patientId = $null
$scanId = $null
$resultId = $null

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "ML Integration Testing" -ForegroundColor Cyan  
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Wait for backend to be ready
Write-Host "Waiting for backend to be ready..." -ForegroundColor Yellow
for ($i = 1; $i -le 30; $i++) {
    try {
        $response = Invoke-RestMethod -Uri "$baseUrl/health" -Method GET -TimeoutSec 2 -ErrorAction Stop
        Write-Host "   Backend is ready!" -ForegroundColor Green
        break
    }
    catch {
        if ($i -eq 30) {
            Write-Host "   FAILED: Backend not responding after 60 seconds" -ForegroundColor Red
            exit 1
        }
        Write-Host "." -NoNewline -ForegroundColor Gray
        Start-Sleep -Seconds 2
    }
}
Write-Host ""

# Step 1: Register
Write-Host "1. Register Doctor..." -ForegroundColor Yellow
try {
    $body = '{"email":"mltest@example.com","password":"TestML123!","fullName":"Dr. ML Test","phone":"+1234567890"}'
    $response = Invoke-RestMethod -Uri "$baseUrl/auth/register" -Method POST -Body $body -ContentType "application/json"
    Write-Host "   SUCCESS: Registered" -ForegroundColor Green
}
catch {
    $errorResponse = $_.Exception.Response
    if ($errorResponse.StatusCode -eq 409) {
        Write-Host "   INFO: User already exists, continuing..." -ForegroundColor Yellow
    }
    else {
        Write-Host "   ERROR: $($_.Exception.Message)" -ForegroundColor Red
        exit 1
    }
}
Write-Host ""

# Step 2: Login
Write-Host "2. Login..." -ForegroundColor Yellow
try {
    $body = '{"email":"mltest@example.com","password":"TestML123!"}'
    $response = Invoke-RestMethod -Uri "$baseUrl/auth/login" -Method POST -Body $body -ContentType "application/json"
    $accessToken = $response.data.accessToken
    Write-Host "   SUCCESS: Logged in" -ForegroundColor Green
    Write-Host "   Token: $($accessToken.Substring(0,30))..." -ForegroundColor Gray
}
catch {
    Write-Host "   ERROR: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}
Write-Host ""

# Step 3: Create Patient
Write-Host "3. Create Patient..." -ForegroundColor Yellow
try {
    $body = '{"patientData":{"name":"Test Patient ML","age":50,"gender":"M","dateOfBirth":"1974-01-15","medicalHistory":"Cardiac evaluation needed","diagnosis":"CHD screening","notes":"ML integration test"}}'
    $headers = @{"Authorization" = "Bearer $accessToken" }
    $response = Invoke-RestMethod -Uri "$baseUrl/patients" -Method POST -Body $body -ContentType "application/json" -Headers $headers
    $patientId = $response.data.patientId
    Write-Host "   SUCCESS: Patient created - ID: $patientId" -ForegroundColor Green
}
catch {
    Write-Host "   ERROR: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}
Write-Host ""

# Step 4: Upload Scan (create a dummy image file for testing)
Write-Host "4. Upload ECG Scan..." -ForegroundColor Yellow
try {
    # Create a simple test image (1x1 pixel PNG) for testing
    $testImagePath = "$env:TEMP\test_ecg_scan.png"
    if (-not (Test-Path $testImagePath)) {
        # Create a minimal PNG file (base64 encoded 1x1 transparent PNG)
        $pngBase64 = "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg=="
        [System.IO.File]::WriteAllBytes($testImagePath, [Convert]::FromBase64String($pngBase64))
    }
    
    $boundary = [System.Guid]::NewGuid().ToString()
    $fileContent = [System.IO.File]::ReadAllBytes($testImagePath)
    $fileName = "test_ecg_scan.png"
    
    $bodyLines = @()
    $bodyLines += "--$boundary"
    $bodyLines += "Content-Disposition: form-data; name=`"file`"; filename=`"$fileName`""
    $bodyLines += "Content-Type: image/png"
    $bodyLines += ""
    $bodyText = $bodyLines -join "`r`n"
    
    $bodyBytes = [System.Text.Encoding]::ASCII.GetBytes($bodyText)
    $bodyBytes += [System.Text.Encoding]::GetEncoding("ISO-8859-1").GetBytes("`r`n")
    $bodyBytes += $fileContent
    $bodyBytes += [System.Text.Encoding]::ASCII.GetBytes("`r`n--$boundary--`r`n")
    
    $headers = @{
        "Authorization" = "Bearer $accessToken"
        "Content-Type"  = "multipart/form-data; boundary=$boundary"
    }
    
    $response = Invoke-RestMethod -Uri "$baseUrl/scans/upload?patientId=$patientId" -Method POST -Body $bodyBytes -Headers $headers
    $scanId = $response.data.scanId
    Write-Host "   SUCCESS: Scan uploaded - ID: $scanId" -ForegroundColor Green
}
catch {
    Write-Host "   ERROR: $($_.Exception.Message)" -ForegroundColor Red
    if ($_.Exception.Response) {
        $reader = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
        $responseBody = $reader.ReadToEnd()
        Write-Host "   Response: $responseBody" -ForegroundColor Red
    }
    # Continue anyway for testing
}
Write-Host ""

# Step 5: Predict (ML Service Call)
if ($scanId) {
    Write-Host "5. Request ML Prediction..." -ForegroundColor Yellow
    try {
        $headers = @{"Authorization" = "Bearer $accessToken" }
        $body = '{"modelVersion":"v1.0","threshold":0.5}'
        Write-Host "   Calling ML service for scan: $scanId..." -ForegroundColor Gray
        $response = Invoke-RestMethod -Uri "$baseUrl/ml/predict/$scanId" -Method POST -Body $body -ContentType "application/json" -Headers $headers -TimeoutSec 120
        $resultId = $response.data.resultId
        Write-Host "   SUCCESS: Prediction completed!" -ForegroundColor Green
        Write-Host "   Result ID: $resultId" -ForegroundColor Cyan
        Write-Host "   Prediction: $($response.data.predictedLabel)" -ForegroundColor Cyan
        Write-Host "   Confidence: $($response.data.confidenceScore)" -ForegroundColor Cyan
        Write-Host "   Status: COMPLETED" -ForegroundColor Green
    }
    catch {
        Write-Host "   ERROR: $($_.Exception.Message)" -ForegroundColor Red
        if ($_.Exception.Response) {
            $reader = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
            $responseBody = $reader.ReadToEnd()
            Write-Host "   Response: $responseBody" -ForegroundColor Red
        }
    }
    Write-Host ""
}

# Step 6: Get Prediction Result
if ($resultId) {
    Write-Host "6. Get Prediction Result..." -ForegroundColor Yellow
    try {
        $headers = @{"Authorization" = "Bearer $accessToken" }
        $response = Invoke-RestMethod -Uri "$baseUrl/ml/results/$resultId" -Method GET -Headers $headers
        Write-Host "   SUCCESS: Result retrieved!" -ForegroundColor Green
        Write-Host "   Prediction: $($response.data.predictedLabel)" -ForegroundColor Cyan
        Write-Host "   Confidence: $($response.data.confidenceScore)" -ForegroundColor Cyan
        Write-Host "   Model Version: $($response.data.modelVersion)" -ForegroundColor Cyan
    }
    catch {
        Write-Host "   ERROR: $($_.Exception.Message)" -ForegroundColor Red
    }
    Write-Host ""
}

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "ML Integration Testing Complete!" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

