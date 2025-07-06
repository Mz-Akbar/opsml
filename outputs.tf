output "api_gateway_url" {
  value = "https://${aws_api_gateway_rest_api.rest-api.id}.execute-api.us-east-1.amazonaws.com/${aws_api_gateway_stage.dev.stage_name}"
}
