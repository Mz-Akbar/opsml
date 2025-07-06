resource "aws_api_gateway_rest_api" "rest-api" {
    name = "Techno-API-Akbar"
    
    endpoint_configuration {
        types = ["REGIONAL"]
    }

    body = jsonencode({
        openapi = "3.0.1"
        info = {
            title = "Techno-API"
            version = "1.0"
        }

        paths = {
            "/generate-token" = {
                post = {
                    x-amazon-apigateway-integration = {
                        httpMethod = "POST"
                        payloadFormatVersion = "1.0"
                        type = "AWS_PROXY"
                        uri = "arn:aws:apigateway:us-east-1:lambda:path/2015-03-31/functions/${aws_lambda_function.POST.arn}/invocations"
                    }
                }
            }

            "/validate-token" = {
                get = {
                    x-amazon-apigateway-integration = {
                        type = "AWS_PROXY"
                        httpMethod = "GET"
                        uri = "arn:aws:apigateway:us-east-1:lambda:path/2015-03-31/functions/${aws_lambda_function.GET.arn}/invocations"
                        payloadFormatVersion = "2.0"
                    }   
                }
            }
        }
    })
}

resource "aws_api_gateway_deployment" "restapi" {
    rest_api_id = aws_api_gateway_rest_api.rest-api.id

 triggers = {
    redeployment = sha1(jsonencode(aws_api_gateway_rest_api.rest-api.body))
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_api_gateway_stage" "dev" {
  deployment_id = aws_api_gateway_deployment.restapi.id
  rest_api_id   = aws_api_gateway_rest_api.rest-api.id
  stage_name    = "dev"
}