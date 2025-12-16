# PostgreSQL Database Setup Script
# Run this script as Administrator or with PostgreSQL superuser access

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "PostgreSQL Database Setup" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Find PostgreSQL installation
$pgPaths = @(
    "C:\Program Files\PostgreSQL\*\bin\psql.exe",
    "C:\Program Files (x86)\PostgreSQL\*\bin\psql.exe"
)

$psqlPath = $null
foreach ($pattern in $pgPaths) {
    $found = Get-ChildItem $pattern -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($found) {
        $psqlPath = $found.FullName
        Write-Host "Found PostgreSQL at: $psqlPath" -ForegroundColor Green
        break
    }
}

if (-not $psqlPath) {
    Write-Host "PostgreSQL not found!" -ForegroundColor Red
    Write-Host ""
    Write-Host "Please install PostgreSQL from:" -ForegroundColor Yellow
    Write-Host "https://www.postgresql.org/download/windows/" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Or use Chocolatey (as Administrator):" -ForegroundColor Yellow
    Write-Host "choco install postgresql -y" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Or use Winget:" -ForegroundColor Yellow
    Write-Host "winget install PostgreSQL.PostgreSQL" -ForegroundColor Cyan
    exit 1
}

# Get PostgreSQL version directory
$pgBinDir = Split-Path $psqlPath
$pgVersionDir = Split-Path $pgBinDir
$pgVersion = Split-Path $pgVersionDir -Leaf

Write-Host "PostgreSQL Version: $pgVersion" -ForegroundColor Gray
Write-Host ""

# Prompt for PostgreSQL superuser password
Write-Host "Enter PostgreSQL superuser password (default: postgres):" -ForegroundColor Yellow
$pgPassword = Read-Host -AsSecureString
$BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($pgPassword)
$plainPassword = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)
if ([string]::IsNullOrEmpty($plainPassword)) {
    $plainPassword = "postgres"
}

# Set PGPASSWORD environment variable
$env:PGPASSWORD = $plainPassword

Write-Host ""
Write-Host "Creating database and user..." -ForegroundColor Yellow

# SQL commands
$sqlCommands = @"
-- Create database
SELECT 'CREATE DATABASE ecgcare;' WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'ecgcare')\gexec

-- Create user
DO `$`$`$`
BEGIN
    IF NOT EXISTS (SELECT FROM pg_user WHERE usename = 'ecguser') THEN
        CREATE USER ecguser WITH PASSWORD 'ecgpass';
    END IF;
END
`$`$`$`;

-- Grant privileges
GRANT ALL PRIVILEGES ON DATABASE ecgcare TO ecguser;
"@

# Try to connect and execute
try {
    # First, connect to postgres database to create ecgcare
    $createDbCmd = "CREATE DATABASE ecgcare;"
    & $psqlPath -U postgres -d postgres -c $createDbCmd 2>&1 | Out-Null
    
    if ($LASTEXITCODE -eq 0 -or $LASTEXITCODE -eq 1) {
        Write-Host "   Database 'ecgcare' created or already exists" -ForegroundColor Green
    }
    
    # Create user
    $createUserCmd = "DO `$`$`$`BEGIN IF NOT EXISTS (SELECT FROM pg_user WHERE usename = 'ecguser') THEN CREATE USER ecguser WITH PASSWORD 'ecgpass'; END IF; END`$`$`$`;"
    & $psqlPath -U postgres -d postgres -c $createUserCmd 2>&1 | Out-Null
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "   User 'ecguser' created or already exists" -ForegroundColor Green
    }
    
    # Grant privileges
    $grantCmd = "GRANT ALL PRIVILEGES ON DATABASE ecgcare TO ecguser;"
    & $psqlPath -U postgres -d postgres -c $grantCmd 2>&1 | Out-Null
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "   Privileges granted" -ForegroundColor Green
    }
    
    # Connect to ecgcare database and create extensions
    Write-Host ""
    Write-Host "Creating required extensions..." -ForegroundColor Yellow
    
    $extensions = @("CREATE EXTENSION IF NOT EXISTS pgcrypto;", "CREATE EXTENSION IF NOT EXISTS citext;")
    foreach ($ext in $extensions) {
        & $psqlPath -U postgres -d ecgcare -c $ext 2>&1 | Out-Null
        if ($LASTEXITCODE -eq 0) {
            Write-Host "   Extension created" -ForegroundColor Green
        }
    }
    
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "Database Setup Complete!" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Database: ecgcare" -ForegroundColor White
    Write-Host "User: ecguser" -ForegroundColor White
    Write-Host "Password: ecgpass" -ForegroundColor White
    Write-Host ""
    Write-Host "You can now start the Spring Boot application!" -ForegroundColor Green
    
}
catch {
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host ""
    Write-Host "Please run this script as Administrator or ensure PostgreSQL is running." -ForegroundColor Yellow
}

# Clear password from environment
Remove-Item Env:\PGPASSWORD -ErrorAction SilentlyContinue










