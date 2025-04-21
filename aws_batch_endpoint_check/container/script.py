
import os
import json
import time
import requests
import boto3

MAX_RETRIES = 3
SLEEP_SECONDS = 5

def notify_failure(message):
    sns = boto3.client("sns")
    topic_arn = os.environ["SNS_TOPIC_ARN"]
    sns.publish(TopicArn=topic_arn, Subject="Endpoint Check Failed", Message=message)

def upload_to_s3(json_data):
    s3 = boto3.client("s3")
    bucket = os.environ["S3_BUCKET"]
    file_name = f"result_{int(time.time())}.json"
    s3.put_object(Bucket=bucket, Key=file_name, Body=json.dumps(json_data))

def main():
    endpoint = os.environ["ENDPOINT_URL"]
    user = os.environ["USER_ID"]
    password = os.environ["PASSWORD"]

    for attempt in range(MAX_RETRIES):
        try:
            print(f"Attempt {attempt+1} connecting to {endpoint}")
            response = requests.get(endpoint, auth=(user, password))
            response.raise_for_status()
            result = {"status": "success", "code": response.status_code}
            upload_to_s3(result)
            return
        except Exception as e:
            print(f"Error on attempt {attempt+1}: {e}")
            time.sleep(SLEEP_SECONDS)

    notify_failure(f"Failed to connect to endpoint {endpoint} after {MAX_RETRIES} attempts.")

if __name__ == "__main__":
    main()
