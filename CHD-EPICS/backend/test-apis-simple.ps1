# Simple API Testing Script
$baseUrl = "http://localhost:8080/api"
$accessToken = $null
$refreshToken = $null
$patientId = $null

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "CHD-EPICS API Testing" -ForegroundColor Cyan  
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Test 1: Register
Write-Host "1. Register Doctor..." -ForegroundColor Yellow
try {
    $body = '{"email":"doctor@test.com","password":"Test123456!","fullName":"Dr. Test User","phone":"+1234567890"}'
    $response = Invoke-RestMethod -Uri "$baseUrl/auth/register" -Method POST -Body $body -ContentType "application/json"
    Write-Host "   SUCCESS: Registered" -ForegroundColor Green
} catch {
    Write-Host "   ERROR: $($_.Exception.Message)" -ForegroundColor Red
}
Write-Host ""

# Test 2: Login
Write-Host "2. Login..." -ForegroundColor Yellow
try {
    $body = '{"email":"doctor@test.com","password":"Test123456!"}'
    $response = Invoke-RestMethod -Uri "$baseUrl/auth/login" -Method POST -Body $body -ContentType "application/json"
    $accessToken = $response.data.accessToken
    $refreshToken = $response.data.refreshToken
    Write-Host "   SUCCESS: Logged in" -ForegroundColor Green
    Write-Host "   Token: $($accessToken.Substring(0,30))..." -ForegroundColor Gray
} catch {
    Write-Host "   ERROR: $($_.Exception.Message)" -ForegroundColor Red
    exit
}
Write-Host ""

# Test 3: Get Current User
Write-Host "3. Get Current User..." -ForegroundColor Yellow
try {
    $headers = @{"Authorization" = "Bearer $accessToken"}
    $response = Invoke-RestMethod -Uri "$baseUrl/auth/me" -Method GET -Headers $headers
    Write-Host "   SUCCESS: User: $($response.data.fullName)" -ForegroundColor Green
} catch {
    Write-Host "   ERROR: $($_.Exception.Message)" -ForegroundColor Red
}
Write-Host ""

# Test 4: Create Patient
Write-Host "4. Create Patient..." -ForegroundColor Yellow
try {
    $body = '{"patientData":{"name":"John Doe","age":45,"gender":"M","dateOfBirth":"1979-05-20","medicalHistory":"Hypertension","diagnosis":"Suspected CHD","notes":"Test"}}'
    $headers = @{"Authorization" = "Bearer $accessToken"}
    $response = Invoke-RestMethod -Uri "$baseUrl/patients" -Method POST -Body $body -ContentType "application/json" -Headers $headers
    $patientId = $response.data.patientId
    Write-Host "   SUCCESS: Patient ID: $patientId" -ForegroundColor Green
} catch {
    Write-Host "   ERROR: $($_.Exception.Message)" -ForegroundColor Red
}
Write-Host ""

# Test 5: Get Patient
if ($patientId) {
    Write-Host "5. Get Patient..." -ForegroundColor Yellow
    try {
        $headers = @{"Authorization" = "Bearer $accessToken"}
        $response = Invoke-RestMethod -Uri "$baseUrl/patients/$patientId" -Method GET -Headers $headers
        Write-Host "   SUCCESS: Patient Name: $($response.data.patientData.name)" -ForegroundColor Green
    } catch {
        Write-Host "   ERROR: $($_.Exception.Message)" -ForegroundColor Red
    }
    Write-Host ""
}

# Test 6: List Patients
Write-Host "6. List Patients..." -ForegroundColor Yellow
try {
    $headers = @{"Authorization" = "Bearer $accessToken"}
    $response = Invoke-RestMethod -Uri "$baseUrl/patients" -Method GET -Headers $headers
    Write-Host "   SUCCESS: Total: $($response.data.pagination.totalElements)" -ForegroundColor Green
} catch {
    Write-Host "   ERROR: $($_.Exception.Message)" -ForegroundColor Red
}
Write-Host ""

# Test 7: Refresh Token
Write-Host "7. Refresh Token..." -ForegroundColor Yellow
try {
    $body = "{`"refreshToken`":`"$refreshToken`"}"
    $response = Invoke-RestMethod -Uri "$baseUrl/auth/refresh" -Method POST -Body $body -ContentType "application/json"
    $accessToken = $response.data.accessToken
    Write-Host "   SUCCESS: New token received" -ForegroundColor Green
} catch {
    Write-Host "   ERROR: $($_.Exception.Message)" -ForegroundColor Red
}
Write-Host ""

# Test 8: Logout
Write-Host "8. Logout..." -ForegroundColor Yellow
try {
    $headers = @{"Authorization" = "Bearer $accessToken"}
    Invoke-RestMethod -Uri "$baseUrl/auth/logout" -Method POST -Headers $headers | Out-Null
    Write-Host "   SUCCESS: Logged out" -ForegroundColor Green
} catch {
    Write-Host "   ERROR: $($_.Exception.Message)" -ForegroundColor Red
}
Write-Host ""

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Testing Complete!" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

