# CHD-EPICS Backend Setup Guide

## Prerequisites

1. **Java 21** - Install JDK 21
2. **PostgreSQL** - Version 12 or higher
3. **MinIO** (Optional) - For file storage
4. **Redis** (Optional) - For caching and session management
5. **ML Service** (Optional) - Python FastAPI service for predictions

## Database Setup

1. Create PostgreSQL database:
```sql
CREATE DATABASE ecgcare;
CREATE USER ecguser WITH PASSWORD 'ecgpass';
GRANT ALL PRIVILEGES ON DATABASE ecgcare TO ecguser;
```

2. The database schema will be automatically created by Flyway migrations on first startup.

## Configuration

Update `src/main/resources/application.yml` with your database credentials:

```yaml
spring:
  datasource:
    url: jdbc:postgresql://localhost:5432/ecgcare
    username: ecguser
    password: ecgpass
```

## Running the Application

### Option 1: Using Maven Wrapper
```bash
cd backend
./mvnw spring-boot:run
```

### Option 2: Using Maven (if installed)
```bash
cd backend
mvn spring-boot:run
```

### Option 3: Build and Run JAR
```bash
cd backend
./mvnw clean package
java -jar target/backend-0.0.1-SNAPSHOT.jar
```

## Application will start on:
- **Port**: 8080
- **Base URL**: http://localhost:8080
- **API Base**: http://localhost:8080/api

## Testing the APIs

### 1. Register a Doctor
```bash
POST http://localhost:8080/api/auth/register
Content-Type: application/json

{
  "email": "doctor@example.com",
  "password": "SecurePassword123!",
  "fullName": "Dr. John Smith",
  "phone": "+1234567890"
}
```

### 2. Login
```bash
POST http://localhost:8080/api/auth/login
Content-Type: application/json

{
  "email": "doctor@example.com",
  "password": "SecurePassword123!"
}
```

Response will include `accessToken` and `refreshToken`.

### 3. Use the Access Token
Include the token in subsequent requests:
```bash
Authorization: Bearer <accessToken>
```

## API Endpoints

All endpoints are documented in `API_CONTRACTS.md` in the root directory.

### Key Endpoints:
- `POST /api/auth/register` - Register new doctor
- `POST /api/auth/login` - Login
- `POST /api/auth/refresh` - Refresh token
- `GET /api/auth/me` - Get current user
- `POST /api/patients` - Create patient
- `GET /api/patients` - List patients
- `GET /api/patients/{id}` - Get patient
- `POST /api/scans/upload` - Upload ECG scan
- `POST /api/ml/predict/{scanId}` - Get ML prediction

## Troubleshooting

### Database Connection Issues
- Ensure PostgreSQL is running
- Check database credentials in `application.yml`
- Verify database exists and user has permissions

### Port Already in Use
- Change port in `application.yml`:
```yaml
server:
  port: 8081
```

### MinIO Connection Issues
- MinIO is optional for basic functionality
- If not using MinIO, scan uploads will fail
- To disable MinIO, comment out MinIO-related code in `ScanService`

### Redis Connection Issues
- Redis is optional
- Application will work without Redis (some features may be limited)

## Development Notes

- The application uses **Flyway** for database migrations
- All patient data is **encrypted** at rest
- JWT tokens expire after **15 minutes** (access) and **7 days** (refresh)
- Sessions timeout after **30 minutes** of inactivity

## Next Steps

1. Set up MinIO for file storage (if needed)
2. Configure Redis for caching (optional)
3. Start ML service for predictions (optional)
4. Set up production database
5. Configure HTTPS for production










