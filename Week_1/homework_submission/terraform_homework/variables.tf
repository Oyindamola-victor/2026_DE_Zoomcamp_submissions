variable "gcp_credentials_file" {
  type        = string
  description = "The path to the GCP credentials file"
  default     = "./keys/gcp_service_account_creds.json"
  #ex: if you have a directory where this file is called keys with your service account json file
  #saved there as gcp_service_account_creds.json you could use default = "./keys/gcp_service_account_creds.json"
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