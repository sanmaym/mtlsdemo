
resource "google_certificate_manager_trust_config" "default" {
  provider    = google-beta
  name        = "${var.sg_prefix}-trust-config-int-1"
  project = data.google_project.producer.project_id
  description = "sample description for the backend trust config"
  location    = "global"

  trust_stores {
    trust_anchors {
      pem_certificate = local_file.be_root_cert.content
    }
     intermediate_cas {
       pem_certificate = local_file.be_intermediate_cert.content
     }
  }
}

resource "google_certificate_manager_certificate" "certificate" {
  provider = google-beta
  name     = "${var.sg_prefix}-lb-certificate"
  labels   = {
    foo = "bar"
  }
  project = data.google_project.producer.project_id
  location    = "global"
  self_managed {
     pem_certificate = local_file.client_cert.content
     pem_private_key = local_file.client_key.content
  }
  scope       = "CLIENT_AUTH"
}


resource "google_network_security_backend_authentication_config" "default" {
  provider = google-beta
  name     = "${var.sg_prefix}-backend-auth-config"
  project = data.google_project.producer.project_id
  location           = "global"
  description        = "my description"
 # well_known_roots   = "PUBLIC_ROOTS"
  client_certificate = google_certificate_manager_certificate.certificate.id
  trust_config       = google_certificate_manager_trust_config.default.id
}
