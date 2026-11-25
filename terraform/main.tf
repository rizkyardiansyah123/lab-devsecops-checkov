terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "ap-southeast-1"
}

# PERBAIKAN 1: S3 Bucket aman
resource "aws_s3_bucket" "data" {
  bucket = "my-company-data-bucket-secure"
}

resource "aws_s3_bucket_public_access_block" "data" {
  bucket                  = aws_s3_bucket.data.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "data" {
  bucket = aws_s3_bucket.data.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "aws:kms"
    }
  }
}

resource "aws_s3_bucket_versioning" "data" {
  bucket = aws_s3_bucket.data.id
  versioning_configuration {
    status = "Enabled"
  }
}

# PERBAIKAN 2: Security Group terbatas
resource "aws_security_group" "web" {
  name        = "web-sg"
  description = "Security group untuk web server"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/8"]
    description = "SSH akses terbatas dari internal network"
  }

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["10.10.0.0/16"]
    description = "MySQL akses terbatas dari subnet aplikasi"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["10.0.0.0/8"]
    description = "Outbound terbatas ke jaringan internal"
  }
}

# PERBAIKAN 3: IAM least privilege
resource "aws_iam_policy" "s3_read_only" {
  name        = "s3-read-only-policy"
  description = "Read-only access ke S3 bucket tertentu"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:ListBucket",
          "s3:GetBucketLocation"
        ]
        Resource = [
          "arn:aws:s3:::my-company-data-bucket-secure",
          "arn:aws:s3:::my-company-data-bucket-secure/*"
        ]
      }
    ]
  })
}

# PERBAIKAN 4: Variable sensitif dan RDS aman
variable "db_password" {
  description = "Password untuk database RDS"
  type        = string
  sensitive   = true
}

resource "aws_db_instance" "main" {
  identifier                = "mydb-secure"
  engine                    = "mysql"
  engine_version            = "8.0"
  instance_class            = "db.t3.micro"
  allocated_storage         = 20
  username                  = "admin"
  password                  = var.db_password
  publicly_accessible       = false
  storage_encrypted         = true
  deletion_protection       = true
  backup_retention_period   = 7
  skip_final_snapshot       = false
  final_snapshot_identifier = "mydb-final-snapshot"
}

# PERBAIKAN 5: EC2 dengan EBS terenkripsi dan IMDSv2
resource "aws_instance" "web" {
  ami           = "ami-0c02fb55956c7d316"
  instance_type = "t3.micro"

  root_block_device {
    encrypted   = true
    volume_type = "gp3"
  }

  metadata_options {
    http_tokens = "required"
  }
}
