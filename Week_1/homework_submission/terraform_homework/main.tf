terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "7.16.0"
    }
  }
}

provider "google" {
  # Configuration options
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

# Creating the Bigquery dataset
resource "google_bigquery_dataset" "week1-homework-dataset" {
  dataset_id = var.bq_dataset_name
  location   = var.location

}