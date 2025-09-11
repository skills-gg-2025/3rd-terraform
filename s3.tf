# Variable for S3 bucket suffix
variable "s3_bucket_suffix" {
  description = "Suffix for S3 bucket name (apdev-log-s3-{suffix})"
  type        = string
}

# S3 Bucket
resource "aws_s3_bucket" "apdev_s3_bucket" {
  bucket = "apdev-log-s3-${var.s3_bucket_suffix}"

  tags = {
    Name = "apdev-log-s3-${var.s3_bucket_suffix}"
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