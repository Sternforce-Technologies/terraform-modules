# 1. Bucket for initial placeholder code
resource "google_storage_bucket" "gcf_source_bucket" {
  name                        = "${var.project_id}-gcf-source-bucket"
  location                    = var.region
  uniform_bucket_level_access = true
}

# 2. Minimal placeholder zip
resource "google_storage_bucket_object" "placeholder_zip" {
  name    = "placeholder.zip"
  bucket  = google_storage_bucket.gcf_source_bucket.name
  content = " " # Sufficient to allow initial function creation
}

# 3. The Cloud Function
resource "google_cloudfunctions2_function" "auditor_function" {
  name        = "im-global-auditor-go"
  project     = var.project_id
  location    = var.region
  description = "Automated Auditor (Managed by GitHub Trigger)"

  # Wait for IAM permissions to settle
  depends_on = [time_sleep.wait_for_iam]

  build_config {
    runtime     = "go125"
    entry_point = "AuditResources"

    source {
      storage_source {
        bucket = google_storage_bucket.gcf_source_bucket.name
        object = google_storage_bucket_object.placeholder_zip.name
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
    retry_policy   = "RETRY_POLICY_RETRY"
  }
}

# Allow Auditor SA to be invoked (Used for the Pub/Sub Push Subscription)
resource "google_cloudfunctions2_function_iam_member" "invoker" {
  project        = var.project_id
  location       = google_cloudfunctions2_function.auditor_function.location
  cloud_function = google_cloudfunctions2_function.auditor_function.name
  role           = "roles/run.invoker"
  member         = "serviceAccount:${google_service_account.im_auditor_sa.email}"
}