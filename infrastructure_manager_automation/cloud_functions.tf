# 1. Bucket for initial placeholder code
# This bucket stores the source code for the function
resource "google_storage_bucket" "gcf_source_bucket" {
  name                        = "${var.project_id}-gcf-source-bucket"
  project                     = var.project_id
  location                    = var.region
  uniform_bucket_level_access = true
}

# 2. GENERATE a valid, minimal zip file
# We need valid Go code so the initial Cloud Build succeeds.
# This creates a 'main.go' file inside a zip archive.
data "archive_file" "placeholder" {
  type        = "zip"
  output_path = "${path.module}/placeholder.zip"
  
  source {
    content  = <<EOF
package auditor

import "context"

// AuditResources is a placeholder to allow the initial function deployment to succeed.
// The real code will be deployed by Cloud Build triggers later.
func AuditResources(ctx context.Context, m interface{}) error { 
    return nil 
}
EOF
    filename = "main.go"
  }
}

# 3. Upload the VALID zip file to the bucket
resource "google_storage_bucket_object" "placeholder_zip" {
  name   = "placeholder.zip"
  bucket = google_storage_bucket.gcf_source_bucket.name
  source = data.archive_file.placeholder.output_path
}

# 4. The Cloud Function
resource "google_cloudfunctions2_function" "auditor_function" {
  name        = "im-global-auditor-go"
  project     = var.project_id
  location    = var.region
  description = "Automated Auditor (Managed by GitHub Trigger)"

  build_config {
    runtime     = "go125"
    entry_point = "AuditResources"
    
    # Use the Cloud Build Service Account for the build
    service_account = google_service_account.cb_sa.id

    # Bootstrap from the placeholder zip in Storage
    # (Triggers will switch this to GitHub for future updates)
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
    trigger_region        = var.region
    event_type            = "google.cloud.pubsub.topic.v1.messagePublished"
    pubsub_topic          = google_pubsub_topic.resource_audit_topic.id
    service_account_email = google_service_account.im_auditor_sa.email
    retry_policy          = "RETRY_POLICY_RETRY"
  }
}

# 5. Allow the Auditor Service Account to be invoked by Eventarc/PubSub
resource "google_cloudfunctions2_function_iam_member" "invoker" {
  project        = var.project_id
  location       = google_cloudfunctions2_function.auditor_function.location
  cloud_function = google_cloudfunctions2_function.auditor_function.name
  role           = "roles/run.invoker"
  member         = "serviceAccount:${google_service_account.im_auditor_sa.email}"
}