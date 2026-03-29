# variables.tf
variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "region" {
  description = "GCP Region for resources"
  type        = string
  default     = "us-central1"  # default if not overridden
}

variable "repository_name" {
  description = "Artifact Registry repository name"
  type        = string
  default     = "my-docker-repo"
}