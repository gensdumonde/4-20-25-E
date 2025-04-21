import boto3
import json

s3_client = boto3.client('s3')
bucket_name = 'myawsbatch-gorio-bucket'

dynamodb_client = boto3.client('dynamodb')
table_name = 'mybatchdb'

try: 
    s3_response = s3_client.get_object(
        Bucket=bucket_name,
        Key='input/data.json'
    )
    
    s3_object_body = s3_response.get('Body')
    
    response_data = s3_object_body.read()
    contacts_dict = json.loads(response_data)

    for (key, val) in contacts_dict.items():
        contact_data = val
        for (contact) in contact_data:
            for (key, val) in contact.items():
                contact_indx = key
                fName = val['fName']
                lName = val['lName']
                email = val['email']
                cell = val['cell']

                dynamodb_response = dynamodb_client.put_item(
                    TableName = table_name,
                    Item = {
                      "id": {"S": contact_indx},
                      "fName": {"S": fName},
                      "lName": {"S": lName},
                      "email": {"S": email},
                      "cell": {"S": cell},
                    },
                )

                print(dynamodb_response)
    
except s3_client.exceptions.NoSuchBucket as e:
    print('The S3 Bucket does not exist')
    
except s3_client.exceptions.NoSuchKey as e:
    print('The Key does not exist')
