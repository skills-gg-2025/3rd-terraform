# Random string for S3 bucket suffix
resource "random_string" "s3_suffix" {
  length  = 4
  special = false
  upper   = false
  numeric = false
}

# S3 Bucket
resource "aws_s3_bucket" "apdev_s3_bucket" {
  bucket = "apdev-log-s3-${random_string.s3_suffix.result}"

  tags = {
    Name = "apdev-log-s3-${random_string.s3_suffix.result}"
  }
}

# S3 Bucket Versioning
resource "aws_s3_bucket_versioning" "apdev_s3_versioning" {
  bucket = aws_s3_bucket.apdev_s3_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

# S3 Bucket Server Side Encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "apdev_s3_encryption" {
  bucket = aws_s3_bucket.apdev_s3_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}