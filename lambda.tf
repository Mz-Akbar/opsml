# lambda s3
data "archive_file" "lambda_s3_zip" {
  type        = "zip"
  source_file = "${path.module}/lambda_s3.py"
  output_path = "${path.module}/lambda_s3.zip"
}

resource "aws_lambda_function" "lambda-s3" {
    function_name = "techno-lambda-s3"
    timeout = 120
    filename = "lambda_s3.zip"
    role = "arn:aws:iam::126189343233:role/LabRole"
    runtime = "python3.11"
    handler = "lambda_s3.lambda_handler"
    source_code_hash = data.archive_file.lambda_s3_zip.output_base64sha256

    environment {
      variables = {
        SNS_TOPIC_ARN = "arn:aws:sns:us-east-1:126189343233:techno-sns-payakumbuh-akbar",
        KINESIS_STREAM_NAME = "techno-kinesis-Akbar",
        DEST_BUCKET = "technooutput-payakumbuh-akbar"
      }
    }
    
}

resource "aws_lambda_permission" "allow-s3" {
    statement_id = "AllowExecutionFromS3Bucket"
    action = "lambda:InvokeFunction"
    function_name = aws_lambda_function.lambda-s3.function_name
    principal = "s3.amazonaws.com"
    source_arn = aws_s3_bucket.technoinput.arn
}

# lambda POST

data "archive_file" "lambda_post_zip" {
  type        = "zip"
  source_file = "${path.module}/lambda_post.py"
  output_path = "${path.module}/lambda_post.zip"
}

resource "aws_lambda_function" "POST" {
    function_name = "techno-lambda-post"
    timeout = 60
    filename = "lambda_post.zip"
    role = "arn:aws:iam::126189343233:role/LabRole"
    runtime = "python3.11"
    handler = "lambda_post.lambda_handler"
    source_code_hash = data.archive_file.lambda_post_zip.output_base64sha256

    environment {
      variables = {
        TOKEN_TABLE = "Token"
    }
  }
}

resource "aws_lambda_permission" "allowdynamodbpost" {
    statement_id = "AllowExecutionFromDynamoDB"
    action = "lambda:InvokeFunction"
    function_name = aws_lambda_function.POST.function_name
    principal = "apigateway.amazonaws.com"
    source_arn = "${aws_api_gateway_rest_api.rest-api.execution_arn}/*/*"

}


# lambda Get

data "archive_file" "lambda_get_zip" {
  type        = "zip"
  source_file = "${path.module}/lambda_get.py"
  output_path = "${path.module}/lambda_get.zip"
}

resource "aws_lambda_function" "GET" {
    function_name = "techno-lambda-get"
    timeout = 90
    filename = "lambda_get.zip"
    role = "arn:aws:iam::126189343233:role/LabRole"
    runtime = "python3.11"
    handler = "lambda_get.lambda_handler"
    source_code_hash = data.archive_file.lambda_get_zip.output_base64sha256

     environment {
      variables = {
        TOKEN_TABLE = "Token"
    }
  }
}

resource "aws_lambda_permission" "allowdynamodbget" {
    statement_id = "AllowExecutionFromDynamoDB"
    action = "lambda:InvokeFunction"
    function_name = aws_lambda_function.GET.function_name
    principal = "apigateway.amazonaws.com"
    source_arn = "${aws_api_gateway_rest_api.rest-api.execution_arn}/*/*"

}

