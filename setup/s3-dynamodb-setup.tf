provider "aws" {
  region = var.region
  access_key = var.aws_access_key != "" ? var.aws_access_key : null
  secret_key = var.aws_secret_key != "" ? var.aws_secret_key : null
}

resource "aws_s3_bucket" "tf_state" {
  bucket = "${var.project_name}-tf-state"

  versioning {
    enabled = true
  }

  # lifecycle {
  #   prevent_destroy = true
  # }

  tags = {
    Name = "${var.project_name}-tf-state"
  }
}

resource "aws_dynamodb_table" "tf_lock" {
  name         = "${var.project_name}-tf-lock"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = {
    Name = "${var.project_name}-tf-lock"
  }
}
