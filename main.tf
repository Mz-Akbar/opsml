# VPC
resource "aws_vpc" "techno-vpc" {
    cidr_block = "25.1.0.0/16"
    enable_dns_support = true
    enable_dns_hostnames = true
    assign_generated_ipv6_cidr_block = true

    tags = {
        Name = "techno-akbar"
    }
}

resource "aws_subnet" "Public-A" {
    vpc_id = aws_vpc.techno-vpc.id
    cidr_block = "25.1.0.0/24"
    assign_ipv6_address_on_creation = true
    availability_zone = "us-east-1a"
    ipv6_cidr_block = cidrsubnet(aws_vpc.techno-vpc.ipv6_cidr_block, 8, 0)
    map_public_ip_on_launch = true
    enable_resource_name_dns_a_record_on_launch = true
    enable_resource_name_dns_aaaa_record_on_launch = true
}

resource "aws_subnet" "Public-B" {
    vpc_id = aws_vpc.techno-vpc.id
    cidr_block = "25.1.2.0/24"
    assign_ipv6_address_on_creation = true
    availability_zone = "us-east-1b"
    ipv6_cidr_block = cidrsubnet(aws_vpc.techno-vpc.ipv6_cidr_block, 8, 1)
    map_public_ip_on_launch = true
    enable_resource_name_dns_a_record_on_launch = true
    enable_resource_name_dns_aaaa_record_on_launch = true
}

resource "aws_subnet" "Private-A" {
    vpc_id = aws_vpc.techno-vpc.id
    cidr_block = "25.1.1.0/24"
    availability_zone = "us-east-1a"
   
}

resource "aws_subnet" "Private-B" {
    vpc_id = aws_vpc.techno-vpc.id
    cidr_block = "25.1.3.0/24"
    availability_zone = "us-east-1b"
}

resource "aws_internet_gateway" "techno-igw" {
    vpc_id = aws_vpc.techno-vpc.id
}

resource "aws_route_table" "techno-rt" {
    vpc_id = aws_vpc.techno-vpc.id
    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.techno-igw.id
    }

    route {
        ipv6_cidr_block = "::/0"
        gateway_id = aws_internet_gateway.techno-igw.id
    }
}

resource "aws_route_table_association" "techno-public-a" {
    route_table_id = aws_route_table.techno-rt.id
    subnet_id = aws_subnet.Public-A.id
}

resource "aws_route_table_association" "techno-public-b" {
    route_table_id = aws_route_table.techno-rt.id
    subnet_id = aws_subnet.Public-B.id
}

resource "aws_eip" "techno-ip" {
    domain = "vpc"
}

resource "aws_nat_gateway" "tehcno-ngw" {
    allocation_id = aws_eip.techno-ip.id
    subnet_id = aws_subnet.Public-A.id
}

resource "aws_route_table" "techno-private" {
    vpc_id = aws_vpc.techno-vpc.id
    route {
        cidr_block = "0.0.0.0/0"
        nat_gateway_id = aws_nat_gateway.tehcno-ngw.id
    }
}

resource "aws_route_table_association" "tehcno-private-a" {
    route_table_id = aws_route_table.techno-private.id
    subnet_id = aws_subnet.Private-A.id
}

resource "aws_route_table_association" "tehcno-private-b" {
    route_table_id = aws_route_table.techno-private.id
    subnet_id = aws_subnet.Private-B.id
}

# Security Group 
resource "aws_security_group" "techno-lb" {
  name        = "techno-sg-lb"
  description = "Allow lb inbound traffic and all outbound traffic"
  vpc_id = aws_vpc.techno-vpc.id

    ingress {
        from_port = 80
        to_port = 80
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    ingress {
        from_port = 443
        to_port = 443
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
}

resource "aws_security_group" "techno-apps" {
  name        = "techno-sg-apps"
  description = "Allow apps inbound traffic and all outbound traffic"
  vpc_id = aws_vpc.techno-vpc.id

    ingress {
        from_port = 2000
        to_port = 2000
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }


    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
}

# IAM Policydata 
data "aws_iam_policy_document" "policy-input" {
    statement {
        principals {
            type        = "AWS"
            identifiers = ["*"]
    }

        actions = [
            "s3:GetObject",
            "s3:PutObject"
        ]

        resources = [
            "${aws_s3_bucket.bucket-input.arn}/*"
        ]
  }
}

data "aws_iam_policy_document" "policy-output" {
    statement {
        principals {
            type        = "AWS"
            identifiers = ["*"]
    }

        actions = [
            "s3:GetObject",
            "s3:PutObject"
        ]

        resources = [
            "${aws_s3_bucket.bucket-output.arn}/*"
        ]
  }
}


# S3
resource "aws_s3_bucket" "bucket-input" {
    bucket = "technoinput-payakumbuh-akbar"
}

resource "aws_s3_bucket_public_access_block" "example" {
    bucket = aws_s3_bucket.bucket-input.id
    block_public_acls = false
    block_public_policy  = false
    ignore_public_acls  = false
    restrict_public_buckets = false
}


resource "aws_s3_bucket_policy" "bucket-input-policies" {
  bucket = aws_s3_bucket.bucket-input.id
  policy = data.aws_iam_policy_document.policy-input.json

  depends_on = [aws_s3_bucket.bucket-input]
}


resource "aws_s3_bucket_lifecycle_configuration" "input" {
  bucket = aws_s3_bucket.bucket-input.id
    
    rule {
        id = "rule-technoinput"
        status = "Enabled"

        filter {
            prefix = ""
        }

        transition {
            days = 30
            storage_class = "GLACIER_IR"
     }

        expiration {
            days = 365
        }
    }
}

resource "aws_s3_bucket" "bucket-output" {
    bucket = "technooutput-payakumbuh-akbar"
}

resource "aws_s3_bucket_public_access_block" "output" {
    bucket = aws_s3_bucket.bucket-output.id
    block_public_acls = false
    block_public_policy  = false
    ignore_public_acls  = false
    restrict_public_buckets = false
}


resource "aws_s3_bucket_policy" "bucket-output-policies" {
  bucket = aws_s3_bucket.bucket-output.id
  policy = data.aws_iam_policy_document.policy-output.json

  depends_on = [aws_s3_bucket.bucket-output]
}


resource "aws_s3_bucket_lifecycle_configuration" "output" {
  bucket = aws_s3_bucket.bucket-input.id
    
    rule {
        id = "rule-technoinput"
        status = "Enabled"

        filter {
            prefix = ""
        }

        transition {
            days = 30
            storage_class = "GLACIER_IR"
     }

        expiration {
            days = 365
        }
    }
}

# Dynamodb
resource "aws_dynamodb_table" "techno-db" {
    name           = "Token"
    billing_mode   = "PAY_PER_REQUEST"
    hash_key       = "token"

    attribute {
        name = "token"
        type = "S"
    }
}

resource "aws_dynamodb_kinesis_streaming_destination" "example" {
  stream_arn = aws_kinesis_stream.techno.arn
  table_name = aws_dynamodb_table.techno-db.name
  approximate_creation_date_time_precision = "MICROSECOND"
}

# Kinesis
resource "aws_kinesis_stream" "techno" {
  name = "techno-kinesis-akbar"
  shard_count = 1
}

# Glue
resource "aws_glue_catalog_database" "tehcno-glue" {
    name = "rekognition_results_db"
}

resource "aws_glue_catalog_table" "aws_glue_catalog_table" {
    name = "rekognition_results_table"
    database_name = "rekognition_results_db"
    table_type = "EXTERNAL_TABLE"
    catalog_id = aws_glue_catalog_database.tehcno-glue.catalog_id

    parameters = {
        EXTERNAL = "TRUE"
        has_encrypted_data = "false"
    }

    storage_descriptor {
        location      = "s3://technooutput-payakumbuh-akbar/result"
        input_format  = "org.apache.hadoop.mapred.TextInputFormat"
        output_format = "org.apache.hadoop.hive.ql.io.IgnoreKeyTextOutputFormat"

        ser_de_info {
            name = "my-stream"
            serialization_library = "org.openx.data.jsonserde.JsonSerDe"

            parameters = {
                "serialization.format" = 1
            }
        }   

            columns {
                name = "image_key"
                type = "string"
            }

            columns {
                name = "labels"
                type = "array<struct<Name:string,Confidence:double>>"
            }
    }
}

resource "aws_glue_crawler" "example" {
    database_name = aws_glue_catalog_database.tehcno-glue.name
    name = "example"
    role   = "arn:aws:iam::919703962183:role/LabRole"

    s3_target {
        path = "s3://${aws_s3_bucket.bucket-output.bucket}"
    }
}

# SNS
resource "aws_sns_topic" "techno-sns" {
    name = "tehno-sms-payakumbuh-akbar"
}

resource "aws_sns_topic_subscription" "techno-sns-susbcription" {
    topic_arn = aws_sns_topic.techno-sns.arn
    protocol  = "email"
    endpoint  = "muhammadzafirulakbar88@gmail.com"
}

# lambda
# Lambda S3 
data "archive_file" "s3" {
  type = "zip"
  source_file = "${path.module}/lambda/lambda_s3.py"
  output_path = "${path.module}/lambda/lambda_s3.zip"
}

resource "aws_lambda_function" "lambda-s3" {
  filename         = "lambda_s3.zip"
  function_name    = "techno-lambda-s3"
  timeout = 120
  role             = "arn:aws:iam::919703962183:role/LabRole"
  handler          = "lambda_s3.lambda_handler"
  source_code_hash = data.archive_file.s3.output_base64sha256
  runtime = "python3.11"

  environment {
    variables = {
        SNS_TOPIC_ARN = "arn:aws:sns:us-east-1:919703962183:tehno-sms-payakumbuh-akbar"
        KINESIS_STREAM_NAME = "techno-kinesis-akbar"
        DEST_BUCKET = "technoinput-payakumbuh-akbar"
    }
  }
}

resource "aws_lambda_permission" "lambda-s3" {
  statement_id  = "AllowExecutionFromS3Bucket"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda-s3.function_name
  principal     = "s3.amazonaws.com"
  source_arn = aws_s3_bucket.bucket-input.arn
}

# Lambda POST
data "archive_file" "post" {
    type = "zip"
    source_file = "${path.module}/lambda/lambda_post.py"
    output_path = "${path.module}/lambda/lambda_post.zip"
}

resource "aws_lambda_function" "lambda-post" {
    filename         = "lambda_post.zip"
    function_name    = "techno-lambda-post"
    timeout = 60
    role             = "arn:aws:iam::919703962183:role/LabRole"
    handler          = "lambda_post.lambda_handler"
    source_code_hash = data.archive_file.post.output_base64sha256
    runtime = "python3.11"

    environment {
        variables = {
            TOKEN_TABLE = "Token"
        }
    }
}

resource "aws_lambda_permission" "post" {
    statement_id  = "AllowExecutionFromApigateway"
    action        = "lambda:InvokeFunction"
    function_name = aws_lambda_function.lambda-post.function_name
    principal     = "apigateway.amazonaws.com"
    source_arn = "${aws_api_gateway_rest_api.techno-api.execution_arn}/*/*"
}

# Get
data "archive_file" "get" {
    type = "zip"
    source_file = "${path.module}/lambda/lambda_get.py"
    output_path = "${path.module}/lambda/lambda_get.zip"
}

resource "aws_lambda_function" "lambda-get" {
    filename         = "lambda_get.zip"
    function_name    = "techno-lambda-get"
    timeout = 90
    role             = "arn:aws:iam::919703962183:role/LabRole"
    handler          = "lambda_get.lambda_handler"
    source_code_hash = data.archive_file.get.output_base64sha256
    runtime = "python3.11"

    environment {
        variables = {
            TOKEN_TABLE = "Token"
        }
    }
}

resource "aws_lambda_permission" "get" {
    statement_id  = "AllowExecutionFromApigateway"
    action        = "lambda:InvokeFunction"
    function_name = aws_lambda_function.lambda-get.function_name
    principal     = "apigateway.amazonaws.com"
    source_arn = "${aws_api_gateway_rest_api.techno-api.execution_arn}/*/*"
}


# Api Gateway
resource "aws_api_gateway_rest_api" "techno-api" {
    name = "Techno-API-Akbar"

    endpoint_configuration {
        types = ["REGIONAL"]
    }
}

resource "aws_api_gateway_resource" "api-generate" {
  parent_id   = aws_api_gateway_rest_api.techno-api.root_resource_id
  path_part   = "generate-token"
  rest_api_id = aws_api_gateway_rest_api.techno-api.id
}

resource "aws_api_gateway_method" "api-method" {
  authorization = "NONE"
  http_method   = "POST"
  resource_id   = aws_api_gateway_resource.api-generate.id
  rest_api_id   = aws_api_gateway_rest_api.techno-api.id
}

resource "aws_api_gateway_integration" "post-inte" {
    http_method = aws_api_gateway_method.api-method.http_method
    resource_id = aws_api_gateway_resource.api-generate.id
    rest_api_id = aws_api_gateway_rest_api.techno-api.id
    type = "AWS_PROXY"
    integration_http_method = "POST"
    uri = aws_lambda_function.lambda-post.invoke_arn
}


resource "aws_api_gateway_resource" "api-validate" {
  parent_id   = aws_api_gateway_rest_api.techno-api.root_resource_id
  path_part   = "validate-token"
  rest_api_id = aws_api_gateway_rest_api.techno-api.id
}

resource "aws_api_gateway_method" "api-method-get" {
  authorization = "NONE"
  http_method   = "GET"
  resource_id   = aws_api_gateway_resource.api-validate.id
  rest_api_id   = aws_api_gateway_rest_api.techno-api.id
}

resource "aws_api_gateway_integration" "post-inter-get" {
    http_method = aws_api_gateway_method.api-method-get.http_method
    resource_id = aws_api_gateway_resource.api-validate.id
    rest_api_id = aws_api_gateway_rest_api.techno-api.id
    type = "AWS_PROXY"
    integration_http_method = "POST"
    uri = aws_lambda_function.lambda-post.invoke_arn
}

resource "aws_api_gateway_deployment" "deploy" {
    rest_api_id = aws_api_gateway_rest_api.techno-api.id

    depends_on = [
        aws_api_gateway_method.api-method-get,
        aws_api_gateway_method.api-method,
        aws_api_gateway_integration.post-inte,
        aws_api_gateway_integration.post-inter-get
    ]
}

resource "aws_api_gateway_stage" "techno-stage" {
    deployment_id = aws_api_gateway_deployment.deploy.id
    rest_api_id   = aws_api_gateway_rest_api.techno-api.id
    stage_name    = "dev"
}