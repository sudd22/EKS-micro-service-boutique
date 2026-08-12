terraform {
  required_providers {
    aws = {
      source                = "hashicorp/aws"
      configuration_aliases = [aws.us_east_1]
    }
  }
}

data "aws_route53_zone" "main" {
  name         = var.domain_name
  private_zone = false
}


resource "aws_acm_certificate" "cert" {
  provider                  = aws.us_east_1
  domain_name               = var.domain_name
  subject_alternative_names = ["*.${var.domain_name}"]
  validation_method         = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "cert_validation" {
  for_each = {
    for dvo in aws_acm_certificate.cert.domain_validation_options : dvo.domain_name => {
      name    = dvo.resource_record_name
      type    = dvo.resource_record_type
      zone_id = data.aws_route53_zone.main.zone_id
      records = [dvo.resource_record_value]
    }
  }

  allow_overwrite = true
  name            = each.value.name
  type            = each.value.type
  zone_id         = data.aws_route53_zone.main.zone_id
  records         = each.value.records
  ttl             = 60

}

resource "aws_acm_certificate_validation" "cert_validation" {
  provider                = aws.us_east_1
  certificate_arn         = aws_acm_certificate.cert.arn
  validation_record_fqdns = [for record in aws_route53_record.cert_validation : record.fqdn]
}

resource "aws_cloudfront_origin_access_control" "s3_access" {
  name                              = "s3-oac"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

resource "aws_cloudfront_function" "strip_api" {
  name    = "frontend_redirect"
  publish = true
  runtime = "cloudfront-js-2.0"
  code    = <<-JS
    function handler(event) {
      var req = event.request;
      if (req.uri.startsWith("/api/")) { req.uri = req.uri.replace(/^\/api/, ""); }
      else if (req.uri === "/api")     { req.uri = "/"; }
      return req;
    }
  JS  
}

resource "aws_cloudfront_distribution" "store_front" {
  enabled             = true
  default_root_object = "index.html"
  aliases             = [var.domain_name, "*.${var.domain_name}"]
  origin {
    origin_id                = "s3-store_front"
    domain_name              = var.storefront_bucket_regional_domain_name
    origin_access_control_id = aws_origin_access_control.s3_access.id
  }
  origin {
    origin_id   = "eks-alb"
    domain_name = var.api_origin_domain
    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "http-only"
      origin_ssl_protocols   = ["TLSv1.3"]
    }
  }
  default_cache_behavior {
    target_origin_id       = "s3-store_front"
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD", "OPTIONS"]
    cached_methods         = ["GET", "HEAD"]
    cache_policy_id        = "658327ea-f89d-4fab-a63d-7e88639e58f6"
  }
  ordered_cache_behavior {
    path_pattern             = "/api/*"
    target_origin_id         = "eks-alb"
    viewer_protocol_policy   = "redirect-to-https"
    allowed_methods          = ["GET", "HEAD", "OPTIONS", "PUT", "POST", "PATCH", "DELETE"]
    cached_methods           = ["GET", "HEAD"]
    cache_policy_id          = "4135ea2d-6df8-44a3-9df3-4b5a84be39ad"
    origin_request_policy_id = "216adef6-5c7f-47e4-b989-5492eafa07d3"

    function_association {
      event_type   = "viewer-request"
      function_arn = aws_cloudfront_function.strip_api.arn
    }
  }
  custom_error_response {
    error_code         = 404
    response_code      = 200
    response_page_path = "/index.html"
  }
  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn      = aws_acm_certificate_validation.cert_validation.certificate_arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }
}

resource "aws_route53_record" "apex_ipv4" {
  zone_id = data.aws_route53_zone.main.zone_id
  name    = var.domain_name
  type    = "A"
  alias {
    name                   = aws_cloudfront_distribution.store_front.domain_name
    zone_id                = aws_cloudfront_distribution.store_front.hosted_zone_id
    evaluate_target_health = false
  }
}
resource "aws_route53_record" "apex_ipv6" {
  zone_id = data.aws_route53_zone.main.zone_id
  name    = var.domain_name
  type    = "AAAA"
  alias {
    name                   = aws_cloudfront_distribution.store_front.domain_name
    zone_id                = aws_cloudfront_distribution.store_front.hosted_zone_id
    evaluate_target_health = false
  }
}
