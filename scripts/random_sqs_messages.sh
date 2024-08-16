#!/bin/bash

# Set the SQS queue URL and AWS region
sqs_queue_url=SQLURL
aws_region=REGION

# Function to generate a random string
generate_random_string() {
  cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 8 | head -n 1
}

# Function to generate a random number between a range
generate_random_number() {
  shuf -i 1-100 -n 1
}

# Loop to send random messages every 10 seconds
while true; do
  random_user_id="user$(generate_random_string)"
  random_product_id="product$(generate_random_string)"
  random_quantity=$(generate_random_number)

  random_message=$(jq -n --arg user_id "$random_user_id" --arg product_id "$random_product_id" --argjson quantity "$random_quantity" '{user_id: $user_id, product_id: $product_id, quantity: $quantity}')
  
  echo "Sending message: $random_message"
  
  # Send the message to SQS
  aws sqs send-message --queue-url $sqs_queue_url --region $aws_region --message-body "$random_message"

  # Wait for 2 min
  sleep 120
done
