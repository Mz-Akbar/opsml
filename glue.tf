resource "aws_glue_catalog_database" "tehcno-glue" {
    name = "rekognition_results_db"
}

resource "aws_glue_catalog_table" "glue-table" {
    name = "rekognition_results_table"
    database_name = "rekognition_results_db"

    storage_descriptor {
        location      = "s3://technoinput-payakumbuh-akbar/result"
        input_format  = "org.apache.hadoop.mapred.TextInputFormat"
        output_format = "org.apache.hadoop.hive.ql.io.IgnoreKeyTextOutputFormat"

        ser_de_info {
            name = "my-stream"
            serialization_library = "org.openx.data.jsonserde.JsonSerDe"
        }
    }
}

resource "aws_glue_crawler" "techno-crawler" {
    database_name = aws_glue_catalog_database.tehcno-glue.name
    name = "techno-crawler-akbar"
    role = "arn:aws:iam::126189343233:role/LabRole"

    s3_target {
        path = "s3://${aws_s3_bucket.technooutput.bucket}"
    }
}