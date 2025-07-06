resource "aws_dynamodb_table" "techno-table" {
    name = "Tokens"
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