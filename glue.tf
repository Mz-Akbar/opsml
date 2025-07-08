resource "aws_glue_catalog_database" "tehcno-glue" {
    name = "rekognition_results_db"
}

resource "aws_glue_catalog_table" "glue-table" {
    name = "rekognition_results_table"
    database_name = "rekognition_results_db"
    catalog_id = aws_glue_catalog_database.tehcno-glue.catalog_id
    table_type = "EXTERNAL_TABLE"

    storage_descriptor {
        location      = "s3://technoinput-payakumbuh-akbar/result"
        input_format  = "org.apache.hadoop.mapred.TextInputFormat"
        output_format = "org.apache.hadoop.hive.ql.io.IgnoreKeyTextOutputFormat"
        number_of_buckets = -1
        stored_as_sub_directories = false
        compressed  = false   

        ser_de_info {
            name = "my-stream"
            serialization_library = "org.openx.data.jsonserde.JsonSerDe"

             parameters = {
                "serialization.format" = 1
                EXTERNAL = "TRUE"
                has_encrypted_data = "false"

             }
        }
        
            columns {
                name = "image_key"
                type = "string"
        }
            columns {
                name = "labels"
                type = "array<struct<Name:string, Confidence:double>>"
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