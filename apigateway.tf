resource "aws_api_gateway_rest_api" "rest-api" {
    name = "Techno-API-Akbar"
    
    endpoint_configuration {
        types = ["REGIONAL"]
    }
}

# GET
resource "aws_api_gateway_resource" "GET" {
    rest_api_id = aws_api_gateway_rest_api.rest-api.id
    parent_id = aws_api_gateway_rest_api.rest-api.root_resource_id
    path_part = "validate-token"
}

resource "aws_api_gateway_method" "method-get" {
    rest_api_id = aws_api_gateway_rest_api.rest-api.id
    resource_id = aws_api_gateway_resource.GET.id
    http_method = "GET"
    authorization = "NONE"
}

resource "aws_api_gateway_integration" "inter-get" {
    rest_api_id = aws_api_gateway_rest_api.rest-api.id
    resource_id = aws_api_gateway_resource.GET.id
    http_method = aws_api_gateway_method.method-get.http_method
    type = "AWS_PROXY"
    uri = aws_lambda_function.GET.invoke_arn
    integration_http_method = "POST"
}


# POST

resource "aws_api_gateway_resource" "POST" {
    rest_api_id = aws_api_gateway_rest_api.rest-api.id
    parent_id = aws_api_gateway_rest_api.rest-api.root_resource_id
    path_part = "generate-token"
}


resource "aws_api_gateway_method" "method-post" {
    rest_api_id = aws_api_gateway_rest_api.rest-api.id
    resource_id = aws_api_gateway_resource.POST.id
    http_method = "POST"
    authorization = "NONE"
}


resource "aws_api_gateway_integration" "inter-post" {
    rest_api_id = aws_api_gateway_rest_api.rest-api.id
    resource_id = aws_api_gateway_resource.POST.id
    http_method = aws_api_gateway_method.method-post.http_method
    type = "AWS_PROXY"
    uri = aws_lambda_function.POST.invoke_arn
    integration_http_method = "POST"
}

resource "aws_api_gateway_deployment" "restapi" {
    rest_api_id = aws_api_gateway_rest_api.rest-api.id
  
  depends_on = [
    aws_api_gateway_method.method-get,
    aws_api_gateway_method.method-post,
    aws_api_gateway_integration.inter-get,
    aws_api_gateway_integration.inter-post
  ]
}

resource "aws_api_gateway_stage" "dev" {
  deployment_id = aws_api_gateway_deployment.restapi.id
  rest_api_id   = aws_api_gateway_rest_api.rest-api.id
  stage_name    = "dev"
}