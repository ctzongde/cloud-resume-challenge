# Provision of AWS S3 bucket and DynamoDB for storing terraform state files to prevent state file corruption and enable collaboration among team members

terraform { 
    required_version = ">=1.5.0"
    required_providers {
        aws = {
            source = "hashicorp/aws"
            version = "~> 5.0"
        }
    }
}

provider "aws" {
    region = "ap-southeast-1"
}

resource "aws_s3_bucket" "terraform_state" {
    # S3 bucket name for storing terraform state files
    bucket = "cloudresume-terraform-state-aaaa"
}

resource "aws_s3_bucket_versioning" "terraform_state_versioning" {
    bucket = aws_s3_bucket.terraform_state.id

    versioning_configuration {
        status = "Enabled"
    }
}

resource "aws_dynamodb_table" "terraform_lock" {
    # DynamoDB table name for state locking
    name = "terraform-state-lock"
    # Set billing mode to on demand 
    billing_mode = "PAY_PER_REQUEST"
    # Define the primary key for the table
    hash_key = "LockID"
    
    attribute {
        # Name of the attribute
        name = "LockID"
        # Type of attribute (String)
        type = "S"
    }
}