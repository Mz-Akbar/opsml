data "aws_iam_policy_document" "bucket-policy" {
    statement {
        principals {
            type = "AWS"
            identifiers = ["arn:aws:iam::126189343233:role/LabRole"]
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
            identifiers = ["arn:aws:iam::126189343233:role/LabRole"]
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