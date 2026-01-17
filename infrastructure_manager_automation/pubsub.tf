import {
  to = module.my-gcp-terraform-projects-sternforce-technologies-PubSubTopic.google_pubsub_topic.resource_audit_topic
  id = "projects/sternforce-technologies/topics/resource-audit-topic"
}

resource "google_pubsub_topic" "resource_audit_topic" {
  labels = {
    managed-by-cnrm = "true"
  }

  name    = "resource-audit-topic"
  project = var.project_id
}