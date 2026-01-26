# Week 1 Homework Submission - Data Engineering Zoomcamp 2026

This repository contains the solution for Week 1 homework, which involves setting up a data pipeline to ingest NYC taxi data into PostgreSQL and provisioning cloud infrastructure using Terraform.

## Table of Contents

1. [Overview](#overview)
2. [Project Structure](#project-structure)
3. [Phase 1: Docker Setup](#phase-1-docker-setup)
4. [Phase 2: Data Ingestion](#phase-2-data-ingestion)
5. [Phase 3: SQL Queries](#phase-3-sql-queries)
6. [Phase 4: Terraform Infrastructure](#phase-4-terraform-infrastructure)

---

## Overview

This project demonstrates:
- **Docker**: Containerizing PostgreSQL and pgAdmin for local development
- **Data Ingestion**: Loading NYC green taxi data (Parquet) and taxi zone lookup data (CSV) into PostgreSQL
- **SQL Analytics**: Querying the data to answer business questions
- **Infrastructure as Code**: Provisioning GCP resources (GCS bucket and BigQuery dataset) using Terraform

---

## Project Structure

```
homework_submission/
├── README.md                          # This file
├── Dockerfile                         # Docker image for data ingestion script
├── Week1_solution_ingest.py          # Python script for data ingestion (CLI)
├── Week1_solution_ingest.ipynb        # Jupyter notebook version
├── sql_solution.txt                   # SQL queries for homework questions
├── Week_1_datasets/                   # Data files
│   ├── green_tripdata_2025-11.parquet
│   └── taxi_zone_lookup.csv
└── terraform_homework/                # Terraform configuration
    ├── main.tf                        # Main Terraform resources
    ├── variables.tf                   # Variable definitions
    └── keys/                          # GCP service account credentials
        └── gcp_service_account_creds.json
```

---

## Phase 1: Docker Setup

### Prerequisites

- Docker and Docker Compose installed
- Ports 5432 (PostgreSQL) and 8085 (pgAdmin) available

### Starting the PostgreSQL and pgAdmin Containers

Create a `docker-compose.yaml` file in your project root:

```yaml
services:
  pg_container:
    image: postgres:18
    container_name: pg_container
    environment:
      POSTGRES_USER: "root"
      POSTGRES_PASSWORD: "root"
      POSTGRES_DB: "ny_taxi"
    volumes:
      - ny_taxi_postgres_data:/var/lib/postgresql
    ports:
      - "5432:5432"
    restart: unless-stopped
    networks:
      - pg_network

  pg_admin:
    image: dpage/pgadmin4
    container_name: pg_admin
    environment:
      PGADMIN_DEFAULT_EMAIL: "admin@admin.com"
      PGADMIN_DEFAULT_PASSWORD: "root"
    volumes:
      - pgadmin_data:/var/lib/pgadmin
    ports:
      - "8085:80"
    restart: unless-stopped
    depends_on:
      - pg_container
    networks:
      - pg_network

volumes:
  ny_taxi_postgres_data:
  pgadmin_data:

networks:
  pg_network:
    driver: bridge
```

### Commands

Start the containers:
```bash
docker-compose up -d
```

Check container status:
```bash
docker-compose ps
```

View logs:
```bash
docker-compose logs -f
```

Stop the containers:
```bash
docker-compose down
```

Stop and remove volumes (clean slate):
```bash
docker-compose down -v
```

### Accessing pgAdmin

1. Open your browser and navigate to `http://localhost:8085`
2. Login with:
   - Email: `admin@admin.com`
   - Password: `root`
3. Add a new server:
   - Name: `ny_taxi`
   - Host: `pg_container` (use container name, not localhost)
   - Port: `5432`
   - Username: `root`
   - Password: `root`

---

## Phase 2: Data Ingestion

### Downloading the Datasets

The datasets can be downloaded using the following commands:

```bash
# Download green taxi data (November 2025)
curl -L -o Week_1_datasets/green_tripdata_2025-11.parquet \
  https://d37ci6vzurychx.cloudfront.net/trip-data/green_tripdata_2025-11.parquet

# Download taxi zone lookup data
curl -L -o Week_1_datasets/taxi_zone_lookup.csv \
  https://github.com/DataTalksClub/nyc-tlc-data/releases/download/misc/taxi_zone_lookup.csv
```

### Option 1: Using Python Script (Recommended)

The ingestion script uses Click for command-line interface and processes data in batches using PyArrow for efficient parquet reading.

**Prerequisites:**
- Python 3.13+
- Dependencies installed (see `pyproject.toml`)

**Run the ingestion script:**

```bash
python Week1_solution_ingest.py \
  --green-taxi-file "Week_1_datasets/green_tripdata_2025-11.parquet" \
  --taxi-zone-file "Week_1_datasets/taxi_zone_lookup.csv" \
  --pg-user root \
  --pg-pass root \
  --pg-host localhost \
  --pg-port 5432 \
  --pg-db ny_taxi
```

**Available options:**
- `--pg-user`: PostgreSQL username (default: `root`)
- `--pg-pass`: PostgreSQL password (default: `root`)
- `--pg-host`: PostgreSQL host (default: `localhost`)
- `--pg-port`: PostgreSQL port (default: `5432`)
- `--pg-db`: PostgreSQL database name (default: `ny_taxi`)
- `--green-taxi-file`: Path to green taxi parquet file (required)
- `--taxi-zone-file`: Path to taxi zone lookup CSV file (required)
- `--green-taxi-table`: Target table name for green taxi data (default: `green_taxi_data`)
- `--taxi-zone-table`: Target table name for taxi zone lookup data (default: `taxizonelookup_data`)

### Option 2: Using Docker

Build the Docker image:

```bash
docker build -t week1-ingest -f Dockerfile .
```

Run the ingestion container:

```bash
docker run --network host \
  -v $(pwd)/Week_1_datasets:/data \
  week1-ingest \
  --green-taxi-file /data/green_tripdata_2025-11.parquet \
  --taxi-zone-file /data/taxi_zone_lookup.csv
```

### Option 3: Using Jupyter Notebook

Open `Week1_solution_ingest.ipynb` in Jupyter and run the cells sequentially.

### Verification

After ingestion, verify the data was loaded:

```bash
# Connect to PostgreSQL
psql -h localhost -U root -d ny_taxi

# Check row counts
SELECT COUNT(*) FROM green_taxi_data;
SELECT COUNT(*) FROM taxizonelookup_data;
```

Expected results:
- `green_taxi_data`: ~46,912 rows
- `taxizonelookup_data`: 265 rows

---

## Phase 3: SQL Queries

All SQL queries are included below. These queries answer the homework questions about the NYC taxi data.

### Question 3: Trips with distance ≤ 1 mile in November 2025

**Question:** For the trips in November 2025 (lpep_pickup_datetime between '2025-11-01' and '2025-12-01', exclusive of the upper bound), how many trips had a trip_distance of less than or equal to 1 mile?

**SQL Query:**
```sql
SELECT COUNT(*) AS trip_count
FROM green_taxi_data
WHERE CAST(lpep_pickup_datetime AS DATE) >= '2025-11-01' 
  AND CAST(lpep_pickup_datetime AS DATE) < '2025-12-01'
  AND trip_distance <= 1.0;
```

### Question 4: Pickup day with longest trip distance

**Question:** Which was the pickup day with the longest trip distance? Only consider trips with trip_distance less than 100 miles (to exclude data errors). Use the pickup time for your calculations.

**SQL Query:**
```sql
SELECT DATE(lpep_pickup_datetime) AS pickup_day
FROM green_taxi_data
WHERE trip_distance < 100.0
ORDER BY trip_distance DESC
LIMIT 1;
```

### Question 5: Pickup zone with largest total amount on November 18th, 2025

**Question:** Which was the pickup zone with the largest total_amount (sum of all trips) on November 18th, 2025?

**SQL Query:**
```sql
SELECT tz."Zone", SUM(gt.total_amount) AS total_amount
FROM green_taxi_data AS gt
INNER JOIN taxizonelookup_data AS tz
ON gt."PULocationID" = tz."LocationID"
WHERE DATE(lpep_pickup_datetime) = '2025-11-18'
GROUP BY tz."Zone"
ORDER BY total_amount DESC
LIMIT 1;
```

### Question 6: Drop-off zone with largest tip from East Harlem North

**Question:** For the passengers picked up in the zone named "East Harlem North" in November 2025, which was the drop-off zone that had the largest tip?

**SQL Query:**
```sql
WITH all_pass_in_ehn_11_2025 AS(
    SELECT *
    FROM green_taxi_data AS gt
    INNER JOIN taxizonelookup_data AS tz
    ON gt."PULocationID" = tz."LocationID"
    WHERE tz."Zone" = 'East Harlem North'
      AND EXTRACT(YEAR FROM lpep_pickup_datetime) = 2025
      AND EXTRACT(MONTH FROM lpep_pickup_datetime) = 11
)
SELECT tz."Zone", MAX(ap."tip_amount") AS tip_amount
FROM all_pass_in_ehn_11_2025 AS ap
INNER JOIN taxizonelookup_data AS tz
ON ap."DOLocationID" = tz."LocationID"
GROUP BY tz."Zone"
ORDER BY tip_amount DESC
LIMIT 1;
```

---

## Phase 4: Terraform Infrastructure

This section covers provisioning GCP resources (Google Cloud Storage bucket and BigQuery dataset) using Terraform.

### Prerequisites

1. **GCP Account**: Active Google Cloud Platform account
2. **GCP Project**: Create or use an existing GCP project
3. **Service Account**: Create a service account with the following roles:
   - Storage Admin (for GCS bucket)
   - BigQuery Admin (for BigQuery dataset)
4. **Service Account Key**: Download the JSON key file and save it as `terraform_homework/keys/gcp_service_account_creds.json`
5. **Terraform**: Install Terraform (v1.0+)

### Configuration Files

#### `terraform_homework/variables.tf`

Defines all configurable variables with defaults:

```hcl
variable "gcp_credentials_file" {
  type        = string
  description = "The path to the GCP credentials file"
  default     = "./keys/gcp_service_account_creds.json"
}

variable "project_id" {
  type        = string
  description = "The ID of the project"
  default     = "de-zoomcamp-485418"
}

variable "region" {
  type        = string
  description = "The region of the project"
  default     = "africa-south1"
}

variable "bq_dataset_name" {
  type        = string
  description = "The name of the BigQuery dataset"
  default     = "week1_homework_dataset"
}

variable "gcs_bucket_name" {
  type        = string
  description = "The name of the GCS bucket"
  default     = "week1-homework-bucket"
}

variable "location" {
  type        = string
  description = "The location of the resources"
  default     = "africa-south1"
}
```

#### `terraform_homework/main.tf`

Defines the GCP resources:

```hcl
terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "7.16.0"
    }
  }
}

provider "google" {
  project     = var.project_id
  region      = var.region
  credentials = file(var.gcp_credentials_file)
}

resource "google_storage_bucket" "week1-homework-bucket" {
  name          = var.gcs_bucket_name
  location      = var.location
  force_destroy = true

  lifecycle_rule {
    condition {
      age = 1
    }
    action {
      type = "AbortIncompleteMultipartUpload"
    }
  }
}

resource "google_bigquery_dataset" "week1-homework-dataset" {
  dataset_id = var.bq_dataset_name
  location   = var.location
}
```

### Terraform Commands

Navigate to the terraform directory:

```bash
cd terraform_homework
```

**1. Initialize Terraform:**
```bash
terraform init
```

**2. Review the execution plan:**
```bash
terraform plan
```

**3. Apply the configuration:**
```bash
terraform apply
```

Type `yes` when prompted to confirm.

**4. Verify resources in GCP Console:**
- GCS Bucket: Navigate to Cloud Storage in GCP Console
- BigQuery Dataset: Navigate to BigQuery in GCP Console

**5. Destroy resources (when done):**
```bash
terraform destroy
```

Type `yes` when prompted to confirm.


## Author

Oyindamola Victor

