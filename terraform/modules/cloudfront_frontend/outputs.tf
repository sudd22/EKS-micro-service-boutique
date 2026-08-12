
output "cloudfront_domain" {
  value = aws_cloudfront_distribution.storefront.domain_name
}
output "website_url" {
  value = "https://${var.domain_name}"
}
