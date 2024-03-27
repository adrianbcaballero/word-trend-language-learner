import boto3
import logging
import os
import json
from decimal import Decimal

logger = logging.getLogger()
logger.setLevel(logging.INFO)

# Use boto3.resource instead of boto3.client

def lambda_handler(event, context):
    try:
        # Access the DynamoDB table using the resource's Table metho

        logger.info("Response: %s",)
        
        return print("test")
    
    except Exception as e:
        logger.error("An error occurred: %s", str(e))
        # Return an error response
        return {
            'statusCode': 500,
            'body': json.dumps({'error': 'Internal Server Error'})
        }