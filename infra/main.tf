terraform {
    // Terraform version constraint
    required_version = ">= 1.5.0"

    // Required providers
    required_providers {
        aws = { 
            source = "hashicorp/aws"
            version = ">= 5.0.0"
        }
    }
}

// Configure the AWS provider
provider "aws" {
    region = "ap-southeast-1"
}

// Create a DynamoDB table for visitor counting
resource "aws_dynamodb_table" "visitor_counter" {
    // Name of DynamoDB table
    name = "visitor-counter"
    // Set billing mode to on demand (PAY_PER_REQUEST)
    billing_mode = "PAY_PER_REQUEST"
    // Define the primary key for the table
    hash_key = "id"

    // Define the attributes for the DynamoDB table
    attribute {
        // Name of the attribute
        name = "id"
        // Type of the attribute (String)
        type = "S"
    }
}