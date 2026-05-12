variable "project" {
    description = "project ID for the GCP resources."
    default     = "de-zoomcamp-496113"
  
}

variable "region" {
    description = "Project region for resources."
    default     = "us-central1"
  
}

variable "location" {
    description = "Project location for resources."
    default     = "US"
  
}


variable "bq_dataset_name" {
    description = "The name of the BigQuery Dataset to create."
    type        = string
    default     = "demo_dataset"
  
}

variable "bq_bucket_name" {
    description = "The name of the BigQuery Bucket to create."
    type        = string
    default     = "de-zoomcamp-496113-terra-bucket"
  
}


variable "gcs_storage_class" {
    description = "The storage class for the GCS bucket."
    type        = string
    default     = "STANDARD"
}