output "api_gateway_url" {
    value = "https://${aws_api_gateway_rest_api.API.id}.execute-api.us-east-1.amazonaws.com/${aws_api_gateway_stage.techno-stage.stage_name}"
}