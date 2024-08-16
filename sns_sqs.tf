# resource "aws_sns_topic" "producer_topic" {
#   name = "producer-topic"

#   tags = {
#     Name = "producer-topic"
#   }
# }

# resource "aws_sns_topic_subscription" "consumer_subscription" {
#   topic_arn = aws_sns_topic.producer_topic.arn
#   protocol  = "http"
#   endpoint  = "http://${aws_instance.consumer_ec2.public_ip}:8080" 
# }


# Create SQS queue
resource "aws_sqs_queue" "vulnerable_queue" {
  provider = aws.consumer
  name     = "vulnerable-orders-queue"
}


# output "sqs_queue_url" {
#   value = aws_sqs_queue.vulnerable_queue.url
# }

