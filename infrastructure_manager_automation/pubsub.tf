resource "google_pubsub_topic" "resource_audit_topic" {
  labels = {
    managed-by-cnrm = "true"
  }

  name    = "resource-audit-topic"
  project = var.project_id
}

resource "google_pubsub_subscription" "im_global_auditor_subscription" {
  ack_deadline_seconds = 600
  message_retention_duration = "86400s"
  name                       = "im-global-auditor-subscription"
  project                    = var.project_id
  topic                      = google_pubsub_topic.resource_audit_topic.name

  push_config {
    oidc_token {
      audience              = "https://im-global-auditor-go-y7knqaxl4q-uc.a.run.app"
      service_account_email = google_service_account.im_auditor_sa.email
    }

    push_endpoint = "https://im-global-auditor-go-y7knqaxl4q-uc.a.run.app?__GCP_CloudEventsMode=CUSTOM_PUBSUB_projects%2Fsternforce-technologies%2Ftopics%2Fresource-audit-topic"
  }

  retry_policy {
    maximum_backoff = "600s"
    minimum_backoff = "10s"
  }
}