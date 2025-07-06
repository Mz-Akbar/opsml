resource "aws_kinesis_stream" "techno-kinesis" {
    name = "techno-kinesis-Akbar"
    shard_count = 1
    retention_period = 24

    stream_mode_details {
        stream_mode = "PROVISIONED"
    }
}