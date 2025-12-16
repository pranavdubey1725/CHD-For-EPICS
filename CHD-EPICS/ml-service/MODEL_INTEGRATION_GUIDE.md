# Model Integration Guide

This guide explains how to integrate your trained ConvNeXt model (with `config.json`, `model.safetensors`, `preprocessor_config.json`, and `training_args.bin`) into the ML service.

## Model Files Overview

Your trained model consists of four key files:

1. **config.json** - Model architecture and hyperparameters (ConvNeXt configuration, number of labels, label mappings)
2. **model.safetensors** - Trained model weights in safetensors format (secure, high-performance alternative to .bin files)
3. **preprocessor_config.json** - Image preprocessing settings (resizing, normalization, mean/std values)
4. **training_args.bin** - Training session arguments (optional for inference, but useful for reproducibility)

## Setup Instructions

### Step 1: Place Your Model Files

Create a directory structure for your model. You can place it anywhere, but we recommend:

```
CHD-EPICS/ml-service/models/chd-classifier/
├── config.json
├── model.safetensors
├── preprocessor_config.json
└── training_args.bin (optional)
```

**Important**: All files should be in the same directory.

### Step 2: Configure the Model Path

You have three options to set the model path:

#### Option A: Using Environment Variable (Recommended)

**Windows (PowerShell):**
```powershell
$env:MODEL_PATH=".\models\chd-classifier"
# Or absolute path:
$env:MODEL_PATH="C:\Users\EKTA\OneDrive\Desktop\JavaSpringbootBackend\CHD-EPICS\ml-service\models\chd-classifier"
```

**Windows (Command Prompt):**
```cmd
set MODEL_PATH=.\models\chd-classifier
```

**Linux/Mac:**
```bash
export MODEL_PATH="./models/chd-classifier"
```

#### Option B: Using .env File (Recommended for Development)

Create a `.env` file in the `ml-service` directory:

```env
MODEL_PATH=./models/chd-classifier
# Or absolute path:
# MODEL_PATH=C:/Users/EKTA/OneDrive/Desktop/JavaSpringbootBackend/CHD-EPICS/ml-service/models/chd-classifier

# Optional: Only needed if labels aren't in config.json
CLASS_LABELS=ASD,VSD
```

#### Option C: Modify main.py Directly

Edit `main.py` and change the default:
```python
MODEL_NAME = os.getenv("MODEL_PATH", "./models/chd-classifier")  # Your local path
```

### Step 3: Install Dependencies

Make sure all required packages are installed:

```bash
cd CHD-EPICS/ml-service
pip install -r requirements.txt
```

The `requirements.txt` includes:
- `transformers` - For loading Hugging Face models
- `safetensors` - For loading .safetensors weight files
- `torch` - PyTorch for model inference
- `pillow` - For image processing

### Step 4: Verify Model Files

Before starting the service, verify your model directory contains:

- ✅ `config.json` - Required
- ✅ `model.safetensors` - Required (or `pytorch_model.bin` as fallback)
- ✅ `preprocessor_config.json` - Required

The service will automatically check for these files and warn you if any are missing.

### Step 5: Start the ML Service

```bash
cd CHD-EPICS/ml-service
uvicorn main:app --reload --port 8000
```

You should see output like:
```
--- Loading model from: ./models/chd-classifier (this may take a minute)... ---
--- Detected local model directory: ./models/chd-classifier ---
--- Found model weights in safetensors format ---
--- Loaded using AutoImageProcessor and AutoModelForImageClassification ---
--- Model type: ConvNextForImageClassification ---
--- Model class labels loaded from config: {0: 'ASD', 1: 'VSD'} ---
--- Model loaded successfully! ---
--- Model has 2 classes: ['ASD', 'VSD'] ---
```

## How It Works

1. **Model Loading**: The service uses `AutoImageProcessor` and `AutoModelForImageClassification` which automatically:
   - Loads `config.json` to reconstruct the model architecture
   - Loads `model.safetensors` to set the trained weights
   - Loads `preprocessor_config.json` to configure image preprocessing

2. **Class Labels**: The service automatically extracts class labels from `config.json`:
   - Looks for `id2label` or `label2id` mappings in the config
   - Falls back to `CLASS_LABELS` environment variable if not found

3. **Inference**: When you call `/predict`:
   - Image is preprocessed using settings from `preprocessor_config.json`
   - Model runs inference using the loaded weights
   - Returns prediction with confidence score

## Troubleshooting

### Model Not Loading

**Error**: `OSError: Can't load config for './models/chd-classifier'`

**Solution**: 
- Check that `MODEL_PATH` points to the correct directory
- Verify `config.json` exists in that directory
- Use absolute path if relative path doesn't work

### Missing Model Weights

**Error**: `OSError: Unable to load weights from model.safetensors`

**Solution**:
- Verify `model.safetensors` exists in the model directory
- Check file permissions
- Ensure `safetensors` package is installed: `pip install safetensors`

### Wrong Class Labels

**Issue**: Predictions return wrong class names

**Solution**:
- Check `config.json` contains `id2label` mapping:
  ```json
  {
    "id2label": {
      "0": "ASD",
      "1": "VSD"
    }
  }
  ```
- Or set `CLASS_LABELS` environment variable: `CLASS_LABELS=ASD,VSD`

### ConvNeXt Model Not Recognized

**Issue**: Model loads but shows wrong model type

**Solution**:
- The `AutoModelForImageClassification` should automatically detect ConvNeXt from `config.json`
- If not, check that `config.json` has `"model_type": "convnext"`

## Testing Your Integration

1. **Check service health**:
   ```bash
   curl http://localhost:8000/
   ```

2. **Test prediction** (with test image):
   ```bash
   curl -X POST http://localhost:8000/predict \
     -H "Content-Type: application/json" \
     -d '{"scan_id": "test-123", "image_data": "<base64_encoded_image>"}'
   ```

3. **Check logs** for model loading and prediction details

## Notes

- `training_args.bin` is **optional** for inference - it's only needed if you want to resume training
- The service automatically handles both `.safetensors` and `.bin` weight formats
- Model loading happens once at startup, so the first request may be slower
- The service uses `model.eval()` to set the model to evaluation mode (no training)






