# Week 3

## `load_yellow_taxi_data.py`

This script downloads **NYC Yellow Taxi** trip data (Parquet) and uploads it to **Google Cloud Storage (GCS)** for use in data engineering pipelines (e.g. ingestion into a data warehouse).

### What it does

1. **Download** – Fetches yellow taxi trip Parquet files from the public NYC TLC dataset for **January–June 2024** (6 months). Downloads run in parallel (4 workers).
2. **GCS bucket** – Creates the target GCS bucket if it doesn’t exist, or verifies it belongs to your project.
3. **Upload** – Uploads each downloaded file to the bucket with retries (up to 3 attempts) and verifies each upload.
4. **Configuration** – Reads settings from `keys/.env` (bucket name, credentials path, download directory). Parquet files are saved under the `dataset/` folder by default.

### Requirements

- Python 3.12+
- Dependencies managed with **uv** (see `pyproject.toml`): `python-dotenv`, `google-cloud-storage`

### Setup

1. Create a `keys` folder and copy the example env there:
   ```bash
   mkdir -p keys
   cp keys/.env.example keys/.env
   ```
2. In `keys/.env`, set at least:
   - `GCS_BUCKET_NAME` – your GCS bucket name (required)
   - `GCP_CREDENTIALS_FILE` – path to GCP service account JSON, e.g. `keys/gcp_service_account.json` (optional if using `gcloud` default credentials)
3. Optionally put your GCP service account JSON in `keys/` (e.g. `keys/gcp_service_account.json`).
4. Install dependencies:
   ```bash
   uv sync
   ```

### Run

```bash
uv run python load_yellow_taxi_data.py
```

Or activate the venv and run:

```bash
source .venv/bin/activate
python load_yellow_taxi_data.py
```

### Environment variables (`.env`)

| Variable | Required | Description |
|----------|----------|-------------|
| `GCS_BUCKET_NAME` | Yes | GCS bucket name for uploaded Parquet files |
| `GCP_CREDENTIALS_FILE` | No | Path to GCP service account JSON (default: `keys/gcp_service_account.json`) |
| `GCP_PROJECT` | No | GCP project ID (used when not using a credentials file) |
| `DOWNLOAD_DIR` | No | Directory for downloaded files (default: `dataset` next to script) |
| `YELLOW_TAXI_BASE_URL` | No | Base URL for trip data (has a default) |
