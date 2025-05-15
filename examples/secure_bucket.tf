# Example: Secure S3 Bucket Following AWS Security Best Practices
# This example demonstrates how to configure a bucket with security best practices:
# - Server-side encryption with AWS KMS
# - Versioning enabled
# - Access logging
# - Public access blocking
# - Restrictive bucket policy
# - Lifecycle management for compliance

# Create a secure S3 bucket that follows AWS best practices
# module "secure_s3" {
#   source      = "../"
#   bucket_name = "secure-example-bucket"

#   # Enable versioning to protect against accidental deletion and maintain data history
#   versioning = {
#     enabled    = true
#     mfa_delete = true # Enable MFA delete for additional security
#   }

#   # Configure server-side encryption with customer-managed KMS key
#   create_kms_key      = true
#   kms_key_alias       = "alias/secure-bucket-key"
#   kms_key_description = "KMS key for secure S3 bucket encryption"

#   # Enable access logging to track all requests
#   logging = {
#     target_bucket = "central-logging-bucket" # Replace with your actual logging bucket
#     target_prefix = "s3-access-logs/secure-bucket/"
#   }

#   # Block all public access
#   public_access_block = {
#     block_public_acls       = true
#     block_public_policy     = true
#     ignore_public_acls      = true
#     restrict_public_buckets = true
#   }

#   # Configure lifecycle rules for compliance and cost optimization
#   lifecycle_rules = [
#     {
#       id      = "compliance-retention"
#       enabled = true
#       prefix  = "compliance/"
#       transitions = [
#         { days = 90, storage_class = "STANDARD_IA" },
#         { days = 365, storage_class = "GLACIER" }
#       ]
#       # Set retention period to meet compliance requirements
#       expiration = [{ days = 2555 }] # ~7 years
#     },
#     {
#       id      = "log-management"
#       enabled = true
#       prefix  = "logs/"
#       # Move logs to cheaper storage after 30 days
#       transitions = [
#         { days = 30, storage_class = "STANDARD_IA" },
#         { days = 90, storage_class = "GLACIER" }
#       ]
#       # Expire logs after 1 year
#       expiration = [{ days = 365 }]
#     }
#   ]

#   # Example bucket policy that enforces encryption in transit
#   policy = <<EOF
# {
#   "Version": "2012-10-17",
#   "Statement": [
#     {
#       "Sid": "DenyIncorrectEncryptionHeader",
#       "Effect": "Deny",
#       "Principal": "*",
#       "Action": "s3:PutObject",
#       "Resource": "arn:aws:s3:::secure-example-bucket/*",
#       "Condition": {
#         "StringNotEquals": {
#           "s3:x-amz-server-side-encryption": "aws:kms"
#         }
#       }
#     },
#     {
#       "Sid": "DenyUnencryptedObjectUploads",
#       "Effect": "Deny",
#       "Principal": "*",
#       "Action": "s3:PutObject",
#       "Resource": "arn:aws:s3:::secure-example-bucket/*",
#       "Condition": {
#         "Null": {
#           "s3:x-amz-server-side-encryption": "true"
#         }
#       }
#     },
#     {
#       "Sid": "EnforceTLSRequestsOnly",
#       "Effect": "Deny",
#       "Principal": "*",
#       "Action": "s3:*",
#       "Resource": [
#         "arn:aws:s3:::secure-example-bucket",
#         "arn:aws:s3:::secure-example-bucket/*"
#       ],
#       "Condition": {
#         "Bool": {
#           "aws:SecureTransport": "false"
#         }
#       }
#     }
#   ]
# }
# EOF

#   tags = {
#     Environment        = "Production"
#     SecurityLevel      = "High"
#     Compliance         = "HIPAA-HITRUST"
#     DataClassification = "Confidential"
#   }
# }
