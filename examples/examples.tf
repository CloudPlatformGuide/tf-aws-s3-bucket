# # Example 1: Basic S3 Bucket Creation
# module "basic_s3" {
#   source      = "../"
#   bucket_name = "example-basic-bucket-${random_id.suffix.hex}"
#   tags = {
#     Environment = "dev"
#   }
# }

# # Example 2: S3 Bucket with Versioning and Lifecycle Rules
# module "versioned_s3" {
#   source      = "../"
#   bucket_name = "example-versioned-bucket-${random_id.suffix.hex}"
#   versioning = {
#     enabled    = true
#     mfa_delete = false
#   }
#   lifecycle_rules = [
#     {
#       id          = "expire-logs"
#       enabled     = true
#       prefix      = "logs/"
#       transitions = [{ days = 30, storage_class = "GLACIER" }]
#       expiration  = [{ days = 365 }]
#     }
#   ]
# }

# # Example 3: S3 Bucket with Server-Side Encryption (AWS managed key)
# module "encrypted_s3" {
#   source      = "../"
#   bucket_name = "example-encrypted-bucket-${random_id.suffix.hex}"
#   encryption = {
#     sse_algorithm = "AES256"
#   }
# }

# # Example 3b: S3 Bucket with Customer Managed KMS Key
# module "customer_kms_s3" {
#   source         = "../"
#   bucket_name    = "example-customer-kms-bucket-${random_id.suffix.hex}"
#   create_kms_key = true
#   kms_key_alias  = "example-customer-kms-bucket-${random_id.suffix.hex}"
#   tags = {
#     Purpose = "Customer KMS Key Example"
#   }
# }

# # Example 4: S3 Bucket with Logging and Notification Configuration
# module "logging_notify_s3" {
#   source      = "../"
#   bucket_name = "example-logging-notify-bucket-${random_id.suffix.hex}"
#   logging = {
#     target_bucket = module.basic_s3.bucket_id
#     target_prefix = "log/"
#   }
#   notifications = {
#     lambda_functions = [
#       {
#         arn    = "arn:aws:lambda:us-east-1:123456789012:function:ProcessS3Event"
#         events = ["s3:ObjectCreated:*"]
#       }
#     ]
#   }
# }

# # Example 5: S3 Bucket with Tags and Access Control List (ACL)
# module "tagged_acl_s3" {
#   source      = "../"
#   bucket_name = "example-tagged-acl-bucket-${random_id.suffix.hex}"
#   acl         = "public-read"
#   tags = {
#     Project = "Demo"
#     Owner   = "user@example.com"
#   }
# }

# # Example 6: S3 Bucket with Cross-Region Replication
# module "replicated_s3" {
#   source      = "../"
#   bucket_name = "example-replicated-bucket-${random_id.suffix.hex}"
#   replication = {
#     role = "arn:aws:iam::123456789012:role/s3-replication-role"
#     rule = {
#       id     = "replication-rule"
#       status = "Enabled"
#       destination = {
#         bucket        = "arn:aws:s3:::destination-bucket"
#         storage_class = "STANDARD"
#       }
#     }
#   }
# }



# # Example 7: S3 Bucket with Custom Domain and Static Website Hosting
module "website_s3" {
  source      = "../"
  bucket_name = "example-website-bucket-${random_id.suffix.hex}"
  public_access_block = {
    block_public_acls       = false
    block_public_policy     = false
    ignore_public_acls      = false
    restrict_public_buckets = false
  }
  website = {
    index_document = "index.html"
    error_document = "error.html"
  }
}
### Upload a index.html file to the bucket
resource "aws_s3_object" "index" {
  bucket       = module.website_s3.bucket_id
  key          = "index.html"
  source       = "content/index.html"
  content_type = "text/html"
}

### Upload a error.html file to the bucket
resource "aws_s3_object" "error" {
  bucket       = module.website_s3.bucket_id
  key          = "error.html"
  source       = "content/error.html"
  content_type = "text/html"
}

## Outputs for the website S3 bucket
output "Website-S3bucket-id" {
  description = "The ID of the static website S3 bucket."
  value       = module.website_s3.bucket_id
}
output "Website-S3bucket-url" {
  description = "The URL of the static website."
  value       = "http://${module.website_s3.bucket_domain_name}/index.html"
}


# # Example 8: S3 Bucket with Event Notifications and Lambda Function
# module "event_lambda_s3" {
#   source      = "../"
#   bucket_name = "example-event-lambda-bucket-${random_id.suffix.hex}"
#   notifications = {
#     lambda_functions = [
#       {
#         arn    = "arn:aws:lambda:us-east-1:123456789012:function:AnotherLambda"
#         events = ["s3:ObjectRemoved:*"]
#       }
#     ]
#   }
# }

# # Example 9: S3 Bucket with Versioning, Logging, and Encryption (Complete Example)
# module "complete_s3" {
#   source      = "../"
#   bucket_name = "example-complete-bucket-${random_id.suffix.hex}"

#   # Versioning configuration
#   versioning = {
#     enabled    = true
#     mfa_delete = false
#   }

#   # Logging configuration
#   logging = {
#     target_bucket = module.basic_s3.bucket_id
#     target_prefix = "access-logs/complete-bucket/"
#   }

#   # Server-side encryption
#   encryption = {
#     sse_algorithm     = "aws:kms"
#     kms_master_key_id = "arn:aws:kms:us-east-1:123456789012:key/example-key-id"
#   }

#   # Lifecycle rules
#   lifecycle_rules = [
#     {
#       id      = "transition-to-ia-and-glacier"
#       enabled = true
#       prefix  = "documents/"
#       transitions = [
#         { days = 30, storage_class = "STANDARD_IA" },
#         { days = 90, storage_class = "GLACIER" }
#       ]
#       expiration = [{ days = 365 }]
#     },
#     {
#       id         = "delete-old-logs"
#       enabled    = true
#       prefix     = "logs/"
#       expiration = [{ days = 90 }]
#     }
#   ]

#   # Access control
#   public_access_block = {
#     block_public_acls       = true
#     block_public_policy     = true
#     ignore_public_acls      = true
#     restrict_public_buckets = true
#   }

#   tags = {
#     Environment = "production"
#     Department  = "IT"
#     Project     = "Data Storage"
#     Compliance  = "HIPAA"
#   }
# }

resource "random_id" "suffix" {
  byte_length = 4
}

