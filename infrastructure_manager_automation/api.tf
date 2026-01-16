locals {
  enabled_apis = [
    "artifactregistry.googleapis.com",
    "bigquery.googleapis.com",
    "cloudbuild.googleapis.com",
    "cloudfunctions.googleapis.com",
    "cloudresourcemanager.googleapis.com",
    "config.googleapis.com",
    "container.googleapis.com",
    "eventarc.googleapis.com",
    "gkeconnect.googleapis.com",
    "gkehub.googleapis.com",
    "iamcredentials.googleapis.com",
    "multiclustermetering.googleapis.com",
    "pubsub.googleapis.com",
    "run.googleapis.com",
    "secretmanager.googleapis.com",
    "source.googleapis.com",
  ]
}

moved {
  from = module.infrastructure_manager_automation.google_project_service.configuration_manager_api
  to   = module.infrastructure_manager_automation.google_project_service.gcp_services["config.googleapis.com"]
}

moved {
  from = module.infrastructure_manager_automation.google_project_service.pubsub_api
  to   = module.infrastructure_manager_automation.google_project_service.gcp_services["pubsub.googleapis.com"]
}

moved {
  from = module.infrastructure_manager_automation.google_project_service.cloud_resource_manager_api
  to   = module.infrastructure_manager_automation.google_project_service.gcp_services["cloudresourcemanager.googleapis.com"]
}

moved {
  from = module.infrastructure_manager_automation.google_project_service.secret_manager_api
  to   = module.infrastructure_manager_automation.google_project_service.gcp_services["secretmanager.googleapis.com"]
}

resource "google_project_service" "gcp_services" {
  for_each = toset(local.enabled_apis)
  project  = var.project_id
  service  = each.key
}