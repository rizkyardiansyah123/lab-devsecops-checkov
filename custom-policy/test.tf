# 1. S3 tanpa tag wajib (harus FAILED)
resource "aws_s3_bucket" "no_tags" {
  bucket = "bucket-without-tags"
}

# 2. S3 dengan tag tidak lengkap (harus FAILED)
resource "aws_s3_bucket" "partial_tags" {
  bucket = "bucket-partial-tags"
  tags = {
    owner = "devops-team"
  }
}

# 3. S3 dengan tag lengkap (harus PASSED)
resource "aws_s3_bucket" "full_tags" {
  bucket = "bucket-with-all-tags"
  tags = {
    owner       = "devops-team"
    environment = "production"
    project     = "ecommerce"
  }
}
