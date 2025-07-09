import json
import boto3
import os

rekognition = boto3.client('rekognition')
sns = boto3.client('sns')
s3 = boto3.client('s3')
kinesis = boto3.client('kinesis')

SNS_TOPIC_ARN = os.environ['SNS_TOPIC_ARN']
KINESIS_STREAM_NAME = os.environ['KINESIS_STREAM_NAME']
DEST_BUCKET = os.environ['DEST_BUCKET']

def lambda_handler(event, context):
    # Ambil info dari S3 event
    for record in event['Records']:
        bucket = record['s3']['bucket']['name']
        key = record['s3']['object']['key']

        # Rekognition - Deteksi Label
        response = rekognition.detect_labels(
            Image={'S3Object': {'Bucket': bucket, 'Name': key}},
            MaxLabels=10
        )

        labels = response['Labels']
        result = {
            'image_key': key,
            'bucket': bucket,
            'labels': labels
        }

        # Simpan hasil ke Kinesis
        kinesis.put_record(
            StreamName=KINESIS_STREAM_NAME,
            Data=json.dumps(result),
            PartitionKey="partitionKey"
        )

        # Simpan hasil ke Bucket 2
        s3.put_object(
            Bucket=DEST_BUCKET,
            Key=f"results/{key}.json",
            Body=json.dumps(result)
        )

        # Kirim notifikasi ke SNS dengan nama bucket
        sns.publish(
            TopicArn=SNS_TOPIC_ARN,
            Message=f"Hasil analisa gambar {key} dari bucket {bucket}: {json.dumps(labels)}",
            Subject="Hasil Rekognition"
        )

    return {
        'statusCode': 200,
        'body': json.dumps('Gambar diproses!')
    }
