# VPC
resource "aws_vpc" "techno-vpc" {
    cidr_block = "25.1.0.0/16"
    assign_generated_ipv6_cidr_block = true
    enable_dns_support = true
    enable_dns_hostnames = true
    tags = {
        Name = "techno-akbar"
    }
}

resource "aws_subnet" "Public-A" {
    vpc_id = aws_vpc.techno-vpc.id
    cidr_block = "25.1.0.0/24"
    ipv6_cidr_block = cidrsubnet(aws_vpc.techno-vpc.ipv6_cidr_block, 8, 0)
    availability_zone = "us-east-1a"
    assign_ipv6_address_on_creation = true
    map_public_ip_on_launch = true
    enable_resource_name_dns_a_record_on_launch = true
    enable_resource_name_dns_aaaa_record_on_launch = true
}

resource "aws_subnet" "Public-B" {
    vpc_id = aws_vpc.techno-vpc.id
    cidr_block = "25.1.2.0/24"
    ipv6_cidr_block = cidrsubnet(aws_vpc.techno-vpc.ipv6_cidr_block, 8, 1)
    assign_ipv6_address_on_creation = true
    availability_zone = "us-east-1b"
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

resource "aws_internet_gateway" "techno-igw"{
    vpc_id = aws_vpc.techno-vpc.id
}

resource "aws_route_table" "techno-Rt-public" {
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
    subnet_id = aws_subnet.Public-A.id
    route_table_id = aws_route_table.techno-Rt-public.id
}

resource "aws_route_table_association" "techno-public-b" {
    subnet_id = aws_subnet.Public-B.id
    route_table_id = aws_route_table.techno-Rt-public.id
}

resource "aws_eip" "techno-ip" {
    domain = "vpc"
}

resource "aws_nat_gateway" "techno-ngw" {
    allocation_id = aws_eip.techno-ip.id
    subnet_id = aws_subnet.Public-A.id
}


resource "aws_route_table" "techno-Rt-private" {
    vpc_id = aws_vpc.techno-vpc.id
    route {
        cidr_block = "0.0.0.0/0"
        nat_gateway_id = aws_nat_gateway.techno-ngw.id
    }
}

resource "aws_route_table_association" "techno-private-A" {
    subnet_id = aws_subnet.Private-A.id
    route_table_id = aws_route_table.techno-Rt-private.id
}

resource "aws_route_table_association" "techno-private-B" {
    subnet_id = aws_subnet.Private-B.id
    route_table_id = aws_route_table.techno-Rt-private.id
}


resource "aws_security_group" "techno-sg-01" {
    vpc_id = aws_vpc.techno-vpc.id
    name = "techno-sg-lb"
    description = "This sg for lb"

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

resource "aws_security_group" "techno-sg-02" {
    vpc_id = aws_vpc.techno-vpc.id
    name = "techno-sg-apps"
    description = "This sg for apps"

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


# IAM Policy
data "aws_iam_policy_document" "bucket-policy" {
    statement {
        principals {
            type = "AWS"
            identifiers = ["*"]
        }
    

        actions = [
            "s3:GetObject",
            "s3:PutObject"
    ]

        resources = [
            "${aws_s3_bucket.technoinput.arn}/*"
        ]
    }
}

data "aws_iam_policy_document" "technooutput" {
    statement {
        principals {
            type = "AWS"
            identifiers = ["*"]
        }
    

        actions = [
            "s3:GetObject",
            "s3:PutObject"
    ]

        resources = [
            "${aws_s3_bucket.technooutput.arn}/*"
        ]
    }
}



# S3
# First Bucket
resource "aws_s3_bucket" "technoinput" {
    bucket = "technoinput-payakumbuh-akbar"   
}

resource "aws_s3_bucket_public_access_block" "public-1" {
    bucket = aws_s3_bucket.technoinput.id
    block_public_acls = false
    block_public_policy = false
    ignore_public_acls = false
    restrict_public_buckets = false
}

resource "aws_s3_bucket_policy" "bucket_policy" {
  bucket = aws_s3_bucket.technoinput.id
  policy = data.aws_iam_policy_document.bucket-policy.json

  depends_on = [aws_s3_bucket.technoinput]
}


resource "aws_s3_bucket_lifecycle_configuration" "techno-lifecylce-1"{
    bucket = aws_s3_bucket.technoinput.id

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


resource "aws_s3_bucket_notification" "trigger" {
    bucket = aws_s3_bucket.technoinput.id

    lambda_function {
        lambda_function_arn = aws_lambda_function.lambda-s3.arn
        events = ["s3:ObjectCreated:*"]
        filter_suffix = ""
    }
    depends_on = [aws_lambda_permission.allow-s3]
}


# Second Bucket
resource "aws_s3_bucket" "technooutput" {
    bucket = "technooutput-payakumbuh-akbar"
}

resource "aws_s3_bucket_public_access_block" "public-2" {
    bucket = aws_s3_bucket.technooutput.id
    block_public_acls = false
    block_public_policy = false
    ignore_public_acls = false
    restrict_public_buckets = false
}

resource "aws_s3_bucket_policy" "bucket_policy_output" {
  bucket = aws_s3_bucket.technooutput.id
  policy = data.aws_iam_policy_document.technooutput.json

  depends_on = [aws_s3_bucket.technooutput]
}


resource "aws_s3_bucket_lifecycle_configuration" "techno-lifecylce-2"{
    bucket = aws_s3_bucket.technooutput.id

    rule {
        id = "rule-technooutput"
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
resource "aws_dynamodb_table" "techno-table" {
    name = "Token"
    billing_mode = "PAY_PER_REQUEST"
    hash_key = "token"

    attribute {
        name = "token"
        type = "S"
    }
}

resource "aws_dynamodb_kinesis_streaming_destination" "techno-stream" {
    table_name = aws_dynamodb_table.techno-table.name 
    stream_arn = aws_kinesis_stream.techno-kinesis.arn
    approximate_creation_date_time_precision = "MICROSECOND"
}

# Kinesis
resource "aws_kinesis_stream" "techno-kinesis" {
    name = "techno-kinesis-Akbar"
    shard_count = 1
    retention_period = 24

    stream_mode_details {
        stream_mode = "PROVISIONED"
    }
}

# Glue 
resource "aws_glue_catalog_database" "tehcno-glue" {
    name = "rekognition_results_db"
}

resource "aws_glue_catalog_table" "glue-table" {
    name = "rekognition_results_table"
    database_name = "rekognition_results_db"
    catalog_id = aws_glue_catalog_database.tehcno-glue.catalog_id
    table_type = "EXTERNAL_TABLE"

    parameters = {
        EXTERNAL = "TRUE"
        has_encrypted_data = "false"

    }

    storage_descriptor {
        location      = "s3://technoinput-payakumbuh-akbar/result"
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



resource "aws_glue_crawler" "techno-crawler" {
    database_name = aws_glue_catalog_database.tehcno-glue.name
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
resource "aws_sns_topic" "techno-sns" {
    name = "techno-sns-payakumbuh-akbar"
}

resource "aws_sns_topic_subscription" "techno-admin" {
    topic_arn = aws_sns_topic.techno-sns.arn
    protocol = "email"
    endpoint = "muhammadzafirulakbar88@gmail.com"
}

# Lambda 
# lambda s3
data "archive_file" "lambda_s3_zip" {
  type        = "zip"
  source_file = "${path.module}/lambda/lambda_s3.py"
  output_path = "${path.module}/lambda_s3.zip"
}

resource "aws_lambda_function" "lambda-s3" {
    function_name = "techno-lambda-s3"
    timeout = 120
    filename = "lambda_s3.zip"
    role = "arn:aws:iam::903675765022:role/LabRole"
    runtime = "python3.11"
    handler = "lambda_s3.lambda_handler"
    source_code_hash = data.archive_file.lambda_s3_zip.output_base64sha256

    environment {
      variables = {
        SNS_TOPIC_ARN = "arn:aws:sns:us-east-1:903675765022:techno-sns-payakumbuh-akbar",
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
  source_file = "${path.module}/lambda/lambda_post.py"
  output_path = "${path.module}/lambda_post.zip"
}

resource "aws_lambda_function" "POST" {
    function_name = "techno-lambda-post"
    timeout = 60
    filename = "lambda_post.zip"
    role = "arn:aws:iam::903675765022:role/LabRole"
    runtime = "python3.11"
    handler = "lambda_post.lambda_handler"
    source_code_hash = data.archive_file.lambda_post_zip.output_base64sha256

    environment {
      variables = {
        TOKEN_TABLE = "Token"
    }
  }
}

resource "aws_lambda_permission" "post" {
    statement_id = "AllowExecutionFromApigateway"
    action = "lambda:InvokeFunction"
    function_name = aws_lambda_function.POST.function_name
    principal = "apigateway.amazonaws.com"
    source_arn = "${aws_api_gateway_rest_api.rest-api.execution_arn}/*/*"

}


# lambda Get

data "archive_file" "lambda_get_zip" {
  type        = "zip"
  source_file = "${path.module}/lambda/lambda_get.py"
  output_path = "${path.module}/lambda_get.zip"
}

resource "aws_lambda_function" "GET" {
    function_name = "techno-lambda-get"
    timeout = 90
    filename = "lambda_get.zip"
    role = "arn:aws:iam::903675765022:role/LabRole"
    runtime = "python3.11"
    handler = "lambda_get.lambda_handler"
    source_code_hash = data.archive_file.lambda_get_zip.output_base64sha256

     environment {
      variables = {
        TOKEN_TABLE = "Token"
    }
  }
}

resource "aws_lambda_permission" "get" {
    statement_id = "AllowExecutionFromApigateway"
    action = "lambda:InvokeFunction"
    function_name = aws_lambda_function.GET.function_name
    principal = "apigateway.amazonaws.com"
    source_arn = "${aws_api_gateway_rest_api.rest-api.execution_arn}/*/*"

}

# Api Gateway
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

resource "aws_api_gateway_stage" "prod" {
  deployment_id = aws_api_gateway_deployment.restapi.id
  rest_api_id   = aws_api_gateway_rest_api.rest-api.id
  stage_name    = "prod"
}