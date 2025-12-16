# ML Model Setup Guide

This guide explains how to integrate your fine-tuned Hugging Face transformer model into the ML service.

## Quick Start

### Option 1: Using a Hugging Face Model ID

If your model is uploaded to Hugging Face Hub:

```bash
# Set environment variable before starting the service
export MODEL_PATH="your-username/your-model-name"
export CLASS_LABELS="ASD,VSD"  # Optional: only if model doesn't have labels configured

# Start the service
uvicorn main:app --reload --port 8000
```

### Option 2: Using a Local Model Path

If your model is saved locally:

```bash
# Set environment variable to local path
export MODEL_PATH="./models/chd-classifier"  # Relative path
# OR
export MODEL_PATH="C:/path/to/your/model"    # Absolute path (Windows)
# OR
export MODEL_PATH="/path/to/your/model"      # Absolute path (Linux/Mac)

export CLASS_LABELS="ASD,VSD"  # Required if model doesn't have labels in config

# Start the service
uvicorn main:app --reload --port 8000
```

### Option 3: Using a .env File (Recommended)

Create a `.env` file in the `ml-service` directory:

```env
MODEL_PATH=your-username/your-model-name
CLASS_LABELS=ASD,VSD
```

Then install `python-dotenv` and load it in your code, or use a tool like `python-dotenv`:

```bash
pip install python-dotenv
```

## Model Requirements

Your fine-tuned model should:

1. **Be a Hugging Face Transformers model** compatible with image classification
2. **Have class labels configured** (recommended):
   - The model's `config.json` should include `id2label` or `label2id` mappings
   - Example config:
     ```json
     {
       "id2label": {
         "0": "ASD",
         "1": "VSD"
       },
       "label2id": {
         "ASD": 0,
         "VSD": 1
       }
     }
     ```

3. **If labels aren't in config**, set the `CLASS_LABELS` environment variable:
   - Format: comma-separated list matching the order of your training classes
   - Example: `CLASS_LABELS="Normal,ASD,VSD"` (class 0=Normal, 1=ASD, 2=VSD)

## How It Works

1. **Model Loading**: The service automatically detects and loads your model using:
   - `AutoImageProcessor` and `AutoModelForImageClassification` (preferred for fine-tuned models)
   - Falls back to `ViTImageProcessor` and `ViTForImageClassification` if needed

2. **Class Labels**: The service tries to get class labels from:
   - Model's `config.id2label` or `config.label2id` (automatic)
   - `CLASS_LABELS` environment variable (fallback)

3. **Prediction**: Uses actual model outputs instead of fake predictions:
   - Gets the predicted class index from model logits
   - Maps it to the class label using `id2label`
   - Returns the actual prediction with confidence score

## Testing Your Model

1. **Start the ML service**:
   ```bash
   cd ml-service
   uvicorn main:app --reload --port 8000
   ```

2. **Check if model loaded**:
   ```bash
   curl http://localhost:8000/
   ```

3. **Test prediction** (if you have a test image):
   ```bash
   # The service will use test_image.jpg if no image_data is provided
   curl -X POST http://localhost:8000/predict \
     -H "Content-Type: application/json" \
     -d '{"scan_id": "test-123"}'
   ```

## Troubleshooting

### Model Not Loading

- **Check the path**: Make sure `MODEL_PATH` points to the correct location
- **Check Hugging Face access**: If using a private model, ensure you're logged in:
  ```bash
  huggingface-cli login
  ```
- **Check model format**: Ensure your model is saved in Hugging Face format (with `config.json`, `pytorch_model.bin`, etc.)

### Wrong Class Labels

- **Check model config**: Inspect your model's `config.json` to see if `id2label` is set
- **Set CLASS_LABELS**: If labels aren't in config, set the environment variable
- **Verify order**: Make sure `CLASS_LABELS` matches the order used during training

### Prediction Errors

- **Check image format**: Ensure images are in a format PIL can read (JPEG, PNG, etc.)
- **Check model input size**: Your model should accept the same image size it was trained on
- **Check logs**: Look at the service logs for detailed error messages

## Example: Fine-tuning and Saving Your Model

If you need to fine-tune a model and save it properly:

```python
from transformers import ViTForImageClassification, TrainingArguments, Trainer
from transformers import ViTImageProcessor

# Load base model
model = ViTForImageClassification.from_pretrained(
    "google/vit-base-patch16-224-in21k",
    num_labels=2,  # Number of classes
    id2label={0: "ASD", 1: "VSD"},
    label2id={"ASD": 0, "VSD": 1}
)

# ... your training code ...

# Save the model
model.save_pretrained("./models/chd-classifier")
processor.save_pretrained("./models/chd-classifier")
```

Then set `MODEL_PATH=./models/chd-classifier` when starting the service.

