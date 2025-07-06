resource "aws_athena_workgroup" "main" {
  name = "techno_workgroup"

  configuration {
    result_configuration {
      output_location = "s3://${aws_s3_bucket.technooutput.bucket}"
    }
  }
}
