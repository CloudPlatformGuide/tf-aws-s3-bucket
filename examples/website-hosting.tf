resource "random_id" "website_suffix" {
  byte_length = 4
}

# S3 Bucket with Static Website Hosting
module "website_s3" {
  source        = "../"
  bucket_name   = "example-website-bucket-${random_id.website_suffix.hex}"
  force_destroy = true
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
