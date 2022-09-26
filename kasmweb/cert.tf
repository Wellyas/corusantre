resource "aws_acm_certificate" "cert" {
  domain_name       = "vdi.b-care.net"
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

output "arn_validation" {
  value = [
    for dvo in aws_acm_certificate.cert.domain_validation_options : "${dvo.resource_record_name   dvo.resource_record_type dvo.resource_record_value}"
  ]
}