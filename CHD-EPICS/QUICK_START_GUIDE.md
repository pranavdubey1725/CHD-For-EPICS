# Quick Start Guide - CHD-EPICS System

## 🚀 How to Start All Services

### Prerequisites
- Python installed (for ML Service and Frontend)
- Java 21+ installed (for Backend)
- Maven wrapper (mvnw.cmd) in backend directory
- Docker Desktop running (for MinIO)

### Step-by-Step Startup

#### 1. Start MinIO (Docker)
```powershell
docker start minio
```
Or if container doesn't exist:
```powershell
docker run -d --name minio -p 9000:9000 -p 9001:9001 -e "MINIO_ROOT_USER=minioadmin" -e "MINIO_ROOT_PASSWORD=minioadmin" minio/minio server /data --console-address ":9001"
```

#### 2. Start ML Service (Port 8000)
Open PowerShell and run:
```powershell
cd C:\Users\EKTA\OneDrive\Desktop\JavaSpringbootBackend\CHD-EPICS\ml-service
python main.py
```
**Keep this window open!**

#### 3. Start Backend (Port 8080)
Open a NEW PowerShell window and run:
```powershell
cd C:\Users\EKTA\OneDrive\Desktop\JavaSpringbootBackend\CHD-EPICS\backend
.\mvnw.cmd spring-boot:run
```
**Keep this window open!** Wait for "Started BackendApplication" message.

#### 4. Start Frontend (Port 3000)
Open a NEW PowerShell window and run:
```powershell
cd C:\Users\EKTA\OneDrive\Desktop\JavaSpringbootBackend\CHD-EPICS\frontend
python -m http.server 3000
```
**Keep this window open!**

### Service URLs
- **Frontend**: http://localhost:3000/main.html
- **Backend API**: http://localhost:8080/api
- **ML Service**: http://localhost:8000
- **MinIO Console**: http://localhost:9001 (admin: minioadmin/minioadmin)

### Testing Flow
1. Open http://localhost:3000/main.html
2. Login or Sign Up
3. Select a patient (Patient Details tab)
4. Upload an ECG scan (Scan tab)
5. Click "Analyze Scan"
6. View results on result.html

## 📁 Important Files & Locations

### ML Service
- **Location**: `CHD-EPICS\ml-service\`
- **Main file**: `main.py`
- **Model**: `models\chd-classifier\`
- **Config**: `.env` (MODEL_PATH=./models/chd-classifier)

### Backend
- **Location**: `CHD-EPICS\backend\`
- **Start command**: `.\mvnw.cmd spring-boot:run`
- **Config**: `src\main\resources\application.yml`

### Frontend
- **Location**: `CHD-EPICS\frontend\`
- **Main page**: `main.html`
- **JavaScript modules**: `js\` directory

## ✅ What's Saved

All code changes have been saved:
- ✅ ML Service (`main.py`) - Model loading, prediction endpoint, error handling
- ✅ Frontend files - All HTML, JavaScript modules
- ✅ Backend - All Java code (compiled on startup)
- ✅ Configuration files - `.env`, `application.yml`

## 🔄 To Stop Services

1. **ML Service**: Press `Ctrl+C` in the ML Service window
2. **Backend**: Press `Ctrl+C` in the Backend window
3. **Frontend**: Press `Ctrl+C` in the Frontend window
4. **MinIO**: `docker stop minio` (optional)

## 🐛 Troubleshooting

### Port Already in Use
```powershell
# Find process using port
Get-NetTCPConnection -LocalPort 8000 | Select-Object OwningProcess

# Stop Python processes
Get-Process python | Stop-Process -Force

# Stop Java processes
Get-Process java | Stop-Process -Force
```

### ML Service Not Loading Model
- Check `.env` file exists in `ml-service\` directory
- Verify model files exist in `ml-service\models\chd-classifier\`
- Check `stdout.log` for error messages

### Backend Not Starting
- Make sure Java 21+ is installed
- Check if Maven wrapper (`mvnw.cmd`) exists
- Look for errors in the Backend window

### Frontend 404 Errors
- Make sure you're running the server from `CHD-EPICS\frontend\` directory
- Check that `main.html` exists in that directory

## 📝 Notes

- All services must be running for the full flow to work
- Backend takes 30-60 seconds to start
- ML Service takes 10-30 seconds to load the model
- Keep all service windows open while testing






