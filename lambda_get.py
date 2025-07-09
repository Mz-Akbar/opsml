# token_validator_lambda.py
import json
import os
import time
import boto3

dynamodb = boto3.client('dynamodb', region_name='us-east-1')
TOKEN_TABLE = os.environ['TOKEN_TABLE']

def lambda_handler(event, context):
    query_params = event.get('queryStringParameters') or {}
    token = query_params.get('token', '')
    
    if not token:
        return {
            'statusCode': 401,
            'body': json.dumps({'error': 'Token is required'})
        }
    
    # Check if token exists and is not expired
    response = dynamodb.get_item(
        TableName=TOKEN_TABLE,
        Key={'token': {'S': token}}
    )
    
    if 'Item' not in response:
        return {
            'statusCode': 401,
            'body': json.dumps({'error': 'Invalid token'})
        }
    
    expiration_time = int(response['Item']['expiration']['N'])
    current_time = int(time.time())
    
    if current_time > expiration_time:
        return {
            'statusCode': 401,
            'body': json.dumps({'error': 'Token expired'})
        }
    
    # Delete the used token
    dynamodb.delete_item(
        TableName=TOKEN_TABLE,
        Key={'token': {'S': token}}
    )
    
    return {
        'statusCode': 200,
        'body': json.dumps({'success': True})
    }