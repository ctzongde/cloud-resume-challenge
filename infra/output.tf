output "visitor_counter_api_url" {
    # Output the URL of the API Gateway endpoint to access the visitor counter API
    # The argument value is constructed using the API endpoint from the aws_apigatewayv2_api resource and appending the /count route_key defined in the aws_apigatewayv2_route resource
    value = "${aws_apigatewayv2_api.visitor_counter_api.api_endpoint}/${aws_apigatewayv2_stage.visitor_counter_stage.name}/count"
}