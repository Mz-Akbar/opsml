import json
import secrets
import time
import boto3
import os
from botocore.exceptions import ClientError

def lambda_handler(event, context):
    try:
        dynamodb = boto3.client('dynamodb')
        token = secrets.token_urlsafe(32)
        expiration = int(time.time()) + 300  # 5 menit
        
        dynamodb.put_item(
            TableName=os.environ['TOKEN_TABLE'],
            Item={
                'token': {'S': token},
                'expiration': {'N': str(expiration)}
            }
        )
        
        return {
            'statusCode': 200,
            'headers': {
                'Access-Control-Allow-Origin': '*',
                'Access-Control-Allow-Headers': 'Content-Type',
                'Access-Control-Allow-Methods': 'POST'
            },
            'body': json.dumps({'token': token})
        }
    
    except ClientError as e:
        print(f"DynamoDB Error: {e}")
        return {
            'statusCode': 500,
            'body': json.dumps({'error': 'Internal server error'})
        }
