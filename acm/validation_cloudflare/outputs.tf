output "arn" {
  description = "ARN of the cert"
  value       = "${aws_acm_certificate.cert.arn}"
}
