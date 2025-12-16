# API Testing Script for CHD-EPICS Backend

$baseUrl = "http://localhost:8080/api"
$accessToken = $null
$refreshToken = $null
$patientId = $null
$scanId = $null

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "CHD-EPICS API Testing" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Test 1: Register Doctor
Write-Host "1. Testing Register Doctor..." -ForegroundColor Yellow
try {
    $registerBody = @{
        email    = "doctor@test.com"
        password = "Test123456!"
        fullName = "Dr. Test User"
        phone    = "+1234567890"
    } | ConvertTo-Json

    $response = Invoke-WebRequest -Uri "$baseUrl/auth/register" -Method POST -Body $registerBody -ContentType "application/json" -UseBasicParsing
    Write-Host "   ✓ Register successful" -ForegroundColor Green
    Write-Host "   Response: $($response.Content)" -ForegroundColor Gray
}
catch {
    Write-Host "   ✗ Register failed: $($_.Exception.Message)" -ForegroundColor Red
    if ($_.Exception.Response) {
        $reader = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
        $responseBody = $reader.ReadToEnd()
        Write-Host "   Error: $responseBody" -ForegroundColor Red
    }
}
Write-Host ""

# Test 2: Login
Write-Host "2. Testing Login..." -ForegroundColor Yellow
try {
    $loginBody = @{
        email    = "doctor@test.com"
        password = "Test123456!"
    } | ConvertTo-Json

    $response = Invoke-WebRequest -Uri "$baseUrl/auth/login" -Method POST -Body $loginBody -ContentType "application/json" -UseBasicParsing
    $responseData = $response.Content | ConvertFrom-Json
    $accessToken = $responseData.data.accessToken
    $refreshToken = $responseData.data.refreshToken
    Write-Host "   ✓ Login successful" -ForegroundColor Green
    Write-Host "   Access Token: $($accessToken.Substring(0, 50))..." -ForegroundColor Gray
}
catch {
    Write-Host "   ✗ Login failed: $($_.Exception.Message)" -ForegroundColor Red
    if ($_.Exception.Response) {
        $reader = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
        $responseBody = $reader.ReadToEnd()
        Write-Host "   Error: $responseBody" -ForegroundColor Red
    }
    exit
}
Write-Host ""

# Test 3: Get Current User
Write-Host "3. Testing Get Current User..." -ForegroundColor Yellow
try {
    $headers = @{
        "Authorization" = "Bearer $accessToken"
    }
    $response = Invoke-WebRequest -Uri "$baseUrl/auth/me" -Method GET -Headers $headers -UseBasicParsing
    Write-Host "   ✓ Get current user successful" -ForegroundColor Green
    Write-Host "   Response: $($response.Content)" -ForegroundColor Gray
}
catch {
    Write-Host "   ✗ Get current user failed: $($_.Exception.Message)" -ForegroundColor Red
}
Write-Host ""

# Test 4: Create Patient
Write-Host "4. Testing Create Patient..." -ForegroundColor Yellow
try {
    $patientBody = @{
        patientData = @{
            name           = "John Doe"
            age            = 45
            gender         = "M"
            dateOfBirth    = "1979-05-20"
            medicalHistory = "Hypertension"
            diagnosis      = "Suspected CHD"
            notes          = "Test patient"
        }
    } | ConvertTo-Json -Depth 10

    $headers = @{
        "Authorization" = "Bearer $accessToken"
    }
    $response = Invoke-WebRequest -Uri "$baseUrl/patients" -Method POST -Body $patientBody -ContentType "application/json" -Headers $headers -UseBasicParsing
    $responseData = $response.Content | ConvertFrom-Json
    $patientId = $responseData.data.patientId
    Write-Host "   ✓ Create patient successful" -ForegroundColor Green
    Write-Host "   Patient ID: $patientId" -ForegroundColor Gray
}
catch {
    Write-Host "   ✗ Create patient failed: $($_.Exception.Message)" -ForegroundColor Red
    if ($_.Exception.Response) {
        $reader = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
        $responseBody = $reader.ReadToEnd()
        Write-Host "   Error: $responseBody" -ForegroundColor Red
    }
}
Write-Host ""

# Test 5: Get Patient
if ($patientId) {
    Write-Host "5. Testing Get Patient..." -ForegroundColor Yellow
    try {
        $headers = @{
            "Authorization" = "Bearer $accessToken"
        }
        $response = Invoke-WebRequest -Uri "$baseUrl/patients/$patientId" -Method GET -Headers $headers -UseBasicParsing
        Write-Host "   ✓ Get patient successful" -ForegroundColor Green
        $responseData = $response.Content | ConvertFrom-Json
        Write-Host "   Patient Name: $($responseData.data.patientData.name)" -ForegroundColor Gray
    }
    catch {
        Write-Host "   ✗ Get patient failed: $($_.Exception.Message)" -ForegroundColor Red
    }
    Write-Host ""
}

# Test 6: List Patients
Write-Host "6. Testing List Patients..." -ForegroundColor Yellow
try {
    $headers = @{
        "Authorization" = "Bearer $accessToken"
    }
    $queryParams = @{
        page = 0
        size = 10
    }
    $uri = "$baseUrl/patients" + '?' + ($queryParams.GetEnumerator() | ForEach-Object { "$($_.Key)=$($_.Value)" }) -join '&'
    $response = Invoke-WebRequest -Uri $uri -Method GET -Headers $headers -UseBasicParsing
    Write-Host "   ✓ List patients successful" -ForegroundColor Green
    $responseData = $response.Content | ConvertFrom-Json
    Write-Host "   Total Patients: $($responseData.data.pagination.totalElements)" -ForegroundColor Gray
}
catch {
    Write-Host "   ✗ List patients failed: $($_.Exception.Message)" -ForegroundColor Red
}
Write-Host ""

# Test 7: Update Patient
if ($patientId) {
    Write-Host "7. Testing Update Patient..." -ForegroundColor Yellow
    try {
        $updateBody = @{
            patientData = @{
                name           = "John Doe Updated"
                age            = 46
                gender         = "M"
                dateOfBirth    = "1979-05-20"
                medicalHistory = "Hypertension, Diabetes"
                diagnosis      = "Confirmed CHD"
                notes          = "Updated test patient"
            }
        } | ConvertTo-Json -Depth 10

        $headers = @{
            "Authorization" = "Bearer $accessToken"
        }
        $response = Invoke-WebRequest -Uri "$baseUrl/patients/$patientId" -Method PUT -Body $updateBody -ContentType "application/json" -Headers $headers -UseBasicParsing
        Write-Host "   ✓ Update patient successful" -ForegroundColor Green
    }
    catch {
        Write-Host "   ✗ Update patient failed: $($_.Exception.Message)" -ForegroundColor Red
    }
    Write-Host ""
}

# Test 8: Refresh Token
Write-Host "8. Testing Refresh Token..." -ForegroundColor Yellow
try {
    $refreshBody = @{
        refreshToken = $refreshToken
    } | ConvertTo-Json

    $response = Invoke-WebRequest -Uri "$baseUrl/auth/refresh" -Method POST -Body $refreshBody -ContentType "application/json" -UseBasicParsing
    $responseData = $response.Content | ConvertFrom-Json
    $newAccessToken = $responseData.data.accessToken
    Write-Host "   ✓ Refresh token successful" -ForegroundColor Green
    Write-Host "   New Access Token: $($newAccessToken.Substring(0, 50))..." -ForegroundColor Gray
    $accessToken = $newAccessToken
}
catch {
    Write-Host "   ✗ Refresh token failed: $($_.Exception.Message)" -ForegroundColor Red
}
Write-Host ""

# Test 9: List Patient Access
if ($patientId) {
    Write-Host "9. Testing List Patient Access..." -ForegroundColor Yellow
    try {
        $headers = @{
            "Authorization" = "Bearer $accessToken"
        }
        $response = Invoke-WebRequest -Uri "$baseUrl/patients/$patientId/access" -Method GET -Headers $headers -UseBasicParsing
        Write-Host "   ✓ List patient access successful" -ForegroundColor Green
        $responseData = $response.Content | ConvertFrom-Json
        Write-Host "   Access Count: $($responseData.data.Count)" -ForegroundColor Gray
    }
    catch {
        Write-Host "   ✗ List patient access failed: $($_.Exception.Message)" -ForegroundColor Red
    }
    Write-Host ""
}

# Test 10: Logout
Write-Host "10. Testing Logout..." -ForegroundColor Yellow
try {
    $headers = @{
        "Authorization" = "Bearer $accessToken"
    }
    $response = Invoke-WebRequest -Uri "$baseUrl/auth/logout" -Method POST -Headers $headers -UseBasicParsing
    Write-Host "   ✓ Logout successful" -ForegroundColor Green
}
catch {
    Write-Host "   ✗ Logout failed: $($_.Exception.Message)" -ForegroundColor Red
}
Write-Host ""

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "API Testing Complete!" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

