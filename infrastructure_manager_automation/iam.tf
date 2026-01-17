data "google_project" "project" {
  project_id = var.project_id
}

resource "google_service_account" "im_sa" {
  account_id   = "${var.deployment_id}-im-sa"
  display_name = "Infrastructure Manager Service Account"
  project      = var.project_id
}

resource "google_service_account" "cb_sa" {
  account_id   = "${var.deployment_id}-cb-sa"
  display_name = "Cloud Build Service Account"
  project      = var.project_id
}

resource "google_service_account" "im_auditor_sa" {
  account_id   = "${var.deployment_id}-im-auditor-sa"
  display_name = "Infrastructure Manager Auditor Service Account"
  project      = var.project_id
}

# Permissions for the Infrastructure Manager service account
# This SA is used by the 'gcloud infra-manager' commands to deploy resources.

resource "google_project_iam_member" "im_role_config_admin" {
  project = var.project_id
  role    = "roles/config.admin"
  member  = "serviceAccount:${google_service_account.im_sa.email}"
}

resource "google_project_iam_member" "im_sa_serviceusage_admin" {
  project = var.project_id
  role    = "roles/serviceusage.serviceUsageAdmin"
  member  = "serviceAccount:${google_service_account.im_sa.email}"
}

resource "google_project_iam_member" "im_sa_iam_sa_admin" {
  project = var.project_id
  role    = "roles/iam.serviceAccountAdmin"
  member  = "serviceAccount:${google_service_account.im_sa.email}"
}

resource "google_project_iam_member" "im_sa_project_iam_admin" {
  project = var.project_id
  role    = "roles/resourcemanager.projectIamAdmin"
  member  = "serviceAccount:${google_service_account.im_sa.email}"
}

resource "google_project_iam_member" "im_sa_secretmanager_admin" {
  project = var.project_id
  role    = "roles/secretmanager.admin"
  member  = "serviceAccount:${google_service_account.im_sa.email}"
}

resource "google_project_iam_member" "im_sa_storage_object_admin" {
  project = var.project_id
  role    = "roles/storage.objectAdmin"
  member  = "serviceAccount:${google_service_account.im_sa.email}"
}

# TODO: Remove editor role if possible and replace with more granular roles
resource "google_project_iam_member" "im_sa_editor" {
  project = var.project_id
  role    = "roles/editor"
  member  = "serviceAccount:${google_service_account.im_sa.email}"
}


# Permissions for the Cloud Build service account (cb_sa)
# This SA runs the Cloud Build triggers.

# Allow cb_sa to act as im_sa
resource "google_service_account_iam_member" "cb_impersonate_im_sa" {
  service_account_id = google_service_account.im_sa.name
  role               = "roles/iam.serviceAccountUser"
  member             = "serviceAccount:${google_service_account.cb_sa.email}"
}

# Allow cb_sa to write logs
resource "google_project_iam_member" "cb_logging" {
  project = var.project_id
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${google_service_account.cb_sa.email}"
}

# Allow cb_sa to access the PAT secret
# should not be editor role here
resource "google_secret_manager_secret_iam_member" "cb_secret_accessor" {
  project   = var.project_id
  secret_id = var.github_pat_secret_name
  role      = "roles/editor"
  member    = "serviceAccount:${google_service_account.cb_sa.email}"
}

# Permissions for the Infrastructure Manager Auditor service account (im_auditor_sa)
# This SA is used by the 'gcloud infra-manager' commands to audit resources.

# Allow im_auditor_sa to act as im_sa
resource "google_service_account_iam_member" "cloudbuild_sa_user" {
  service_account_id = google_service_account.im_auditor_sa.name
  role               = "roles/iam.serviceAccountUser"
  member             = "serviceAccount:${google_service_account.cb_sa.email}"
}

# Grant Infra Manager Viewer to see Terraform state
resource "google_project_iam_member" "im_auditor_role_config_viewer" {
  project = var.project_id
  role    = "roles/config.viewer"
  member  = "serviceAccount:${google_service_account.im_auditor_sa.email}"
}

# Grant Asset Inventory Viewer to see actual state
resource "google_project_iam_member" "im_auditor_role_cloudasset_viewer" {
  project = var.project_id
  role    = "roles/cloudasset.viewer"
  member  = "serviceAccount:${google_service_account.im_auditor_sa.email}"
}

# Grant Cloud Service Agent to access the repos
resource "google_project_iam_member" "im_auditor_role_cloudbuild_service_agent" {
  project = var.project_id
  role    = "roles/cloudbuild.serviceAgent"
  member  = "serviceAccount:${google_service_account.im_auditor_sa.email}"
}

# Grant Pub/Sub Publisher to send alerts
resource "google_project_iam_member" "im_auditor_role_pubsub_publisher" {
  project = var.project_id
  role    = "roles/pubsub.publisher"
  member  = "serviceAccount:${google_service_account.im_auditor_sa.email}"
}

# Grant BigQuery Data Editor to write to BQ tables
resource "google_project_iam_member" "im_auditor_role_bigquery_dataeditor" {
  project = var.project_id
  role    = "roles/bigquery.dataEditor"
  member  = "serviceAccount:${google_service_account.im_auditor_sa.email}"
}

# Grant Logging Log Writer to write logs
resource "google_project_iam_member" "im_auditor_role_logging_logwriter" {
  project = var.project_id
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${google_service_account.im_auditor_sa.email}"
}

# Grant Secret Manager Secret Accessor to read secrets
resource "google_project_iam_member" "im_auditor_role_secretmanager_secretaccessor" {
  project = var.project_id
  role    = "roles/secretmanager.secretAccessor"
  member  = "serviceAccount:${google_service_account.im_auditor_sa.email}"
}

# Test only
resource "google_project_iam_member" "im_auditor_editor" {
	project = var.project_id
	role    = "roles/editor"
	member  = "serviceAccount:${google_service_account.im_auditor_sa.email}"
}

# Permissions for the Google-managed Cloud Build service agent
# This agent is used by the google_cloudbuildv2_connection resource.

resource "google_secret_manager_secret_iam_member" "gcp_default_sa_secret_accessor" {
  project   = var.project_id
  secret_id = var.github_pat_secret_name
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:service-${data.google_project.project.number}@gcp-sa-cloudbuild.iam.gserviceaccount.com"
}

### Test

# 2. The Cloud Build Service Agent needs to be a "Service Agent"
# This allows it to actually "perform" the build using managed connections
resource "google_project_iam_member" "cloudbuild_service_agent_role" {
  project = var.project_id
  role    = "roles/cloudbuild.serviceAgent"
  member  = "serviceAccount:service-${data.google_project.project.number}@gcp-sa-cloudbuild.iam.gserviceaccount.com"
}

# 3. The Cloud Functions Service Agent needs to act as the build account
# This is the "handshake" that often fails
resource "google_project_iam_member" "gcf_service_agent" {
  project = var.project_id
  role    = "roles/cloudfunctions.serviceAgent"
  member  = "serviceAccount:service-${data.google_project.project.number}@gcf-admin-robot.iam.gserviceaccount.com"
}
