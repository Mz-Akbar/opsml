# vpc
resource "aws_vpc" "techno-vpc" {
    cidr_block = "25.1.0.0/16"
    enable_dns_support = true
    enable_dns_hostnames = true
    assign_generated_ipv6_cidr_block = true

    tags = {
        Name = "techno-akbar"
    }
}

resource "aws_subnet" "techno-public-a" {
    vpc_id = aws_vpc.techno-vpc.id
    cidr_block = "25.1.0.0/24"
    availability_zone = "us-east-1a"
    assign_ipv6_address_on_creation = true
    enable_resource_name_dns_aaaa_record_on_launch = true
    enable_resource_name_dns_a_record_on_launch = true
    ipv6_cidr_block = cidrsubnet(aws_vpc.techno-vpc.ipv6_cidr_block, 8, 0)
    map_public_ip_on_launch = true 
}

resource "aws_subnet" "techno-public-b" {
    vpc_id = aws_vpc.techno-vpc.id
    cidr_block = "25.1.2.0/24"
    availability_zone = "us-east-1b"
    ipv6_cidr_block = cidrsubnet(aws_vpc.techno-vpc.ipv6_cidr_block, 8, 1)
    enable_resource_name_dns_aaaa_record_on_launch = true
    enable_resource_name_dns_a_record_on_launch = true
    map_public_ip_on_launch = true 
    assign_ipv6_address_on_creation = true
}

resource "aws_subnet" "techno-private-a" {
    vpc_id = aws_vpc.techno-vpc.id
    cidr_block = "25.1.1.0/24"
    availability_zone = "us-east-1b"
}

resource "aws_subnet" "techno-private-b" {
    vpc_id = aws_vpc.techno-vpc.id 
    cidr_block = "25.1.4.0/24"
    availability_zone = "us-east-1b"
}

resource "aws_internet_gateway" "techno-igw" {
    vpc_id = aws_vpc.techno-vpc.id
}

resource "aws_route_table" "techno-rt-public" {
    vpc_id = aws_vpc.techno-vpc.id
    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.techno-igw.id
    }

    route {
        ipv6_cidr_block = "::/0"
        gateway_id =aws_internet_gateway.techno-igw.id
    }
}

resource "aws_route_table_association" "techno-public-a" {
    route_table_id = aws_route_table.techno-rt-public.id
    subnet_id = aws_subnet.techno-public-a.id
}

resource "aws_route_table_association" "techno-public-b" {
    route_table_id = aws_route_table.techno-rt-public.id
    subnet_id = aws_subnet.techno-public-b.id
}

resource "aws_eip" "techno-ip" {
    domain = "vpc"
}

resource "aws_nat_gateway" "tehcno-igw" {
    allocation_id = aws_eip.techno-ip.id
    subnet_id = aws_subnet.techno-public-a.id
}

resource "aws_route_table" "techno-rt-private" {
    vpc_id = aws_vpc.techno-vpc.id
    route {
        cidr_block = "0.0.0.0/0"
        nat_gateway_id = aws_nat_gateway.tehcno-igw.id
    }
}

resource "aws_route_table_association" "techno-private-a" {
    route_table_id = aws_route_table.techno-rt-private.id
    subnet_id = aws_subnet.techno-private-a.id
}

resource "aws_route_table_association" "techno-private-b" {
    route_table_id = aws_route_table.techno-rt-private.id
    subnet_id = aws_subnet.techno-private-b.id
}

# Security Group
resource "aws_security_group" "techno-sg" {
    vpc_id = aws_vpc.techno-vpc.id
    name = "techno-sg-lb"
    description = "This inbound traffic for ports 80 anda 443"

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

resource "aws_security_group" "techno-sg-app" {
    vpc_id = aws_vpc.techno-vpc.id
    name = "tachno-sg-apps"
    description = "This is sg for apps"

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


# S3 Policy
data "aws_iam_policy_document" "techno-s3-policy" {
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
      "${aws_s3_bucket.techno-bucket-input.arn}/*",
    ]
  }
}

# S3
resource "aws_s3_bucket" "techno-bucket-input" { # Bucket input
    bucket = "technoinput-payakumbuh-akbar"
}


resource "aws_s3_bucket_public_access_block" "techno-public-access" {
  bucket = aws_s3_bucket.techno-bucket-input.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_policy" "techno-bucket-policy" {
  bucket = aws_s3_bucket.techno-bucket-input.id
  policy = data.aws_iam_policy_document.techno-s3-policy.json
}

resource "aws_s3_bucket_lifecycle_configuration" "example" {
  bucket = aws_s3_bucket.techno-bucket-input.id

  rule {
    id = "rule-1"

    filter {
        prefix = ""
    }

    expiration {
      days = 30
    }

    status = "Enabled"

    transition {
      days          = 365
      storage_class = "GLACIER_IR"
    }
  }
}



resource "aws_s3_bucket" "techno-bucket-output" { # bucket output
    bucket = "technooutput-payakumbuh-akbar"
}


resource "aws_s3_bucket_public_access_block" "techno-public-access-2" {
  bucket = aws_s3_bucket.techno-bucket-output.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_policy" "techno-bucket-policy-2" {
  bucket = aws_s3_bucket.techno-bucket-output.id
  policy = data.aws_iam_policy_document.techno-s3-policy.json
}

resource "aws_s3_bucket_lifecycle_configuration" "techno-lifecilce-output" {
  bucket = aws_s3_bucket.techno-bucket-output.id

  rule {
    id = "rule-1"

    filter {
        prefix = ""
    }

    expiration {
      days = 30
    }

    status = "Enabled"

    transition {
      days          = 365
      storage_class = "GLACIER_IR"
    }
  }
}

# DynamoDB
resource "aws_dynamodb_table" "basic-dynamodb-table" {
  name           = "Tokens"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "token"

  attribute {
    name = "token"
    type = "S"
  }
}

resource "aws_dynamodb_kinesis_streaming_destination" "tehcno-dynamodb-streaming" {
  stream_arn                               = aws_kinesis_stream.techno-kinesis.arn
  table_name                               = aws_dynamodb_table.basic-dynamodb-table.name
  approximate_creation_date_time_precision = "MICROSECOND"
}

# Kinesis
resource "aws_kinesis_stream" "techno-kinesis" {
    name        = "techno-kinesis-akbar"
    shard_count = 1
    retention_period = 24

    stream_mode_details {
    stream_mode = "PROVISIONED"
  }
}

# GLue
resource "aws_glue_catalog_database" "techno-glue-db" {
  name = "rekognition_results_db"
}

resource "aws_glue_catalog_table" "aws_glue_catalog_table" {
  name          = "rekognition_results_table"
  database_name = "rekognition_results_db"

  table_type = "EXTERNAL_TABLE"

  parameters = {
    EXTERNAL              = "TRUE"
    has_encryption = false
  }

  storage_descriptor {
    location      = "s3://technooutput-payakumbuh-akbar/results"
    input_format  = "org.apache.hadoop.hive.mapred.TextInputFormat"
    output_format = "org.apache.hadoop.hive.ql.io.IgnoreKeyTextOutputFormat"

    ser_de_info {
      name                  = "my-stream"
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
  database_name = aws_glue_catalog_database.techno-glue-db.name
  name          = "techno-crrwler-akbar"
  role          = "arn:aws:iam::011482749954:role/LabRole"

  s3_target {
    path = "s3://${aws_s3_bucket.techno-bucket-output.bucket}"
  }
}

# SNS
resource "aws_sns_topic" "techno-sns" {
  name = "techno-sns-payakumbuh-akbar"
}

resource "aws_sns_topic_subscription" "techno-subscription" {
  topic_arn = aws_sns_topic.techno-sns.arn
  protocol  = "email"
  endpoint  = "muhammadzafirulakbar88@gmail.com"
}

# lambda
data "archive_file" "example" {
  type        = "zip"
  source_file = "${path.module}/lambda/index.js"
  output_path = "${path.module}/lambda/function.zip"
}

# Lambda function
resource "aws_lambda_function" "example" {
  filename         = data.archive_file.example.output_path
  function_name    = "example_lambda_function"
  role             = aws_iam_role.example.arn
  handler          = "index.handler"
  source_code_hash = data.archive_file.example.output_base64sha256

  runtime = "python3.11"

  environment {
    variables = {
      ENVIRONMENT = "production"
      LOG_LEVEL   = "info"
    }
  }
}