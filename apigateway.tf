resource "aws_api_gateway_rest_api" "rest-api" {
    name = "Techno-API-Akbar"
    
    endpoint_configuration {
        types = ["REGIONAL"]
    }
}


resource "aws_api_gateway_deployment" "restapi" {
    rest_api_id = aws_api_gateway_rest_api.rest-api.id
  
  depends_on = [
    aws_api_gateway_method.GET,
    aws_api_gateway_method.POST,
    aws_api_gateway_integration.GET,
    aws_api_gateway_integration.POST
  ]
}

resource "aws_api_gateway_stage" "dev" {
  deployment_id = aws_api_gateway_deployment.restapi.id
  rest_api_id   = aws_api_gateway_rest_api.rest-api.id
  stage_name    = "dev"
}

# GET
resource "aws_api_gateway_resource" "GET" {
    rest_api_id = aws_api_gateway_rest_api.rest-api.id
    parent_id = aws_api_gateway_rest_api.rest-api.root_resource_id
    path_part = "validate-token"
}

resource "aws_api_gateway_method" "GET" {
    rest_api_id = aws_api_gateway_rest_api.rest-api.id
    resource_id = aws_api_gateway_resource.GET.id
    http_method = "GET"
    authorization = "NONE"
}

resource "aws_api_gateway_integration" "GET" {
    rest_api_id = aws_api_gateway_rest_api.rest-api.id
    resource_id = aws_api_gateway_resource.GET.id
    http_method = aws_api_gateway_method.GET.http_method
    type = "AWS_PROXY"
    uri = aws_lambda_function.GET.invoke_arn
    integration_http_method = "GET"
}


# POST

resource "aws_api_gateway_resource" "POST" {
    rest_api_id = aws_api_gateway_rest_api.rest-api.id
    parent_id = aws_api_gateway_rest_api.rest-api.root_resource_id
    path_part = "generate-token"
}


resource "aws_api_gateway_method" "POST" {
    rest_api_id = aws_api_gateway_rest_api.rest-api.id
    resource_id = aws_api_gateway_resource.POST.id
    http_method = "POST"
    authorization = "NONE"
}


resource "aws_api_gateway_integration" "POST" {
    rest_api_id = aws_api_gateway_rest_api.rest-api.id
    resource_id = aws_api_gateway_resource.POST.id
    http_method = aws_api_gateway_method.POST.http_method
    type = "AWS_PROXY"
    uri = aws_lambda_function.POST.invoke_arn
    integration_http_method = "POST"
}

