# Terraform module to create an S3 bucket with various configurations
# including versioning, encryption, logging, and notifications.

data "aws_caller_identity" "current" {}

resource "aws_s3_bucket" "this" {
  bucket        = var.bucket_name
  force_destroy = var.force_destroy
  tags          = var.tags
}

resource "aws_s3_bucket_lifecycle_configuration" "this" {
  count  = length(var.lifecycle_rules) > 0 ? 1 : 0
  bucket = aws_s3_bucket.this.id
  dynamic "rule" {
    for_each = var.lifecycle_rules
    content {
      status = lookup(rule.value, "enabled", true)
      id     = lookup(rule.value, "id", null)
      dynamic "transition" {
        for_each = lookup(rule.value, "transitions", [])
        content {
          days          = lookup(transition.value, "days", null)
          storage_class = lookup(transition.value, "storage_class", null)
        }
      }
      dynamic "expiration" {
        for_each = lookup(rule.value, "expiration", [])
        content {
          days = lookup(expiration.value, "days", null)
        }
      }
    }

  }
}

resource "aws_s3_bucket_logging" "this" {
  count         = var.logging != null ? 1 : 0
  bucket        = aws_s3_bucket.this.id
  target_bucket = var.logging.target_bucket
  target_prefix = lookup(var.logging, "target_prefix", null)
}

resource "aws_s3_bucket_versioning" "this" {
  count  = var.versioning != null ? 1 : 0
  bucket = aws_s3_bucket.this.id
  versioning_configuration {
    status     = var.versioning.enabled ? "Enabled" : "Suspended"
    mfa_delete = var.versioning.mfa_delete ? "Enabled" : "Disabled"
  }
}

resource "aws_s3_bucket_website_configuration" "this" {
  count  = var.website != null ? 1 : 0
  bucket = aws_s3_bucket.this.id
  index_document {
    suffix = var.website.index_document
  }
  error_document {
    key = lookup(var.website, "error_document", null)
  }
  routing_rule {
    condition {
      key_prefix_equals = "/"
    }
    redirect {
      replace_key_prefix_with = "index.html"
    }
  }
}

resource "aws_kms_key" "this" {
  count                   = var.create_kms_key ? 1 : 0
  description             = var.kms_key_description
  deletion_window_in_days = 7
  enable_key_rotation     = true
}

resource "aws_kms_alias" "this" {
  count         = var.create_kms_key && var.kms_key_alias != null ? 1 : 0
  name          = "alias/${var.kms_key_alias}"
  target_key_id = aws_kms_key.this[0].key_id
  depends_on    = [aws_kms_key.this]
}

locals {
  # Determine S3 bucket kms key based on whether a customer managed key is created
  effective_encryption = var.create_kms_key ? {
    sse_algorithm     = "aws:kms"
    kms_master_key_id = aws_kms_key.this[0].arn
  } : var.encryption
}

resource "aws_s3_bucket_server_side_encryption_configuration" "this" {
  count  = local.effective_encryption != null ? 1 : 0
  bucket = aws_s3_bucket.this.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = local.effective_encryption.sse_algorithm
      kms_master_key_id = lookup(local.effective_encryption, "kms_master_key_id", null)
    }
  }
}

resource "aws_s3_bucket_public_access_block" "this" {
  count                   = var.public_access_block != null ? 1 : 0
  bucket                  = aws_s3_bucket.this.id
  block_public_acls       = lookup(var.public_access_block, "block_public_acls", true)
  block_public_policy     = lookup(var.public_access_block, "block_public_policy", true)
  ignore_public_acls      = lookup(var.public_access_block, "ignore_public_acls", true)
  restrict_public_buckets = lookup(var.public_access_block, "restrict_public_buckets", true)
}

resource "aws_s3_bucket_replication_configuration" "this" {
  count  = var.replication != null ? 1 : 0
  bucket = aws_s3_bucket.this.id
  role   = var.replication.role
  rule {
    id     = var.replication.rule.id
    status = var.replication.rule.status
    filter {
      prefix = lookup(var.replication.rule, "prefix", null)
    }
    destination {
      bucket        = var.replication.rule.destination.bucket
      storage_class = lookup(var.replication.rule.destination, "storage_class", null)
    }
  }
}

resource "aws_s3_bucket_notification" "this" {
  count  = var.notifications != null ? 1 : 0
  bucket = aws_s3_bucket.this.id
  dynamic "lambda_function" {
    for_each = lookup(var.notifications, "lambda_functions", [])
    content {
      lambda_function_arn = lambda_function.value.arn
      events              = lambda_function.value.events
      filter_prefix       = lookup(lambda_function.value, "filter_prefix", null)
      filter_suffix       = lookup(lambda_function.value, "filter_suffix", null)
    }
  }
  dynamic "topic" {
    for_each = lookup(var.notifications, "topics", [])
    content {
      topic_arn     = topic.value.arn
      events        = topic.value.events
      filter_prefix = lookup(topic.value, "filter_prefix", null)
      filter_suffix = lookup(topic.value, "filter_suffix", null)
    }
  }
  dynamic "queue" {
    for_each = lookup(var.notifications, "queues", [])
    content {
      queue_arn     = queue.value.arn
      events        = queue.value.events
      filter_prefix = lookup(queue.value, "filter_prefix", null)
      filter_suffix = lookup(queue.value, "filter_suffix", null)
    }
  }
}




# Create individual policy documents

locals {
  # Determine if we need to create a policy - this is known at plan time
  has_policies = (var.policy != null || var.website != null || var.is_logging_bucket != null)

}

### Base Policy Document
data "aws_iam_policy_document" "base_policy" {
  count = var.policy != null ? 1 : 0
  # Use the provided policy as a base
  source_policy_documents = [var.policy]
}

## Bucket Website Policy
data "aws_iam_policy_document" "website" {
  count = var.website != null ? 1 : 0
  statement {
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.this.arn}/*"]
    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
  }
}

### S3 Bucket Logging Policy
data "aws_iam_policy_document" "logging" {
  count = var.is_logging_bucket ? 1 : 0
  statement {
    actions   = ["s3:PutObject"]
    resources = ["arn:aws:s3:::${var.bucket_name}/*"]
    principals {
      type        = "Service"
      identifiers = ["logging.s3.amazonaws.com"]
    }
    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [data.aws_caller_identity.current.account_id]
    }
  }
}

# Combine policies using source_policy_documents approach
data "aws_iam_policy_document" "combined_policy" {
  count = local.has_policies ? 1 : 0

  # Ensure at least one valid statement exists
  statement {
    sid       = "DefaultStatement"
    effect    = "Allow"
    actions   = ["s3:ListBucket"]
    resources = [aws_s3_bucket.this.arn]
    principals {
      type        = "AWS"
      identifiers = [data.aws_caller_identity.current.arn]
    }
  }

  # Combine the policies into a single document, removing null values with compact
  source_policy_documents = compact([
    var.policy != null ? var.policy : null,
    var.website != null ? data.aws_iam_policy_document.website[0].json : null,
    var.is_logging_bucket ? data.aws_iam_policy_document.logging[0].json : null,
    # Add more policy documents here as needed
  ])
}


# Use the policy with S3 bucket, if null no S3 bucket policy is created
resource "aws_s3_bucket_policy" "bucket_policy" {
  count  = local.has_policies ? 1 : 0
  bucket = aws_s3_bucket.this.id
  policy = data.aws_iam_policy_document.combined_policy[0].json
}

