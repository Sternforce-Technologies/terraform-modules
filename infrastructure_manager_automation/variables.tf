variable "project_id" {
  description = "The GCP project ID."
  type        = string
}

variable "region" {
  description = "The GCP region for resources."
  type        = string
  default     = "us-central1"
}

variable "deployment_id" {
  description = "A unique identifier for this deployment, used for naming resources."
  type        = string
}

variable "repo_url" {
  description = "The full URL of the source code repository."
  type        = string
}

variable "config_path" {
  description = "The configuration path of the source code repository."
  type        = string
  default     = "."
  }

variable "github_app_installation_id" {
  description = "The installation ID of the GitHub App."
  type        = number
}

variable "github_pat_secret_name" {
  description = "The name of the Secret Manager secret that holds the GitHub PAT."
  type        = string
}

variable "tf_version" {
  description = "The Terraform version to use."
  type        = string
  default     = "1.3.10"
}