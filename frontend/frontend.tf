
data "google_project" "project" {
  provider   = google-beta
  project_id = var.sg_project_id

}

resource "google_certificate_manager_trust_config" "default" {
  provider    = google-beta
  name        = "${var.sg_prefix}-my-trust-config"
  project     = data.google_project.project.project_id
  description = "sample description for the trust config"
  location    = "global"

  trust_stores {
    trust_anchors {
     pem_certificate = tls_self_signed_cert.root.cert_pem
    }
    intermediate_cas {
      pem_certificate = tls_locally_signed_cert.intermediate.cert_pem
    }
  }
}

resource "google_network_security_server_tls_policy" "default" {
  provider    = google-beta
  name        = "${var.sg_prefix}-tls-policy"
  project     = data.google_project.project.project_id
  description = "${var.sg_prefix}-description"
  location    = "global"
  allow_open  = "false"
  mtls_policy {
    client_validation_mode         = "REJECT_INVALID"
    client_validation_trust_config = "projects/${data.google_project.project.number}/locations/global/trustConfigs/${google_certificate_manager_trust_config.default.name}"
  }
}





