provider "aws" {
  alias      = "producer"
  region     = var.aws_region
  access_key = var.producer_access_key
  secret_key = var.producer_secret_key
}

provider "aws" {
  alias      = "consumer"
  region     = var.aws_region
  access_key = var.consumer_access_key
  secret_key = var.consumer_secret_key
}

# Data sources to get account IDs
data "aws_caller_identity" "consumer" {
  provider = aws.consumer
}

data "aws_caller_identity" "producer" {
  provider = aws.producer
}