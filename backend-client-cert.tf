

provider "tls" {}
provider "local" {}

####################
# 🔐 Root CA
####################
resource "tls_private_key" "client_root" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "tls_self_signed_cert" "client_root" {
  is_ca_certificate     = true
  private_key_pem       = tls_private_key.client_root.private_key_pem
  validity_period_hours = 876000 # 10 years

  allowed_uses = [
    "cert_signing",
    "client_auth"
  ]

  subject {
    common_name = "be-client-root"
  }
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
    common_name         = "test.example.com"
    organization        = "example"
    organizational_unit = "be-loadbalancer"
    country             = "US"
    province            = "California"
    locality            = "San Francisco"
  }
}

resource "tls_locally_signed_cert" "client" {
  cert_request_pem      = tls_cert_request.client_csr.cert_request_pem
  ca_cert_pem           = tls_self_signed_cert.client_root.cert_pem
  ca_private_key_pem    = tls_private_key.client_root.private_key_pem
  validity_period_hours = 8760 # 1 year

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
  content  = tls_self_signed_cert.client_root.cert_pem
  filename = "${path.module}/be-client-root.cert"
}

resource "local_file" "client_cert" {
  content  = tls_locally_signed_cert.client.cert_pem
  filename = "${path.module}/be-client.cert"
}

resource "local_file" "client_key" {
  content  = tls_private_key.client.private_key_pem
  filename = "${path.module}/be-client.key"
}

# resource "local_file" "client_chain" {
#   content  = join("\n", [
#     tls_locally_signed_cert.client.cert_pem,
#     tls_locally_signed_cert.intermediate.cert_pem,
#     tls_self_signed_cert.client_root.cert_pem
#   ])
#   filename = "${path.module}/client-chain.pem"
# }