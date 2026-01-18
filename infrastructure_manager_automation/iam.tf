# Access project data to retrieve the project number for service agent identities
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

# --- Cloud Build PERMISSIONS (The Critical Fix) ---

# 1. Grant to the Project's DEFAULT Cloud Build Service Account (The Builder)
# This account is often the "caller" referenced in your error message.
resource "google_project_iam_member" "cb_default_usage_consumer" {
  project = var.project_id
  role    = "roles/serviceusage.serviceUsageConsumer"
  member  = "serviceAccount:${data.google_project.project.number}@cloudbuild.gserviceaccount.com"
}

# 2. Grant to the Cloud Build ROBOT Service Agent (The Orchestrator)
resource "google_project_iam_member" "cb_agent_usage_consumer" {
  project = var.project_id
  role    = "roles/serviceusage.serviceUsageConsumer"
  member  = "serviceAccount:service-${data.google_project.project.number}@gcp-sa-cloudbuild.iam.gserviceaccount.com"
}

# 3. Grant Service Agent role to the Robot (Required for GitHub Connection access)
resource "google_project_iam_member" "cb_agent_robot" {
  project = var.project_id
  role    = "roles/cloudbuild.serviceAgent"
  member  = "serviceAccount:service-${data.google_project.project.number}@gcp-sa-cloudbuild.iam.gserviceaccount.com"
}

# --- Cloud Functions Robot Permissions ---

# Grant Service Usage Consumer to the GCF Robot
resource "google_project_iam_member" "gcf_robot_usage" {
  project = var.project_id
  role    = "roles/serviceusage.serviceUsageConsumer"
  member  = "serviceAccount:service-${data.google_project.project.number}@gcf-admin-robot.iam.gserviceaccount.com"
}

# --- Auditor and Infrastructure Manager Permissions ---

resource "google_project_iam_member" "im_role_config_admin" {
  project = var.project_id
  role    = "roles/config.admin"
  member  = "serviceAccount:${google_service_account.im_sa.email}"
}

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

# Secret Accessor for the Robot (Required for Gen2 GitHub Connections)
resource "google_secret_manager_secret_iam_member" "cb_agent_secret" {
  project   = var.project_id
  secret_id = var.github_pat_secret_name
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:service-${data.google_project.project.number}@gcp-sa-cloudbuild.iam.gserviceaccount.com"
}

# --- Mandatory Propagation Delay ---

resource "time_sleep" "wait_for_iam" {
  create_duration = "90s" # Increased to 90s to be absolutely safe for Service Usage propagation

  depends_on = [
    google_project_iam_member.cb_default_usage_consumer,
    google_project_iam_member.cb_agent_usage_consumer,
    google_project_iam_member.cb_agent_robot,
    google_project_iam_member.gcf_robot_usage
  ]
}