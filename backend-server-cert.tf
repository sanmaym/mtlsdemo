

####################
# 🔐 Root CA
####################
resource "tls_private_key" "server_root" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "tls_self_signed_cert" "server_root" {
  is_ca_certificate     = true
  private_key_pem       = tls_private_key.server_root.private_key_pem
  validity_period_hours = 876000 # 10 years

  allowed_uses = [
    "cert_signing",
    "server_auth"
  ]

  subject {
    common_name = "be-apache-root"
  }
}

#############################
# 🏛 Intermediate CA
#############################
resource "tls_private_key" "server_intermediate" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "tls_cert_request" "server_intermediate" {
  private_key_pem = tls_private_key.server_intermediate.private_key_pem

  subject {
    common_name  = "be-apache-int"
    organization = "be-apache-root-org"
  }
}

resource "tls_locally_signed_cert" "server_intermediate" {
  cert_request_pem     = tls_cert_request.server_intermediate.cert_request_pem
  ca_cert_pem          = tls_self_signed_cert.server_root.cert_pem
  ca_private_key_pem   = tls_private_key.server_root.private_key_pem
  is_ca_certificate    = true
  validity_period_hours = 43800 # 5 years

  allowed_uses = [
    "cert_signing",
    "key_encipherment",
    "digital_signature",
    "crl_signing"
  ]
}

###########################
# 👤 Server Leaf Certificate
###########################
resource "tls_private_key" "server_key" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "tls_cert_request" "server_key_csr" {
  private_key_pem = tls_private_key.server_key.private_key_pem

  subject {
    common_name         = "examplebackeendsvc.com"
    organization        = "example"
    organizational_unit = "gxlb-to-apache"
  }
  dns_names = ["examplebackeendsvc.com", "api.examplebackeendsvc.com"]

}

resource "tls_locally_signed_cert" "server_crt" {
  cert_request_pem      = tls_cert_request.server_key_csr.cert_request_pem
  ca_cert_pem           = tls_locally_signed_cert.server_intermediate.cert_pem
  ca_private_key_pem    = tls_private_key.server_intermediate.private_key_pem
  validity_period_hours = 8760 # 1 year

  allowed_uses = [
    "digital_signature",
    "key_encipherment",
    "server_auth",
    "content_commitment"
  ]
}

##############################
# 💾 Output Certs to Files
##############################

resource "local_file" "be_root_cert" {
  content  = tls_self_signed_cert.server_root.cert_pem
  filename = "${path.module}/be-root.cert"
}

resource "local_file" "be_intermediate_cert" {
  content  = tls_locally_signed_cert.server_intermediate.cert_pem
  filename = "${path.module}/be-int.cert"
}

resource "local_file" "be_server_cert" {
  content  = tls_locally_signed_cert.server_crt.cert_pem
  filename = "${path.module}/be-server.cert"
}

resource "local_file" "be_server_key" {
  content  = tls_private_key.server_key.private_key_pem
  filename = "${path.module}/be-server.key"
}
