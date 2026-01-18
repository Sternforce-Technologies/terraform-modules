# Access project data
data "google_project" "project" {
  project_id = var.project_id
}

# --- 1. Service Account Definitions ---

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

# --- 2. Infrastructure Manager (IM) Core Permissions ---

resource "google_project_iam_member" "im_role_config_admin" {
  project = var.project_id
  role    = "roles/config.admin"
  member  = "serviceAccount:${google_service_account.im_sa.email}"
}

resource "google_project_iam_member" "im_sa_editor" {
  project = var.project_id
  role    = "roles/editor" 
  member  = "serviceAccount:${google_service_account.im_sa.email}"
}

# IM needs to be able to "ActAs" itself to deploy resources
resource "google_service_account_iam_member" "im_sa_user" {
  service_account_id = google_service_account.im_sa.name
  role               = "roles/iam.serviceAccountUser"
  member             = "serviceAccount:${google_service_account.im_sa.email}"
}

# --- 3. Custom Cloud Build SA (cb_sa) Permissions ---

# This fixes the build failing once it actually starts
resource "google_project_iam_member" "cb_sa_logging" {
  project = var.project_id
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${google_service_account.cb_sa.email}"
}

resource "google_project_iam_member" "cb_sa_functions_dev" {
  project = var.project_id
  role    = "roles/cloudfunctions.developer"
  member  = "serviceAccount:${google_service_account.cb_sa.email}"
}

resource "google_project_iam_member" "cb_sa_usage" {
  project = var.project_id
  role    = "roles/serviceusage.serviceUsageConsumer"
  member  = "serviceAccount:${google_service_account.cb_sa.email}"
}

# This allows Cloud Build to "pass" the Auditor SA to the function during deploy
resource "google_service_account_iam_member" "cb_sa_actas_auditor" {
  service_account_id = google_service_account.im_auditor_sa.name
  role               = "roles/iam.serviceAccountUser"
  member             = "serviceAccount:${google_service_account.cb_sa.email}"
}

# --- 4. Robot/Service Agent Permissions (The Pre-Flight Fixes) ---

resource "google_project_iam_member" "cb_agent_robot" {
  project = var.project_id
  role    = "roles/cloudbuild.serviceAgent"
  member  = "serviceAccount:service-${data.google_project.project.number}@gcp-sa-cloudbuild.iam.gserviceaccount.com"
}

resource "google_project_iam_member" "cb_agent_usage" {
  project = var.project_id
  role    = "roles/serviceusage.serviceUsageConsumer"
  member  = "serviceAccount:service-${data.google_project.project.number}@gcp-sa-cloudbuild.iam.gserviceaccount.com"
}

resource "google_project_iam_member" "gcf_robot_usage" {
  project = var.project_id
  role    = "roles/serviceusage.serviceUsageConsumer"
  member  = "serviceAccount:service-${data.google_project.project.number}@gcf-admin-robot.iam.gserviceaccount.com"
}

# --- 5. Auditor SA Permissions (The "Logic" Permissions) ---

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

# --- 6. Infrastructure Manager Service Agent Permissions ---

# Fixes: "Caller does not have required permission to use project"
resource "google_project_iam_member" "im_agent_usage" {
  project = var.project_id
  role    = "roles/serviceusage.serviceUsageConsumer"
  member  = "serviceAccount:service-${data.google_project.project.number}@gcp-sa-config.iam.gserviceaccount.com"
}

# Fixes: "Permission 'iam.serviceaccounts.actAs' denied" (Likely the next error you would hit)
# Allows the Infra Manager Agent to run the build AS the im_sa
resource "google_service_account_iam_member" "im_agent_actas_im_sa" {
  service_account_id = google_service_account.im_sa.name
  role               = "roles/iam.serviceAccountUser"
  member             = "serviceAccount:service-${data.google_project.project.number}@gcp-sa-config.iam.gserviceaccount.com"
}


# --- 6. Propagation Wait ---

resource "time_sleep" "wait_for_iam" {
  create_duration = "90s" 

  depends_on = [
    google_project_iam_member.cb_sa_usage,
    google_project_iam_member.cb_agent_usage,
    google_project_iam_member.gcf_robot_usage,
    google_service_account_iam_member.cb_sa_actas_auditor
  ]
}