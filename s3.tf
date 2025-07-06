# First Bucket
resource "aws_s3_bucket" "technoinput" {
    bucket = "technoinput-payakumbuh-akbar"   
}

resource "aws_s3_bucket_public_access_block" "public-1" {
    bucket = aws_s3_bucket.technoinput.id
    block_public_acls = true
    block_public_policy = true
    ignore_public_acls = true
    restrict_public_buckets = true
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
    block_public_acls = true
    block_public_policy = true
    ignore_public_acls = true
    restrict_public_buckets = true
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

