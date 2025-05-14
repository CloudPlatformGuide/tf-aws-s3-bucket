# Example: Basic S3 Bucket Creation with versioning and access logging
module "basic_s3" {
  source      = "../.."
  bucket_name = "example-basic-bucket"

  # Enable versioning with MFA delete disabled
  versioning = {
    enabled    = true
    mfa_delete = false
  }

  # Configure access logging to a separate logging bucket
  logging = {
    target_bucket = "logging-bucket-name"
    target_prefix = "s3-access-logs/example-basic-bucket/"
  }

  tags = {
    Environment = "dev"
    Purpose     = "Example"
  }
}
