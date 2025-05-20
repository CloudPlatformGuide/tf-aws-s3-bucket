#Example: Basic S3 Bucket Creation with versioning and access logging

resource "random_id" "basic_suffix" {
  byte_length = 4
}

resource "random_id" "logging_suffix" {
  byte_length = 4
}

# Create a bucket for logging
module "logging_s3" {
  source        = "../"
  bucket_name   = "logging-bucket-${random_id.logging_suffix.hex}"
  force_destroy = true

  # Make this a logging bucket
  is_logging_bucket = true

  # Enable versioning with MFA delete disabled
  versioning = {
    enabled    = true
    mfa_delete = false
  }

  tags = {
    Environment = "dev"
    Purpose     = "Example"
  }
}


module "basic_s3" {
  source        = "../"
  bucket_name   = "basic-bucket-${random_id.basic_suffix.hex}"
  force_destroy = true

  #Configure access logging to a separate logging bucket
  logging = {
    target_bucket = module.logging_s3.bucket_id
    target_prefix = "s3-access-logs/basic-bucket-${random_id.basic_suffix.hex}/"
  }

  tags = {
    Environment = "dev"
    Purpose     = "Example"
  }
}

output "basic_s3_id" {
  description = "The ID of the S3 Basic bucket."
  value       = module.basic_s3.bucket_id
}

output "logging_s3_id" {
  description = "The ID of the S3 Logging bucket."
  value       = module.logging_s3.bucket_id
}
