resource "google_cloudfunctions2_function" "auditor_function" {
  name        = "im-global-auditor-go"
  project     = var.project_id
  location    = var.region
  description = "Automated Auditor (Managed by GitHub Trigger)"

  build_config {
    runtime     = "go125"
    entry_point = "AuditResources"
    service_account = google_service_account.cb_sa.id
    
    source {
      repo_source {
        project_id   = var.project_id
        repo_name    = google_cloudbuildv2_repository.github_module_repo.id
        branch_name  = "main"
        dir          = "infrastructure_manager_automation/im-audit"
      }
    }
  }

  service_config {
    max_instance_count    = 1
    available_memory      = "256M"
    timeout_seconds       = 60
    service_account_email = google_service_account.im_auditor_sa.email

    environment_variables = {
      GCP_PROJECT = var.project_id
    }
  }

  event_trigger {
    trigger_region = var.region
    event_type     = "google.cloud.pubsub.topic.v1.messagePublished"
    pubsub_topic   = google_pubsub_topic.resource_audit_topic.id
    service_account_email = google_service_account.im_auditor_sa.email
    retry_policy   = "RETRY_POLICY_RETRY"
  }

  depends_on = [google_cloudbuildv2_repository.github_module_repo]
}

# Allow Auditor SA to be invoked by the Pub/Sub OIDC token
resource "google_cloudfunctions2_function_iam_member" "invoker" {
  project        = var.project_id
  location       = google_cloudfunctions2_function.auditor_function.location
  cloud_function = google_cloudfunctions2_function.auditor_function.name
  role           = "roles/run.invoker"
  member         = "serviceAccount:${google_service_account.im_auditor_sa.email}"
}