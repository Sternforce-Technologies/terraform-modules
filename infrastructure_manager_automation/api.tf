resource "google_project_service" "secret_manager_api" {
  project = var.project_id
  service = "secretmanager.googleapis.com"
}

resource "google_project_service" "configuration_manager_api" {
  project = var.project_id
  service = "config.googleapis.com"
}

resource "google_project_service" "cloud_resource_manager_api" {
  project = var.project_id
  service = "cloudresourcemanager.googleapis.com"
}

resource "google_project_service" "pubsub_api" {
	project = var.project_id
	service = "pubsub.googleapis.com"
}