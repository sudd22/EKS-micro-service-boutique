resource "aws_s3_bucket" "storefront" {
  bucket        = "microservice-platform-storefront-boutique"
  force_destroy = true
}

resource "aws_s3_bucket_public_access_block" "storefront" {
  bucket                  = aws_s3_bucket.storefront.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
