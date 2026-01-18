# Access project data to retrieve the project number
data "google_project" "project" {
  project_id = var.project_id
}

# --- Service Accounts ---

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

# --- Infrastructure Manager Permissions ---

resource "google_project_iam_member" "im_role_config_admin" {
  project = var.project_id
  role    = "roles/config.admin"
  member  = "serviceAccount:${google_service_account.im_sa.email}"
}

resource "google_project_iam_member" "im_sa_editor" {
  project = var.project_id
  role    = "roles/editor" # Recommended to tighten this later
  member  = "serviceAccount:${google_service_account.im_sa.email}"
}

# --- Cloud Build Robot Permissions (FIXED) ---

# Robot Agent Role: Required for GitHub connection access
resource "google_project_iam_member" "cb_agent_robot" {
  project = var.project_id
  role    = "roles/cloudbuild.serviceAgent"
  member  = "serviceAccount:service-${data.google_project.project.number}@gcp-sa-cloudbuild.iam.gserviceaccount.com"
}

# Service Usage: Required to "consume" project APIs during build
resource "google_project_iam_member" "cb_agent_usage" {
  project = var.project_id
  role    = "roles/serviceusage.serviceUsageConsumer"
  member  = "serviceAccount:service-${data.google_project.project.number}@gcp-sa-cloudbuild.iam.gserviceaccount.com"
}

# Secret Accessor: Required to read the GitHub PAT token
resource "google_secret_manager_secret_iam_member" "cb_agent_secret" {
  project   = var.project_id
  secret_id = var.github_pat_secret_name
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:service-${data.google_project.project.number}@gcp-sa-cloudbuild.iam.gserviceaccount.com"
}

# --- Cloud Functions Robot Permissions (FIXED) ---

# GCF Robot Usage: Required for pre-flight build checks
resource "google_project_iam_member" "gcf_robot_usage" {
  project = var.project_id
  role    = "roles/serviceusage.serviceUsageConsumer"
  member  = "serviceAccount:service-${data.google_project.project.number}@gcf-admin-robot.iam.gserviceaccount.com"
}

# --- Auditor SA Permissions ---

resource "google_project_iam_member" "im_auditor_role_cloudasset_viewer" {
  project = var.project_id
  role    = "roles/cloudasset.viewer"
  member  = "serviceAccount:${google_service_account.im_auditor_sa.email}"
}

resource "google_project_iam_member" "im_auditor_role_bigquery_dataeditor" {
  project = var.project_id
  role    = "roles/bigquery.dataEditor"
  member  = "serviceAccount:${google_service_account.im_auditor_sa.email}"
}

resource "google_project_iam_member" "im_auditor_role_pubsub_publisher" {
  project = var.project_id
  role    = "roles/pubsub.publisher"
  member  = "serviceAccount:${google_service_account.im_auditor_sa.email}"
}

# --- Mandatory Propagation Delay ---

resource "time_sleep" "wait_for_iam" {
  create_duration = "60s"

  depends_on = [
    google_project_iam_member.cb_agent_robot,
    google_project_iam_member.cb_agent_usage,
    google_project_iam_member.gcf_robot_usage
  ]
}