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
    
}

resource "aws_lambda_permission" "allow-s3" {
    statement_id = "AllowExecutionFromS3Bucket"
    action = "lambda:InvokeFunction"
    function_name = aws_lambda_function.lambda-s3.function_name
    principal = "s3.amazonaws.com"
    source_arn = aws_s3_bucket.technoinput.arn
}

resource "aws_lambda_event_source_mapping" "allow-s3" {
  event_source_arn = aws_kinesis_stream.techno-kinesis.arn
  function_name = aws_lambda_function.lambda-s3.arn
  starting_position  = "LATEST"
  batch_size = 100
  maximum_batching_window_in_seconds = 5
  parallelization_factor = 2

  destination_config {
    on_failure {
      destination_arn = aws_sns_topic.techno-sns.arn
    }
  }
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
    action = "lambda:Invokefunction"
    function_name = aws_lambda_function.POST.function_name
    principal = "apigateway.amazonaws.com"
    source_arn = "arn:aws:execute-api:us-east-1:126189343233:${aws_api_gateway_rest_api.rest-api.id}/*/*"

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
    filename = data.archive_file.lambda_get_zip.output_path
    role = "arn:aws:iam::126189343233:role/LabRole"
    runtime = "python3.11"
    handler = "lambda_get.lambda_handler"
    source_code_hash = data.archive_file.lambda_get_zip.output_base64sha256
}

resource "aws_lambda_permission" "allowdynamodbget" {
    statement_id = "AllowExecutionFromDynamoDB"
    action = "lambda:Invokefunctioon"
    function_name = aws_lambda_function.GET.function_name
    principal = "apigateway.amazonaws.com"
    source_arn = "arn:aws:execute-api:us-east-1:126189343233:${aws_api_gateway_rest_api.rest-api.id}/*/*"

}

