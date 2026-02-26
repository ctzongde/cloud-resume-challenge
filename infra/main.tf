terraform {
    # Terraform version constraint
    required_version = ">= 1.5.0"

    # Required providers
    required_providers {
        aws = { 
            source = "hashicorp/aws"
            version = ">= 5.0.0"
        }
    }
}

# Configure the AWS provider
provider "aws" {
    # AWS region where the resources will be created
    region = "ap-southeast-1"
}

# Create a DynamoDB table for visitor counting
resource "aws_dynamodb_table" "visitor_counter" {
    # Name of DynamoDB table
    name = "visitor-counter"
    # Set billing mode to on demand (PAY_PER_REQUEST)
    billing_mode = "PAY_PER_REQUEST"
    # Define the primary key for the table
    hash_key = "id"

    # Define the attributes for the DynamoDB table
    attribute {
        # Name of the attribute
        name = "id"
        # Type of the attribute (String)
        type = "S"
    }
}

# Lambda IAM role to allow Lambda function to access DynamoDB
resource "aws_iam_role" "lambda_role" {
    # Name of the IAM role
    name = "lambda-role"
    # Assume role policy to allow Lambda service to assume this role
    # jsonencode is used to convert the policy into a JSON string format
    assume_role_policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
            {
                Effect = "Allow",
                Principal = {
                    Service = "lambda.amazonaws.com"
                },
                Action = "sts:AssumeRole"
            }
        ]
    })
}

# Attach a policy to the IAM role to allow it to access the DynamoDB table
resource "aws_iam_role_policy" "lambda_policy" {
    # Name of the IAM role policy
    name = "lambda-policy"
    # The IAM role to attach this policy to
    role = aws_iam_role.lambda_role.id

    # Define the policy that allows the Lambda function to get and update items
    # jsonencode is used to convert the policy into a JSON string format
    policy = jsonencode({
        "Version" = "2012-10-17",
        "Statement" = [
            {
                "Effect" = "Allow",
                "Action" = [
                    "dynamodb:GetItem",
                    "dynamodb:UpdateItem"
                ],
                "Resource" = [
                    aws_dynamodb_table.visitor_counter.arn
                ]
            }
        ]
    })
}

# CloudWatch Logs IAM role policy to allow Lambda function to write logs to CloudWatch
resource "aws_iam_role_policy_attachment" "lambda_logs" {
    # Name of IAM role policy attachment
    role = aws_iam_role.lambda_role.name
    # ARN of the AWS managed policy for Lambda basic execution role, which allows writing logs to CloudWatch
    policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# Package Lambda function code into a zip file
data "archive_file" "visitor_counter_zip" {
    # type of archive set to zip
    type = "zip"
    # file path to the lambda function source code
    source_file = "/Users/aaaa/Code/CloudResumeChallenge/retrieveVisitorCountPython.py"
    # file path to the output zip file
    output_path = "${path.module}/retrieveVisitorCountPython.zip"
}

# Create a Lambda function to handle visitor counting
resource "aws_lambda_function" "visitor_counter_function" {
    function_name = "visitor-counter-function"

    # Lambda IAM role to allow the function to access DynamoDB and write logs to CloudWatch
    role = aws_iam_role.lambda_role.arn
    
    # Run time environment for the Lambda function
    runtime = "python3.14"

    # Lambda function handler: file name and function name within the file
    handler = "retrieveVisitorCountPython.lambda_handler"

    # file path to the zip file containing the Lambda function code
    filename = data.archive_file.visitor_counter_zip.output_path

    # source code hash to ensure Lambda function is updated when the source code changes
    source_code_hash = data.archive_file.visitor_counter_zip.output_base64sha256

    # Ensure that the Lambda function is created after the IAM role and policies are in place
    depends_on = [
        aws_iam_role_policy.lambda_policy,
        aws_iam_role_policy_attachment.lambda_logs
    ]
}