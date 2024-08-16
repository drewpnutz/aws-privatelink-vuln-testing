import boto3
import json
import mysql.connector
import time
import urllib.parse
import logging
import sys

# Logging Setup
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler("/home/ec2-user/consumer_sqs_vuln.log"),
        logging.StreamHandler(sys.stdout)
    ]
)

# SQS setup
sqs = boto3.client('sqs', region_name='REGION')
queue_url = 'SQSURL'

# Database connection function
def get_db_connection():
    return mysql.connector.connect(
        host="localhost",
        user="vulnuser",
        password="password",
        database="vulnerable_db"
    )

while True:
    try:
        logging.info("Fishing for messages..")
        response = sqs.receive_message(
            QueueUrl=queue_url,
            MaxNumberOfMessages=1,
            WaitTimeSeconds=20
        )

        if 'Messages' in response:
            for message in response['Messages']:
                logging.info(f"Raw message body: {message['Body']}")

                try:
                    decoded_body = urllib.parse.unquote(message['Body'])
                    order = json.loads(decoded_body)
                    logging.info(f"Decoded and parsed message: {order}")

                    # Extremely vulnerable query construction (DO NOT USE IN PRODUCTION!)
                    query = f"INSERT INTO orders SET user_id='{order['user_id']}', product_id='{order['product_id']}', quantity={order['quantity']}"

                    logging.info(f"Executing query: {query}")

                    db = get_db_connection()
                    cursor = db.cursor()

                    for result in cursor.execute(query, multi=True):
                        if result.with_rows:
                            print(result.fetchall())
                    db.commit()

                    logging.info("Query executed successfully")

                except mysql.connector.Error as err:
                    logging.error(f"MySQL Error: {err}")
                    if db.is_connected():
                        db.rollback()
                except Exception as e:
                    logging.error(f"Error processing message: {e}")
                finally:
                    if 'db' in locals() and db.is_connected():
                        cursor.close()
                        db.close()

                sqs.delete_message(
                    QueueUrl=queue_url,
                    ReceiptHandle=message['ReceiptHandle']
                )
                logging.info("Message deleted from queue")
        else:
            logging.info("No messages received")

    except Exception as e:
        logging.error(f"Unexpected error: {e}")

    time.sleep(1)