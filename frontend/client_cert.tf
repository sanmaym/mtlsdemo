terraform {
  required_providers {
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.0"
    }
  }
}

provider "tls" {}
provider "local" {}

####################
# 🔐 Root CA
####################
resource "tls_private_key" "root" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "tls_self_signed_cert" "root" {
  is_ca_certificate     = true
  private_key_pem       = tls_private_key.root.private_key_pem
  validity_period_hours = 87600 # 10 years

  allowed_uses = [
    "cert_signing",
    "client_auth"
  ]

  subject {
    common_name = "client-root"
  }
}

#############################
# 🏛 Intermediate CA
#############################
resource "tls_private_key" "intermediate" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "tls_cert_request" "intermediate" {
  private_key_pem = tls_private_key.intermediate.private_key_pem

  subject {
    common_name  = "client-int"
    organization = "My Org"
  }
}

resource "tls_locally_signed_cert" "intermediate" {
  cert_request_pem     = tls_cert_request.intermediate.cert_request_pem
  ca_cert_pem          = tls_self_signed_cert.root.cert_pem
  ca_private_key_pem   = tls_private_key.root.private_key_pem
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
# 👤 Client Certificate
###########################
resource "tls_private_key" "client" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "tls_cert_request" "client_csr" {
  private_key_pem = tls_private_key.client.private_key_pem

  subject {
    common_name         = "macosxexample.com"
    organization        = "example"
    organizational_unit = "macosxexample"
    country             = "US"
    province            = "Virginia"
    locality            = "Reston"
  }
}

resource "tls_locally_signed_cert" "client" {
  cert_request_pem      = tls_cert_request.client_csr.cert_request_pem
  ca_cert_pem           = tls_locally_signed_cert.intermediate.cert_pem
  ca_private_key_pem    = tls_private_key.intermediate.private_key_pem
  validity_period_hours = 87600 # 1 year

  allowed_uses = [
    "digital_signature",
    "key_encipherment",
    "client_auth",
    "content_commitment"
  ]
}

##############################
# 💾 Output Certs to Files
##############################

resource "local_file" "root_cert" {
  content  = tls_self_signed_cert.root.cert_pem
  filename = "${path.module}/fe-root.cert"
}

resource "local_file" "intermediate_cert" {
  content  = tls_locally_signed_cert.intermediate.cert_pem
  filename = "${path.module}/fe-int.cert"
}

resource "local_file" "client_cert" {
  content  = tls_locally_signed_cert.client.cert_pem
  filename = "${path.module}/fe-client.cert"
}

resource "local_file" "client_key" {
  content  = tls_private_key.client.private_key_pem
  filename = "${path.module}/fe-client.key"
}

resource "local_file" "client_chain" {
  content  = join("\n", [
    tls_locally_signed_cert.client.cert_pem,
    tls_locally_signed_cert.intermediate.cert_pem,
    tls_self_signed_cert.root.cert_pem
  ])
  filename = "${path.module}/client-chain.pem"
}