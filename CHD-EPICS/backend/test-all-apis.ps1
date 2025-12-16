# Comprehensive API Test Script
# Tests all APIs and creates dummy data as needed

$baseUrl = "http://localhost:8080/api"
$global:accessToken = $null
$global:refreshToken = $null
$global:doctor1Id = $null
$global:doctor2Id = $null
$global:patientId = $null
$global:scanId = $null

function Write-TestHeader {
    param([string]$TestName)
    Write-Host "`n========================================" -ForegroundColor Cyan
    Write-Host "TEST: $TestName" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
}

function Write-TestResult {
    param([bool]$Success, [string]$Message, [object]$Data = $null)
    if ($Success) {
        Write-Host "[PASS] $Message" -ForegroundColor Green
        if ($Data) {
            Write-Host "      Response: $($Data | ConvertTo-Json -Depth 2 -Compress)" -ForegroundColor Gray
        }
    }
    else {
        Write-Host "[FAIL] $Message" -ForegroundColor Red
        if ($Data) {
            Write-Host "      Error: $($Data | ConvertTo-Json -Depth 2 -Compress)" -ForegroundColor Red
        }
    }
}

function Invoke-ApiRequest {
    param(
        [string]$Method,
        [string]$Endpoint,
        [object]$Body = $null,
        [hashtable]$Headers = @{},
        [bool]$RequireAuth = $false
    )
    
    $url = "$baseUrl$Endpoint"
    $headers = @{
        "Content-Type" = "application/json"
    }
    
    if ($RequireAuth -and $global:accessToken) {
        $headers["Authorization"] = "Bearer $global:accessToken"
    }
    
    # Copy additional headers
    if ($Headers.Count -gt 0) {
        $headerKeys = @($Headers.Keys)
        foreach ($key in $headerKeys) {
            $headers[$key] = $Headers[$key]
        }
    }
    
    try {
        $params = @{
            Uri        = $url
            Method     = $Method
            Headers    = $headers
            TimeoutSec = 10
        }
        
        if ($Body) {
            $params["Body"] = ($Body | ConvertTo-Json -Depth 10)
        }
        
        $response = Invoke-RestMethod @params
        return @{ Success = $true; Data = $response }
    }
    catch {
        $errorResponse = $null
        $statusCode = $null
        $errorMessage = $_.Exception.Message
        
        try {
            if ($_.ErrorDetails.Message) {
                $errorResponse = $_.ErrorDetails.Message | ConvertFrom-Json
            }
            if ($_.Exception.Response) {
                $statusCode = $_.Exception.Response.StatusCode.value__
                $reader = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
                $responseBody = $reader.ReadToEnd()
                $reader.Close()
                try {
                    $errorResponse = $responseBody | ConvertFrom-Json
                }
                catch {
                    $errorMessage = $responseBody
                }
            }
        }
        catch { }
        
        return @{ 
            Success    = $false
            StatusCode = $statusCode
            Error      = $errorResponse
            Message    = $errorMessage
            RawError   = $_.Exception
        }
    }
}

# Check if application is running
Write-Host "`n=== CHECKING APPLICATION STATUS ===" -ForegroundColor Yellow
$port = Test-NetConnection -ComputerName localhost -Port 8080 -InformationLevel Quiet -WarningAction SilentlyContinue
if (-not $port) {
    Write-Host "[ERROR] Application is not running on port 8080!" -ForegroundColor Red
    Write-Host "Please start the application first." -ForegroundColor Yellow
    exit 1
}
Write-Host "[OK] Application is running" -ForegroundColor Green

# Test Health Endpoint
Write-TestHeader "Health Check"
$result = Invoke-ApiRequest -Method "GET" -Endpoint "/health"
Write-TestResult $result.Success "Health check" $result.Data

# ============================================
# AUTHENTICATION APIs
# ============================================

# 1. Register Doctor 1
Write-TestHeader "Register Doctor 1"
$registerBody = @{
    email    = "doctor1@test.com"
    password = "Password123!"
    fullName = "Dr. John Smith"
    phone    = "+1234567890"
}
$result = Invoke-ApiRequest -Method "POST" -Endpoint "/auth/register" -Body $registerBody
if ($result.Success) {
    $global:doctor1Id = $result.Data.data.doctorId
    Write-TestResult $true "Doctor 1 registered" $result.Data
}
else {
    Write-TestResult $false "Doctor 1 registration failed" $result
}

# 2. Register Doctor 2
Write-TestHeader "Register Doctor 2"
$registerBody2 = @{
    email    = "doctor2@test.com"
    password = "Password123!"
    fullName = "Dr. Jane Doe"
    phone    = "+0987654321"
}
$result = Invoke-ApiRequest -Method "POST" -Endpoint "/auth/register" -Body $registerBody2
if ($result.Success) {
    $global:doctor2Id = $result.Data.data.doctorId
    Write-TestResult $true "Doctor 2 registered" $result.Data
}
else {
    Write-TestResult $false "Doctor 2 registration failed" $result
}

# 3. Login Doctor 1
Write-TestHeader "Login Doctor 1"
$loginBody = @{
    email    = "doctor1@test.com"
    password = "Password123!"
}
$result = Invoke-ApiRequest -Method "POST" -Endpoint "/auth/login" -Body $loginBody
if ($result.Success) {
    $global:accessToken = $result.Data.data.accessToken
    $global:refreshToken = $result.Data.data.refreshToken
    Write-TestResult $true "Doctor 1 logged in" $result.Data
}
else {
    Write-TestResult $false "Doctor 1 login failed" $result
    Write-Host "[ERROR] Cannot continue without authentication token!" -ForegroundColor Red
    exit 1
}

# 4. Get Current User (Me)
Write-TestHeader "Get Current User"
$result = Invoke-ApiRequest -Method "GET" -Endpoint "/auth/me" -RequireAuth $true
Write-TestResult $result.Success "Get current user" $result.Data

# 5. Refresh Token
Write-TestHeader "Refresh Token"
$refreshBody = @{
    refreshToken = $global:refreshToken
}
$result = Invoke-ApiRequest -Method "POST" -Endpoint "/auth/refresh" -Body $refreshBody
if ($result.Success) {
    $global:accessToken = $result.Data.data.accessToken
    Write-TestResult $true "Token refreshed" $result.Data
}
else {
    Write-TestResult $false "Token refresh failed" $result
}

# ============================================
# PATIENT MANAGEMENT APIs
# ============================================

# 6. Create Patient
Write-TestHeader "Create Patient"
$patientBody = @{
    patientData = @{
        firstName      = "John"
        lastName       = "Patient"
        age            = 45
        gender         = "Male"
        medicalHistory = "Hypertension, Diabetes"
        notes          = "Regular checkup required"
    }
}
$result = Invoke-ApiRequest -Method "POST" -Endpoint "/patients" -Body $patientBody -RequireAuth $true
if ($result.Success) {
    $global:patientId = $result.Data.data.patientId
    Write-TestResult $true "Patient created" $result.Data
}
else {
    Write-TestResult $false "Patient creation failed" $result
}

# 7. Get Patient
if ($global:patientId) {
    Write-TestHeader "Get Patient"
    $result = Invoke-ApiRequest -Method "GET" -Endpoint "/patients/$global:patientId" -RequireAuth $true
    Write-TestResult $result.Success "Get patient" $result.Data
}

# 8. List Patients
Write-TestHeader "List Patients"
$result = Invoke-ApiRequest -Method "GET" -Endpoint "/patients?page=0&size=10" -RequireAuth $true
Write-TestResult $result.Success "List patients" $result.Data

# 9. Update Patient
if ($global:patientId) {
    Write-TestHeader "Update Patient"
    $updateBody = @{
        patientData = @{
            firstName      = "John"
            lastName       = "Patient"
            age            = 46
            gender         = "Male"
            medicalHistory = "Hypertension, Diabetes, Asthma"
            notes          = "Updated medical history"
        }
    }
    $result = Invoke-ApiRequest -Method "PUT" -Endpoint "/patients/$global:patientId" -Body $updateBody -RequireAuth $true
    Write-TestResult $result.Success "Patient updated" $result.Data
}

# ============================================
# ACCESS MANAGEMENT APIs
# ============================================

# 10. Share Patient Access
if ($global:patientId -and $global:doctor2Id) {
    Write-TestHeader "Share Patient Access"
    $shareBody = @{
        recipientDoctorId = $global:doctor2Id
        role              = "viewer"
    }
    $result = Invoke-ApiRequest -Method "POST" -Endpoint "/patients/$global:patientId/access/share" -Body $shareBody -RequireAuth $true
    Write-TestResult $result.Success "Access shared" $result.Data
}

# 11. List Patient Access
if ($global:patientId) {
    Write-TestHeader "List Patient Access"
    $result = Invoke-ApiRequest -Method "GET" -Endpoint "/patients/$global:patientId/access" -RequireAuth $true
    Write-TestResult $result.Success "List access" $result.Data
}

# 12. Update Access Role
if ($global:patientId -and $global:doctor2Id) {
    Write-TestHeader "Update Access Role"
    $updateRoleBody = @{
        role = "editor"
    }
    $result = Invoke-ApiRequest -Method "PUT" -Endpoint "/patients/$global:patientId/access/$global:doctor2Id" -Body $updateRoleBody -RequireAuth $true
    Write-TestResult $result.Success "Access role updated" $result.Data
}

# ============================================
# SCAN APIs
# ============================================

# 13. Upload Scan (requires file upload - simplified test)
if ($global:patientId) {
    Write-TestHeader "Upload Scan"
    Write-Host "[INFO] Scan upload requires multipart file upload" -ForegroundColor Yellow
    Write-Host "[INFO] This test would require a test image file" -ForegroundColor Yellow
    # Note: File upload requires special handling with Invoke-WebRequest
    # Skipping for now as it requires creating a test file
}

# 14. List Patient Scans
if ($global:patientId) {
    Write-TestHeader "List Patient Scans"
    $result = Invoke-ApiRequest -Method "GET" -Endpoint "/patients/$global:patientId/scans?page=0&size=10" -RequireAuth $true
    Write-TestResult $result.Success "List patient scans" $result.Data
}

# ============================================
# ML PREDICTION APIs
# ============================================

# 15. List Patient Predictions
if ($global:patientId) {
    Write-TestHeader "List Patient Predictions"
    $result = Invoke-ApiRequest -Method "GET" -Endpoint "/patients/$global:patientId/predictions?page=0&size=10" -RequireAuth $true
    Write-TestResult $result.Success "List patient predictions" $result.Data
}

# ============================================
# SUMMARY
# ============================================
Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "TEST SUMMARY" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Created Dummy Data:" -ForegroundColor Yellow
Write-Host "  - Doctor 1 ID: $global:doctor1Id" -ForegroundColor White
Write-Host "  - Doctor 2 ID: $global:doctor2Id" -ForegroundColor White
Write-Host "  - Patient ID: $global:patientId" -ForegroundColor White
Write-Host "`nAll API tests completed!" -ForegroundColor Green

