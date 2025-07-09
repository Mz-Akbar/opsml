# vpc
resource "aws_vpc" "techno-vpc" {
    cidr_block = "25.1.0.0/16"
    assign_generated_ipv6_cidr_block = true
    enable_dns_hostnames = true
    enable_dns_support = true
    tags = {
        Name = "techno-vpc"
    }
}

resource "aws_subnet" "Public-A" {
    vpc_id = aws_vpc.techno-vpc.id
    cidr_block = "25.1.0.0/24"
    availability_zone = "us-east-1a"
    assign_ipv6_address_on_creation = true
    ipv6_cidr_block = cidrsubnet(aws_vpc.techno-vpc.ipv6_cidr_block, 8, 0)
    map_public_ip_on_launch = true
    enable_resource_name_dns_a_record_on_launch = true
    enable_resource_name_dns_aaaa_record_on_launch = true
}

resource "aws_subnet" "Public-B" {
    vpc_id = aws_vpc.techno-vpc.id
    cidr_block = "25.1.2.0/24"
    availability_zone = "us-east-1b"
    assign_ipv6_address_on_creation = true
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
    cidr_block = "25.1.4.0/24"
    availability_zone = "us-east-1b"
}

resource "aws_internet_gateway" "techno-igw" {
    vpc_id = aws_vpc.techno-vpc.id
}

resource "aws_route_table" "techno-Rt-Public" {
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

resource "aws_route_table_association" "Public-A" {
    subnet_id = aws_subnet.Public-A.id
    route_table_id = aws_route_table.techno-Rt-Public.id
}

resource "aws_route_table_association" "Public-B" {
    subnet_id = aws_subnet.Public-B.id
    route_table_id = aws_route_table.techno-Rt-Public.id
}

resource "aws_eip" "ip" {
    domain = "vpc"
}

resource "aws_nat_gateway" "techno-ngw" {
    allocation_id = aws_eip.ip.id
    subnet_id = aws_subnet.Public-A.id
}

resource "aws_route_table" "techno-Rt-Private" {
    vpc_id = aws_vpc.techno-vpc.id
    route {
        cidr_block = "0.0.0.0/0"
        nat_gateway_id = aws_nat_gateway.techno-ngw.id
    }
}

resource "aws_route_table_association" "Pricate-A" {
    subnet_id = aws_subnet.Private-A.id
    route_table_id = aws_route_table.techno-Rt-Private.id
}

resource "aws_route_table_association" "Pricate-B" {
    subnet_id = aws_subnet.Private-B.id
    route_table_id = aws_route_table.techno-Rt-Private.id
}

# security group lb
resource "aws_security_group" "lb-sg" {
    name = "techno-sg-lb"
    description = "This is for lb"
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

# security group app

resource "aws_security_group" "app-sg" {
    name = "techno-sg-app"
    description = "This is for app"
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


# IAM policy Bucketinput
data "aws_iam_policy_document" "bucketinput-policy" {
    statement {
        sid = "PublicReadAccess"
        effect = "Allow"

    principals {
        type = "AWS"
        identifiers = ["*"]
    }

    actions = [
        "s3:GetObject"
    ]

    resources = [
        "${aws_s3_bucket.techno-input.arn}/*"
    ]
    }
}



# s3
resource "aws_s3_bucket" "techno-input" {       # bucketinput
    bucket = "technoinput-payakumbuh-akbar"

    lifecycle {
        ignore_changes = [lifecycle_rule]
  }
}

resource "aws_s3_bucket_policy" "techoinput-policy" {
    bucket = aws_s3_bucket.techno-input.id
    policy = data.aws_iam_policy_document.bucketinput-policy.json

    depends_on = [aws_s3_bucket.techno-input]
}


resource "aws_s3_bucket_public_access_block" "public-a" {
    bucket = aws_s3_bucket.techno-input.id
    block_public_acls = false
    block_public_policy = false
    ignore_public_acls = false
    restrict_public_buckets = false
}

resource "aws_s3_bucket_notification" "trigger" {
    bucket = aws_s3_bucket.techno-input.id

    lambda_function {
        lambda_function_arn = aws_lambda_function.trigger-s3.arn
        events = ["s3:ObjectCreated:*"]
        filter_suffix = ""
    }
    depends_on = [aws_lambda_permission.lambda-s3]
}

#IAM policy bucketoutput
resource "aws_s3_bucket_lifecycle_configuration" "techno-lifecycle-1" {
    bucket = aws_s3_bucket.techno-input.id

    rule {
        id = "rule-1"
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


data "aws_iam_policy_document" "technooutput" {
    statement {
        sid = "StorageResult"
        effect = "Allow"

    principals {
        type = "AWS"
        identifiers = ["*"]
    }

    actions = [
        "s3:GetObject"
    ]

    resources = [
        "${aws_s3_bucket.technooutput.arn}/*"
    ]
    }
}

resource "aws_s3_bucket" "technooutput" {      # bucketoutput
    bucket = "technooutput-payakumbuh-akbar"

    lifecycle {
        ignore_changes = [lifecycle_rule]
  }
}


resource "aws_s3_bucket_lifecycle_configuration" "techno-lifecycle-2" {
    bucket = aws_s3_bucket.technooutput.id

    rule {
        id = "rule-2"
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

resource "aws_s3_bucket_public_access_block" "public-b" {
    bucket = aws_s3_bucket.technooutput.id
    block_public_acls = false
    block_public_policy = false
    ignore_public_acls = false
    restrict_public_buckets = false
}

resource "aws_s3_bucket_policy" "bucketoutput-policy" {
    bucket = aws_s3_bucket.technooutput.id
    policy =  data.aws_iam_policy_document.technooutput.json

    depends_on = [aws_s3_bucket.technooutput]
}


# Dynamodb 
resource "aws_dynamodb_table" "techno-table" {
    name = "Token"
    billing_mode = "PAY_PER_REQUEST"
    hash_key = "token"

    attribute {
        name = "token"
        type = "S"
    }
}

resource "aws_dynamodb_kinesis_streaming_destination" "techno-db-kinesis" {
    stream_arn = aws_kinesis_stream.techno-kinesis.arn
    table_name = aws_dynamodb_table.techno-table.name
}



# kinesis
resource "aws_kinesis_stream" "techno-kinesis" {
    name = "techno-kinesis-akbar"
    shard_count = 1
    retention_period = 24

    stream_mode_details {
        stream_mode = "PROVISIONED"
    }
}


# GLUE
resource "aws_glue_catalog_database" "techno-db" {
    name = "rekognition-results-db"
}


resource "aws_glue_catalog_table" "techno-table" {
    name = "rekognition_results_table"
    database_name = "rekognition-results-db"
    table_type = "EXTERNAL_TABLE"

    parameters = {
        EXTERNAL = "TRUE"
        has_encrypted_data = "false"
    }

    storage_descriptor {
        location = "s3://technooutput-payakumbuh-akbar/results"
        input_format = "org.apache.hadoop.mapred.TextInputFormat"
        output_format = "org.apache.hadoop.hive.q1.io.IgnoreKeyTextOutputFormat"

        ser_de_info {
            name = "My-Stream"
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

resource "aws_glue_crawler" "techno-crawler" {
    database_name = "rekognition-results-db"
    name = "techno-crawler-akbar"
    role = "arn:aws:iam::903675765022:role/LabRole"

    s3_target {
        path = "s3://${aws_s3_bucket.technooutput.bucket}"
    }
}

# Athena 
resource "aws_athena_workgroup" "main" {
  name = "techno_workgroup"

  configuration {
    result_configuration {
      output_location = "s3://${aws_s3_bucket.technooutput.bucket}"
    }
  }
}


# SNS
resource "aws_sns_topic" "SNS" {
    name = "techno-sns-payakumbuh-akbar"
}

resource "aws_sns_topic_subscription" "sns-subscription" {
    topic_arn = aws_sns_topic.SNS.arn
    protocol = "email"
    endpoint = "akbarmz235@gmail.com"
}


# Lambda Function

# lambda S3
data "archive_file" "lambda-s3" {
    type = "zip"
    source_file = "${path.module}/lambda_s3.py"
    output_path = "${path.module}/lambda_s3.zip"
}


resource "aws_lambda_function" "trigger-s3" {
    function_name = "techno-lambda-s3"
    timeout = 120
    filename = "lambda_s3.zip"
    role = "arn:aws:iam::903675765022:role/LabRole"
    handler = "lambda_s3.lambda_handler"
    source_code_hash = data.archive_file.lambda-s3.output_base64sha256
    runtime = "python3.11"


    environment {
        variables = {
            SNS_TOPIC_ARN = "techno-sns-payakumbuh-akbar"
            KINESIS_STREAM_NAME = "techno-kinesis-akbar"
            DEST_BUCKET = "technoinout-payakumbuh-akbar"
        }
    }
}

resource "aws_lambda_permission" "lambda-s3" {
    statement_id = "AllowLambdaExecutionFromS3"
    action = "lambda:InvokeFunction"
    function_name = aws_lambda_function.trigger-s3.function_name
    principal = "s3.amazonaws.com"
    source_arn = aws_s3_bucket.techno-input.arn
}

# lambda post

data "archive_file" "post" {
    type = "zip"
    source_file = "${path.module}/lambda_post.py"
    output_path =  "${path.module}/lambda_post.zip"
}

resource "aws_lambda_function" "lambda-post" {
    function_name = "techno-lambda-post"
    timeout = 60
    filename = "lambda_post.zip"
    role = "arn:aws:iam::903675765022:role/LabRole"
    handler = "lambda_post.lambda_handler"
    source_code_hash = data.archive_file.post.output_base64sha256
    runtime = "python3.11"

    environment {
        variables = {
            TOKEN_TABLE = "Token"
        }
    }
}

resource "aws_lambda_permission" "lambda_post" {
    statement_id = "AllowLambdaExecutionFromDynamodb"
    action = "lambda:InvokeFunction" 
    function_name = aws_lambda_function.lambda-post.function_name
    principal = "apigateway.amazonaws.com"
    source_arn = "${aws_api_gateway_rest_api.API.execution_arn}/*/*"
}

# lambda get
data "archive_file" "lambda_get" {
    type = "zip"
    source_file = "${path.module}/lambda_get.py"
    output_path = "${path.module}/lambda_get.zip"
}

resource "aws_lambda_function" "lambda-get" {
    function_name = "techno-lambda-get"
    timeout = 90
    filename = "lambda_get.zip"
    role = "arn:aws:iam::903675765022:role/LabRole"
    handler = "lambda_get.lambda_handler"
    source_code_hash = data.archive_file.lambda_get.output_base64sha256
    runtime = "python3.11"

    environment {
        variables = {
            TOKEN_TABLE = "Token"
        }
    }
}

resource "aws_lambda_permission" "lambda-get" {
    statement_id = "AllowLambdaExecutionFromDynamodb" 
    action = "lambda:InvokeFunction"
    function_name = aws_lambda_function.lambda-get.function_name
    principal = "apigateway.amazonaws.com"
    source_arn = "${aws_api_gateway_rest_api.API.execution_arn}/*/*"
}


# API Gateway
resource "aws_api_gateway_rest_api" "API" {
    name = "Techno-API-Akbar"
    endpoint_configuration {
        types = ["REGIONAL"]
    }
}

# POST
resource "aws_api_gateway_resource" "api-resource-post" {
    rest_api_id = aws_api_gateway_rest_api.API.id
    parent_id = aws_api_gateway_rest_api.API.root_resource_id
    path_part = "generate-token"
}

resource "aws_api_gateway_method" "POST" {
    rest_api_id = aws_api_gateway_rest_api.API.id
    resource_id = aws_api_gateway_resource.api-resource-post.id
    http_method = "POST"
    authorization = "NONE"
}

resource "aws_api_gateway_integration" "post-inter" {
    rest_api_id = aws_api_gateway_rest_api.API.id
    resource_id = aws_api_gateway_resource.api-resource-post.id
    http_method = aws_api_gateway_method.POST.http_method
    type = "AWS_PROXY"
    integration_http_method = "POST"
    uri = aws_lambda_function.lambda-post.invoke_arn
}

# GET
resource "aws_api_gateway_resource" "api-resource" {
    rest_api_id = aws_api_gateway_rest_api.API.id
    parent_id = aws_api_gateway_rest_api.API.root_resource_id
    path_part = "validate-token"
}

resource "aws_api_gateway_method" "GET" {
    rest_api_id = aws_api_gateway_rest_api.API.id
    resource_id = aws_api_gateway_resource.api-resource.id
    http_method = "GET"
    authorization = "NONE"
}

resource "aws_api_gateway_integration" "get-inter" {
    rest_api_id = aws_api_gateway_rest_api.API.id
    resource_id = aws_api_gateway_resource.api-resource.id
    http_method = aws_api_gateway_method.GET.http_method
    type = "AWS_PROXY"
    integration_http_method = "POST"
    uri = aws_lambda_function.lambda-get.invoke_arn
}


resource "aws_api_gateway_deployment" "api-deploy" {
    rest_api_id = aws_api_gateway_rest_api.API.id

    depends_on = [
        aws_api_gateway_method.POST,
        aws_api_gateway_method.GET,
        aws_api_gateway_integration.post-inter,
        aws_api_gateway_integration.get-inter
    ]
}

resource "aws_api_gateway_stage" "techno-stage" {
    deployment_id = aws_api_gateway_deployment.api-deploy.id
    rest_api_id = aws_api_gateway_rest_api.API.id 
    stage_name = "prod"
}

