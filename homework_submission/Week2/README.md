# Week 2 Homework Submission — Data Engineering Zoomcamp 2026

Assignment solution for **Module 2** of the Data Engineering Zoomcamp, using [Kestra](https://kestra.io) for orchestration and PostgreSQL for storage.

## Overview

This project implements an ETL pipeline that:

1. **Extracts** NYC taxi trip data (yellow or green) from the [DataTalksClub NYC TLC data releases](https://github.com/DataTalksClub/nyc-tlc-data/releases)
2. **Loads** the data into PostgreSQL with a staging table pattern
3. **Merges** new records into the target table using `unique_row_id` to avoid duplicates

## Architecture

| Component | Purpose |
|-----------|---------|
| **Kestra** | Workflow orchestration (v1.1) |
| **PostgreSQL** | NYC taxi data storage (`ny_taxi` database) |
| **pgAdmin** | Database administration UI |
| **kestra_postgres** | Kestra metadata storage |

## Prerequisites

- [Docker](https://docs.docker.com/get-docker/) and Docker Compose
- For Kestra AI features: GCP Gemini API key (optional)

## Project Structure

```
week2_homework_submission/
├── docker-compose.yaml   # PostgreSQL, pgAdmin, Kestra services
├── flow_code.yaml        # Kestra workflow definition
├── mock_keys/            # Placeholder for secrets (see Setup)
│   ├── .env
│   ├── .env_encoded
│   └── gcp_service_account.json
└── README.md
```

## Setup

### 1. Configure secrets for Kestra

The Kestra service expects an env file at `keys/.env_encoded`. Create the directory and file:

```bash
mkdir -p keys
cp mock_keys/.env keys/.env
```

Edit `keys/.env` with your values. For Kestra AI (Gemini), you need at least:

```
GCP_GEMINI_KEY=<your_gemini_api_key>
```

Then encode and use it:

```bash
# Encode the env file (Kestra expects base64-encoded env)
base64 keys/.env > keys/.env_encoded
```

### 2. Start the stack

```bash
docker compose up -d
```

### 3. Deploy the workflow

1. Open Kestra UI: http://localhost:8080  
   - Username: `admin@kestra.io`  
   - Password: `Admin1234`

2. Create a new flow and paste the contents of `flow_code.yaml`, or use the Kestra CLI to deploy.

### 4. Access services

| Service | URL | Credentials |
|---------|-----|-------------|
| Kestra | http://localhost:8080 | admin@kestra.io / Admin1234 |
| pgAdmin | http://localhost:8085 | admin@admin.com / root |
| PostgreSQL | localhost:5432 | root / root, database: `ny_taxi` |

## Workflow Details

### Inputs

- **Taxi type**: `yellow` or `green` (default: `yellow`)

### Flow steps

1. **set_label** — Set execution labels
2. **extract** — Download CSV from GitHub (e.g. `yellow_tripdata_2026-01.csv.gz`), gunzip, and output
3. **if_yellow_taxi** / **if_green_taxi** — Branch by taxi type:
   - Create target and staging tables if needed
   - Truncate staging table
   - Copy CSV into staging
   - Add `unique_row_id` (MD5 hash) and `filename`
   - Merge staging into target (insert only new rows)
4. **purge_files** — Remove downloaded files from storage

### Triggers

| Trigger | Schedule | Input |
|---------|----------|-------|
| `green_schedule` | 1st of month at 09:00 | taxi: green |
| `yellow_schedule` | 1st of month at 10:00 | taxi: yellow |

## Running manually

Execute a flow run from the Kestra UI and choose the taxi type. The workflow uses the current month for the file name (e.g. `yellow_tripdata_2026-02.csv`).

## Data sources

- **Yellow taxi**: `https://github.com/DataTalksClub/nyc-tlc-data/releases/download/yellow/{file}.gz`
- **Green taxi**: `https://github.com/DataTalksClub/nyc-tlc-data/releases/download/green/{file}.gz`

## Notes

- The `mock_keys/` folder contains example config only. Do not commit real secrets.
- Ensure `keys/` (or your env path) is in `.gitignore` if it holds real credentials.
