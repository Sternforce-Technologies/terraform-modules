resource "google_pubsub_topic" "resource_audit_topic" {
  labels = {
    managed-by-cnrm = "true"
  }

  name    = "resource-audit-topic"
  project = var.project_id
}