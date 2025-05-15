variable "bucket_name" {
  description = "The name of the S3 bucket. Must be globally unique."
  type        = string
}

variable "force_destroy" {
  description = "A boolean that indicates all objects should be deleted from the bucket so that the bucket can be destroyed without error."
  type        = bool
  default     = false
}


variable "tags" {
  description = "A map of tags to assign to the bucket."
  type        = map(string)
  default     = {}
}

variable "versioning" {
  description = "Versioning configuration for the bucket."
  type = object({
    enabled    = bool
    mfa_delete = optional(bool, false)
  })
  default = {
    enabled    = false
    mfa_delete = false
  }
}

variable "lifecycle_rules" {
  description = "A list of lifecycle rules for objects in the bucket."
  type = list(object({
    id      = optional(string)
    enabled = optional(bool, true)
    prefix  = optional(string)
    tags    = optional(map(string))
    transitions = optional(list(object({
      days          = number
      storage_class = string
    })), [])
    expiration = optional(list(object({
      days = number
    })), [])
  }))
  default = []
}

variable "logging" {
  description = "Bucket access logging configuration. When enabled, logs will be delivered to the specified target bucket with the provided prefix."
  type = object({
    target_bucket = string
    target_prefix = optional(string, "")
  })
  default = null
}

variable "website" {
  description = "Static website hosting configuration."
  type = object({
    index_document = string
    error_document = optional(string)
  })
  default = null
}

variable "encryption" {
  description = "Server-side encryption configuration. If using a customer managed KMS key, this will be set automatically."
  type = object({
    sse_algorithm     = string
    kms_master_key_id = optional(string)
  })
  default = null
}

variable "create_kms_key" {
  description = "If true, create a customer managed KMS key for S3 bucket encryption."
  type        = bool
  default     = false
}

variable "kms_key_alias" {
  description = "Alias for the customer managed KMS key (if created)."
  type        = string
  default     = null
}

variable "kms_key_description" {
  description = "Description for the customer managed KMS key (if created)."
  type        = string
  default     = "KMS key for S3 bucket encryption"
}

variable "policy" {
  description = "A valid bucket policy JSON document."
  type        = string
  default     = null
}

variable "public_access_block" {
  description = "Public access block configuration."
  type = object({
    block_public_acls       = optional(bool, true)
    block_public_policy     = optional(bool, true)
    ignore_public_acls      = optional(bool, true)
    restrict_public_buckets = optional(bool, true)
  })
  default = null
}

variable "replication" {
  description = "Replication configuration."
  type = object({
    role = string
    rule = object({
      id     = string
      status = string
      prefix = optional(string)
      destination = object({
        bucket        = string
        storage_class = optional(string)
      })
    })
  })
  default = null
}

variable "notifications" {
  description = "Notification configuration for S3 events."
  type = object({
    lambda_functions = optional(list(object({
      arn           = string
      events        = list(string)
      filter_prefix = optional(string)
      filter_suffix = optional(string)
    })), [])
    topics = optional(list(object({
      arn           = string
      events        = list(string)
      filter_prefix = optional(string)
      filter_suffix = optional(string)
    })), [])
    queues = optional(list(object({
      arn           = string
      events        = list(string)
      filter_prefix = optional(string)
      filter_suffix = optional(string)
    })), [])
  })
  default = null
}
