# CHD-EPICS: Architecture and Low Level Design (LLD) Documentation

## Table of Contents
1. [System Overview](#system-overview)
2. [High-Level Architecture](#high-level-architecture)
3. [Technology Stack](#technology-stack)
4. [Database Design (LLD)](#database-design-lld)
5. [Application Architecture](#application-architecture)
6. [Security Architecture](#security-architecture)
7. [Data Flow](#data-flow)
8. [Component Details](#component-details)

---

## System Overview

**CHD-EPICS** (Chronic Heart Defects - ECG Prediction and Image Classification System) is a healthcare application that:
- Manages doctor authentication and authorization
- Stores and manages encrypted patient data
- Handles ECG scan uploads and storage
- Integrates with ML service for heart defect prediction
- Maintains audit logs for compliance
- Implements role-based access control for patient data

---

## High-Level Architecture

```
┌─────────────────┐
│   Web Client    │
│  (Frontend)     │
└────────┬────────┘
         │ HTTPS/REST API
         │
┌────────▼─────────────────────────────────────┐
│         Spring Boot Backend                   │
│  ┌─────────────────────────────────────────┐ │
│  │  Controllers (REST Endpoints)           │ │
│  └──────────────┬──────────────────────────┘ │
│                 │                            │
│  ┌──────────────▼──────────────────────────┐ │
│  │  Service Layer (Business Logic)         │ │
│  └──────────────┬──────────────────────────┘ │
│                 │                            │
│  ┌──────────────▼──────────────────────────┐ │
│  │  Repository Layer (Data Access)         │ │
│  └──────────────┬──────────────────────────┘ │
│                 │                            │
└─────────────────┼────────────────────────────┘
                  │
    ┌─────────────┼─────────────┬──────────────┐
    │             │             │              │
┌───▼───┐   ┌─────▼─────┐  ┌───▼────┐  ┌─────▼────┐
│PostgreSQL│ │   Redis   │  │ MinIO  │  │ML Service│
│Database │ │  (Cache)  │  │(Storage)│  │ (FastAPI)│
└─────────┘ └───────────┘  └────────┘  └──────────┘
```

### Architecture Layers:

1. **Presentation Layer**: REST API endpoints (to be implemented)
2. **Business Logic Layer**: Service classes (to be implemented)
3. **Data Access Layer**: JPA Repositories (to be implemented)
4. **Infrastructure Layer**: Database, Storage, Cache, External Services

---

## Technology Stack

### Backend (Java/Spring Boot)
- **Framework**: Spring Boot 3.5.7
- **Java Version**: 21
- **Security**: Spring Security + JWT (JJWT 0.11.5)
- **Database**: PostgreSQL with Flyway migrations
- **ORM**: Spring Data JPA / Hibernate
- **Object Storage**: MinIO 8.5.9
- **Caching**: Redis (Spring Data Redis)
- **Password Hashing**: Argon2
- **Build Tool**: Maven
- **Utilities**: Lombok

### ML Service (Python)
- **Framework**: FastAPI
- **ML Library**: Transformers (Hugging Face)
- **Model**: ViT (Vision Transformer) - google/vit-base-patch16-224-in21k
- **Image Processing**: PIL (Pillow)
- **Deep Learning**: PyTorch

### Database
- **RDBMS**: PostgreSQL
- **Extensions**: 
  - `pgcrypto` (for cryptographic functions)
  - `citext` (case-insensitive text)

---

## Database Design (LLD)

### Core Entities and Relationships

#### 1. **Doctor Management**

**`doctor` Table**
- Primary entity for healthcare providers
- Fields: `doctor_id` (UUID), `full_name`, `email` (case-insensitive, unique), `phone`, `is_active`, `created_at`
- Purpose: Stores basic doctor information

**`doctor_auth` Table**
- One-to-one with `doctor`
- Fields: `doctor_id` (FK), `password_hash`, `mfa_enabled`, `mfa_secret`, `last_password_reset`
- Purpose: Authentication credentials and MFA configuration

**`doctor_crypto` Table**
- One-to-one with `doctor`
- Fields: `doctor_id` (FK), `public_key`, `private_key_enc`, `private_key_salt`, `kek_params` (JSONB)
- Purpose: Stores encrypted private keys for patient data encryption/decryption
- **Security**: Private keys are encrypted using KEK (Key Encryption Key) with Argon2

#### 2. **Session Management**

**`session` Table**
- Tracks user sessions for security and audit
- Fields: `session_id` (UUID), `doctor_id` (FK), `login_at`, `last_activity_at`, `logout_at`, `ended_by`, `ip`, `user_agent`
- Indexes: `(doctor_id, login_at)` for efficient session queries
- Purpose: Session tracking, timeout management, security monitoring

#### 3. **Audit Logging**

**`audit_log` Table**
- Comprehensive audit trail
- Fields: `audit_id` (serial), `session_id` (FK), `doctor_id` (FK), `action`, `entity_type`, `entity_id`, `details` (JSONB), `created_at`
- Indexes: `(doctor_id, created_at)` for time-based queries
- Purpose: Compliance, security monitoring, activity tracking

#### 4. **Patient Management (Encrypted)**

**`patient` Table**
- Core patient entity with encrypted payload
- Fields: 
  - `patient_id` (UUID)
  - `anonymized_code` (unique, for de-identification)
  - `enc_payload` (encrypted patient data)
  - `enc_payload_iv` (initialization vector for AES-GCM)
  - `enc_payload_tag` (authentication tag for AES-GCM)
  - `created_at`, `updated_at`
- **Encryption**: AES-GCM (Galois/Counter Mode) for authenticated encryption
- Purpose: Stores encrypted patient information

**`patient_key` Table**
- Many-to-many relationship between patients and doctors
- Fields: `patient_id` (FK), `doctor_id` (FK), `wrapping_scheme`, `dek_enc`, `dek_iv`, `dek_tag`
- Composite Primary Key: `(patient_id, doctor_id)`
- Purpose: Stores encrypted DEK (Data Encryption Key) per doctor-patient pair
- **Key Management**: Each doctor has their own encrypted copy of the DEK, wrapped with their public key

**`patient_access` Table**
- Role-based access control (RBAC)
- Fields: `doctor_id` (FK), `patient_id` (FK), `role` ('owner', 'editor', 'viewer'), `granted_by` (FK), `granted_at`
- Composite Primary Key: `(doctor_id, patient_id)`
- Purpose: Defines access permissions for doctors on patient records

#### 5. **ECG Scan Management**

**`ecg_scan` Table**
- Stores ECG scan metadata
- Fields: `scan_id` (UUID), `patient_id` (FK), `storage_uri` (MinIO path), `mimetype`, `uploaded_by` (FK), `uploaded_at`, `checksum`, `metadata` (JSONB)
- Indexes: `(patient_id, uploaded_at)` for chronological queries
- Purpose: Tracks ECG image files stored in MinIO

#### 6. **ML Results**

**`ml_result` Table**
- Stores ML prediction results
- Fields: `result_id` (UUID), `patient_id` (FK), `scan_id` (FK, nullable), `model_version`, `predicted_label`, `class_probs` (JSONB), `explanation_uri`, `threshold`, `created_by` (FK), `created_at`
- Indexes: `(patient_id, created_at)` for result history
- Purpose: Stores ML predictions (e.g., ASD, VSD classifications)

#### 7. **Draft Management**

**`draft` Table**
- Temporary form data storage
- Fields: `draft_id` (UUID), `doctor_id` (FK), `patient_id` (FK, nullable), `form_type`, `enc_payload`, `enc_payload_iv`, `enc_payload_tag`, `updated_at`
- Purpose: Saves encrypted draft forms before final submission

---

## Application Architecture

### Current State
The application is in **initial setup phase** with:
- ✅ Spring Boot application class configured
- ✅ Dependencies configured in `pom.xml`
- ✅ Database schema defined via Flyway migration
- ✅ Configuration files (application.yml)
- ⏳ **Pending**: Controllers, Services, Repositories, Security Configuration

### Expected Layer Structure

```
com.ecgcare.backend/
├── BackendApplication.java          ✅ (Main class)
├── config/                          ⏳ (To be created)
│   ├── SecurityConfig.java          ⏳ (JWT, Spring Security)
│   ├── MinIOConfig.java             ⏳ (MinIO client setup)
│   ├── RedisConfig.java             ⏳ (Redis connection)
│   └── JwtConfig.java               ⏳ (JWT utilities)
├── controller/                      ⏳ (To be created)
│   ├── AuthController.java          ⏳ (Login, Register, Refresh)
│   ├── PatientController.java      ⏳ (CRUD operations)
│   ├── ScanController.java         ⏳ (Upload, Download scans)
│   └── MLController.java           ⏳ (Trigger predictions)
├── service/                         ⏳ (To be created)
│   ├── AuthService.java            ⏳ (Authentication logic)
│   ├── PatientService.java         ⏳ (Patient business logic)
│   ├── EncryptionService.java      ⏳ (Encryption/decryption)
│   ├── ScanService.java            ⏳ (File handling)
│   └── MLService.java              ⏳ (ML integration)
├── repository/                      ⏳ (To be created)
│   ├── DoctorRepository.java       ⏳ (JPA repository)
│   ├── PatientRepository.java      ⏳ (JPA repository)
│   ├── SessionRepository.java      ⏳ (JPA repository)
│   └── ... (other repositories)
├── model/                           ⏳ (To be created)
│   ├── entity/                      ⏳ (JPA entities)
│   ├── dto/                         ⏳ (Data Transfer Objects)
│   └── request/                     ⏳ (Request models)
└── exception/                       ⏳ (To be created)
    ├── GlobalExceptionHandler.java ⏳ (Error handling)
    └── CustomExceptions.java       ⏳ (Custom exceptions)
```

---

## Security Architecture

### 1. **Authentication & Authorization**

**JWT-Based Authentication**
- **Access Token**: Short-lived (15 minutes), contains user claims
- **Refresh Token**: Long-lived (7 days), stored securely
- **Token Storage**: Redis for blacklisting/revocation

**Session Management**
- Database-backed session tracking
- Automatic timeout handling
- IP and User-Agent tracking

### 2. **Data Encryption**

**Multi-Layer Encryption Strategy**

```
┌─────────────────────────────────────────┐
│  Patient Data (Plaintext)               │
└──────────────┬──────────────────────────┘
               │
               │ AES-GCM Encryption
               │ (DEK - Data Encryption Key)
               ▼
┌─────────────────────────────────────────┐
│  Encrypted Payload (enc_payload)        │
│  + IV (enc_payload_iv)                  │
│  + Tag (enc_payload_tag)                │
└──────────────┬──────────────────────────┘
               │
               │ Key Wrapping
               │ (Doctor's Public Key)
               ▼
┌─────────────────────────────────────────┐
│  Encrypted DEK (dek_enc)                │
│  Stored in patient_key table            │
└─────────────────────────────────────────┘
```

**Key Components:**
- **DEK (Data Encryption Key)**: Symmetric key (AES-256) used to encrypt patient data
- **KEK (Key Encryption Key)**: Derived from doctor's password using Argon2
- **Public/Private Key Pair**: RSA keys for wrapping/unwrapping DEKs
- **Anonymized Code**: Separate identifier for de-identified access

### 3. **Access Control**

**Role-Based Access Control (RBAC)**
- **Owner**: Full control (create, read, update, delete, share)
- **Editor**: Can modify patient data
- **Viewer**: Read-only access

**Access Granting**
- Tracked via `patient_access` table
- Records who granted access (`granted_by`)
- Timestamped (`granted_at`)

### 4. **Password Security**

- **Hashing**: Argon2 (memory-hard, resistant to GPU attacks)
- **MFA Support**: TOTP-based multi-factor authentication
- **Password Reset**: Tracked with `last_password_reset` timestamp

---

## Data Flow

### 1. **User Registration/Login Flow**

```
1. Doctor registers → Password hashed with Argon2
2. RSA key pair generated → Private key encrypted with KEK (derived from password)
3. Keys stored in doctor_crypto table
4. Login → JWT tokens issued (access + refresh)
5. Session created in session table
```

### 2. **Patient Data Creation Flow**

```
1. Doctor creates patient record
2. Generate random DEK (AES-256)
3. Encrypt patient data with DEK using AES-GCM
4. Wrap DEK with doctor's public key
5. Store:
   - Encrypted payload in patient table
   - Encrypted DEK in patient_key table
   - Access record in patient_access table (role: 'owner')
```

### 3. **Patient Data Access Flow**

```
1. Doctor requests patient data
2. System checks patient_access table for permission
3. Retrieve encrypted DEK from patient_key table
4. Unwrap DEK using doctor's private key (decrypted with KEK)
5. Decrypt patient payload using DEK
6. Return decrypted data
7. Log access in audit_log
```

### 4. **ECG Scan Upload & ML Prediction Flow**

```
1. Doctor uploads ECG scan
2. File stored in MinIO → storage_uri generated
3. Metadata saved in ecg_scan table
4. Backend calls ML Service (/predict endpoint)
5. ML Service:
   - Downloads image from MinIO
   - Processes with ViT model
   - Returns prediction (ASD/VSD) + confidence
6. Result stored in ml_result table
7. Response sent to doctor
```

### 5. **Access Sharing Flow**

```
1. Owner doctor grants access to another doctor
2. Retrieve patient's DEK (unwrapped with owner's private key)
3. Wrap DEK with recipient doctor's public key
4. Insert new record in patient_key table
5. Insert access record in patient_access table
6. Log action in audit_log
```

---

## Component Details

### Backend Components (To Be Implemented)

#### **Controllers**
- **AuthController**: `/api/auth/login`, `/api/auth/register`, `/api/auth/refresh`
- **PatientController**: `/api/patients` (CRUD), `/api/patients/{id}/share`
- **ScanController**: `/api/scans/upload`, `/api/scans/{id}/download`
- **MLController**: `/api/ml/predict/{scanId}`

#### **Services**
- **AuthService**: Password validation, JWT generation, session management
- **PatientService**: Patient CRUD, access control, encryption/decryption orchestration
- **EncryptionService**: DEK generation, AES-GCM encryption/decryption, key wrapping
- **ScanService**: MinIO operations, file validation, checksum calculation
- **MLService**: HTTP client for ML service, result processing

#### **Repositories**
- JPA repositories for all entities
- Custom queries for complex operations (e.g., patient access checks)

### ML Service Components

#### **FastAPI Application**
- **Endpoint**: `POST /predict`
- **Input**: `ScanRequest` (mri_scan_id)
- **Process**:
  1. Load image (currently from local file, to be replaced with MinIO download)
  2. Preprocess with ViTImageProcessor
  3. Run inference with ViT model
  4. Post-process results (currently simulated: ASD/VSD based on class index)
- **Output**: Prediction label, confidence score, status

---

## Configuration Details

### Application Configuration (`application.yml`)

**Database**
- PostgreSQL connection with timezone (Asia/Kolkata)
- Flyway enabled for migrations
- Hibernate DDL mode: `validate` (schema managed by Flyway)

**MinIO**
- Endpoint: `http://localhost:9000`
- Bucket: `ecg-bucket`
- Purpose: Object storage for ECG scans

**Redis**
- Host: `localhost:6379`
- Purpose: Caching, session management, JWT blacklisting

**JWT**
- Issuer: `ecgcare`
- Access token TTL: 15 minutes
- Refresh token TTL: 7 days

---

## Security Considerations

### Implemented Security Features
1. ✅ **Encryption at Rest**: Patient data encrypted in database
2. ✅ **Key Management**: Separate DEK per patient, wrapped per doctor
3. ✅ **Password Security**: Argon2 hashing
4. ✅ **Session Tracking**: Database-backed sessions with timeout
5. ✅ **Audit Logging**: Comprehensive activity tracking
6. ✅ **Access Control**: RBAC with granular permissions

### Security Best Practices
- **AES-GCM**: Authenticated encryption (prevents tampering)
- **Key Separation**: Each doctor has separate encrypted DEK copy
- **Anonymization**: Separate anonymized_code for de-identified access
- **Audit Trail**: All actions logged with session context
- **MFA Support**: Infrastructure for TOTP-based MFA

---

## Future Enhancements

1. **ML Service Integration**
   - Replace test image with MinIO download
   - Implement proper ECG classification model
   - Add explanation/visualization generation

2. **API Implementation**
   - Complete REST endpoints
   - Request/response validation
   - Error handling and exception mapping

3. **Performance Optimization**
   - Redis caching for frequently accessed data
   - Database query optimization
   - Connection pooling

4. **Monitoring & Logging**
   - Application logging (Logback/Log4j2)
   - Health checks
   - Metrics collection

5. **Testing**
   - Unit tests for services
   - Integration tests for APIs
   - Security testing

---

## Summary

This is a **healthcare-grade application** with:
- **Strong encryption** for patient data (AES-GCM)
- **Sophisticated key management** (per-doctor DEK wrapping)
- **Comprehensive audit logging** for compliance
- **Role-based access control** for data sharing
- **ML integration** for automated diagnosis
- **Modern tech stack** (Spring Boot 3, Java 21, PostgreSQL)

The architecture follows **layered architecture** principles with clear separation of concerns, making it maintainable and scalable.








