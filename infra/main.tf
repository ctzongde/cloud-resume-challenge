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

    # Configure the backend to use AWS S3 for storing terraform state files and DynamoDB for state locking
    backend "s3" {
        # S3 bucket name for storing terraform state files
        bucket = "cloudresume-terraform-state-aaaa"
        # S3 key for the terraform state file
        key = "backend/terraform.tfstate"
        # aws region where the s3 bucket is located
        region = "ap-southeast-1"
        # DynamoDB table name for state locking
        dynamodb_table = "terraform-state-lock"
        # Enable encryption for the state file in S3
        encrypt = true
    }

    # comment to test backend v4
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
    source_file = "/Users/aaaa/Code/CloudResumeChallenge/backend/retrieveVisitorCountPython.py"
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

# API Gateway to trigger the Lambda function when the website is accessed
# HTTP API > Integration > Route > Stage > Deployment
# Create an API Gateway HTTP API
resource "aws_apigatewayv2_api" "visitor_counter_api"{
    name = "visitor-counter-api"
    protocol_type = "HTTP"

    # CORS configuration to allow cross-origin requests from the website to the API Gateway endpoint
    cors_configuration {
        allow_origins = ["*"]
        allow_methods = ["GET", "OPTIONS"]
        allow_headers = ["*"]
    }
}

# Create an integration between API Gateway and the Lambda function
resource "aws_apigatewayv2_integration" "visitor_counter_integration" {
    # the API Gateway to integrate with
    api_id = aws_apigatewayv2_api.visitor_counter_api.id
    # type of integration set to AWS_PROXY to allow API Gateway to proxy requests directly to the Lambda function
    integration_type = "AWS_PROXY"
    # the Lambda function to integrate with
    integration_uri = aws_lambda_function.visitor_counter_function.arn
    # expects the Lambda function to return a response in the format expected by API Gateway
    payload_format_version = "2.0"
}

# Create a route in API Gateway to trigger the Lambda function when the root path is accessed
resource "aws_apigatewayv2_route" "visior_counter_route" {
    # the API Gateway to create the route for
    api_id = aws_apigatewayv2_api.visitor_counter_api.id
    # the route key defines the HTTP method and path that will trigger this route. 
    route_key = "GET /count"
    # the integration to trigger when this route is accessed
    target = "integrations/${aws_apigatewayv2_integration.visitor_counter_integration.id}"
}

# stage to deploy the API Gateway
resource "aws_apigatewayv2_stage" "visitor_counter_stage" {
    # the API Gateway ID to create the stage for
    api_id = aws_apigatewayv2_api.visitor_counter_api.id
    # name of the stage
    name = "prod"
    # auto deploy changes to the stage when the API Gateway configuration changes
    auto_deploy = true
}

# "aws_lambda_permission" resource to allow API Gateway to invoke the Lambda function
resource "aws_lambda_permission" "apigw_lambda_permission" {
    # the Lambda function to allow API Gateway to invoke
    function_name = aws_lambda_function.visitor_counter_function.function_name
    # a unique identifier for this permission statement
    statement_id = "AllowAPIGatewayInvoke"
    # the action that API Gateway is allowed to perform on the Lambda function
    action = "lambda:InvokeFunction"
    # the principal that is allowed to invoke the Lambda function, which is the API Gateway service
    principal = "apigateway.amazonaws.com"
    # the source ARN specifies which API Gateway routes are allowed to invoke the Lambda function
    source_arn = "${aws_apigatewayv2_api.visitor_counter_api.execution_arn}/*/*"
}