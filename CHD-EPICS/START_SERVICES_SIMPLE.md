# 🚀 Quick Start - All Services in 4 Steps

## ⚡ Fastest Way: Use the Script!

**Option 1: Use the existing script** (starts 3 services automatically)

```powershell
cd C:\Users\EKTA\OneDrive\Desktop\JavaSpringbootBackend\CHD-EPICS
.\start-all-services.ps1
```

Then manually start frontend (see Step 4 below).

---

## 📋 Manual Method: 4 Separate PowerShell Windows

### 🟦 **Window 1: MinIO (Docker)**

```powershell
# Option A: If container already exists
docker start minio

# Option B: If container doesn't exist, create it
docker run -d --name minio -p 9000:9000 -p 9001:9001 -e "MINIO_ROOT_USER=minioadmin" -e "MINIO_ROOT_PASSWORD=minioadmin" minio/minio server /data --console-address ":9001"
```

**✅ Check**: http://localhost:9001 (login: minioadmin/minioadmin)

---

### 🟩 **Window 2: ML Service**

```powershell
cd C:\Users\EKTA\OneDrive\Desktop\JavaSpringbootBackend\CHD-EPICS\ml-service
python main.py
```

**✅ Look for**: "Uvicorn running on http://0.0.0.0:8000"  
**⏱️ Wait**: 10-30 seconds for model to load

---

### 🟨 **Window 3: Backend (Spring Boot)**

```powershell
cd C:\Users\EKTA\OneDrive\Desktop\JavaSpringbootBackend\CHD-EPICS\backend
.\mvnw.cmd spring-boot:run
```

**✅ Look for**: "Started BackendApplication"  
**⏱️ Wait**: 30-60 seconds

---

### 🟧 **Window 4: Frontend**

```powershell
cd C:\Users\EKTA\OneDrive\Desktop\JavaSpringbootBackend\CHD-EPICS\frontend
python -m http.server 3000
```

**✅ Look for**: "Serving HTTP on 0.0.0.0 port 3000"  
**⏱️ Wait**: Instant!

---

## 🌐 Open Your App!

Once all 4 windows are running:

**Open**: http://localhost:3000/main.html

---

## ✅ Quick Health Checks

Test each service:

1. **Backend**: http://localhost:8080/api/health
2. **ML Service**: http://localhost:8000/health
3. **MinIO**: http://localhost:9001
4. **Frontend**: http://localhost:3000/main.html

---

## 🛑 To Stop Everything

Press `Ctrl+C` in each window, then:
```powershell
docker stop minio
```

---

**That's it! 🎉**




