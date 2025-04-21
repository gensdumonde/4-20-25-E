
import boto3
import os
import json
import requests
from time import sleep
from botocore.exceptions import ClientError
from requests.auth import HTTPBasicAuth
import logging

# Setup logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger()

# Retrieve secrets from AWS Secrets Manager
def get_secret(secret_name):
    region_name = os.environ['AWS_REGION']
    session = boto3.session.Session()
    client = session.client(service_name='secretsmanager', region_name=region_name)

    try:
        get_secret_value_response = client.get_secret_value(SecretId=secret_name)
        if 'SecretString' in get_secret_value_response:
            return json.loads(get_secret_value_response['SecretString'])
        else:
            return json.loads(get_secret_value_response['SecretBinary'])
    except ClientError as e:
        logger.error(f"Error retrieving secret {secret_name}: {e}")
        raise e

# Connect to MuleSoft API using OAuth
def connect_mulesoft(oauth_url, client_id, client_secret):
    headers = {'Content-Type': 'application/x-www-form-urlencoded'}
    payload = f'grant_type=client_credentials&client_id={client_id}&client_secret={client_secret}'
    
    try:
        response = requests.post(oauth_url, headers=headers, data=payload)
        response.raise_for_status()
        return response.json()['access_token']
    except requests.exceptions.HTTPError as err:
        logger.error(f"Error during authentication: {err}")
        raise

# Upload to S3
def upload_to_s3(bucket_name, file_name, file_content):
    s3 = boto3.client('s3')
    try:
        s3.put_object(Bucket=bucket_name, Key=file_name, Body=file_content)
        logger.info(f"File {file_name} uploaded successfully to {bucket_name}")
    except ClientError as e:
        logger.error(f"Error uploading file: {e}")
        raise e

# Send SNS notification
def send_sns_notification(topic_arn, message):
    sns = boto3.client('sns')
    try:
        sns.publish(TopicArn=topic_arn, Message=message)
        logger.info("SNS notification sent")
    except ClientError as e:
        logger.error(f"Error sending SNS notification: {e}")
        raise e

# Main function to execute the logic
def main():
    secret_name = "sftp/credentials"
    s3_bucket_name = os.environ["S3_BUCKET_NAME"]
    sns_topic_arn = os.environ["SNS_TOPIC_ARN"]
    oauth_url = os.environ["OAUTH_URL"]

    # Get secrets
    secrets = get_secret(secret_name)
    client_id = secrets['client_id']
    client_secret = secrets['client_secret']
    access_token = None

    retries = 3
    for attempt in range(retries):
        try:
            access_token = connect_mulesoft(oauth_url, client_id, client_secret)
            break
        except Exception as e:
            if attempt < retries - 1:
                logger.warning(f"Retrying... {attempt + 1}/{retries}")
                sleep(5)
            else:
                logger.error(f"Failed after {retries} attempts. Sending failure notification.")
                send_sns_notification(sns_topic_arn, "MuleSoft connection failed.")
                raise e

    # Simulate file creation to upload
    file_name = "output.json"
    file_content = json.dumps({"data": "Sample file from MuleSoft connection."})

    # Upload to S3
    upload_to_s3(s3_bucket_name, file_name, file_content)

if __name__ == '__main__':
    main()
