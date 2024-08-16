variable "aws_region" {
  description = "The AWS region to create resources in"
  type        = string
  default     = "us-east-1"
}

variable "availability_zone" {
  description = "The availability zone to use for the subnet"
  type        = string
  default     = "us-east-1a"
}

variable "consumer_vpc_cidr" {
  description = "The CIDR block for the VPC"
  type        = string
  default     = "10.10.0.0/24"
}

variable "consumer_subnet_cidr" {
  description = "The CIDR block for the subnet"
  type        = string
  default     = "10.10.0.0/27"
}

variable "producer_vpc_cidr" {
  description = "The CIDR block for the VPC"
  type        = string
  default     = "10.69.0.0/24"
}

variable "producer_subnet_cidr" {
  description = "The CIDR block for the subnet"
  type        = string
  default     = "10.69.0.0/27"
}

variable "pa_mgmt_subnet_cidr" {
  description = "The CIDR block for the subnet"
  type        = string
  default     = "10.69.0.32/27"
}

variable "gwlb_dp_subnet_cidr" {
  description = "The CIDR block for the subnet"
  type        = string
  default     = "10.69.0.64/27"
}


variable "ami_id" {
  description = "The AMI ID for the EC2 instance"
  type        = string
  default     = "ami-0427090fd1714168b" # Adjust as necessary
}

variable "instance_type" {
  description = "The instance type for the EC2 instance"
  type        = string
  default     = "c4.large"
}

variable "source_ssh_networks" {
  description = "Public IP to SSH to consumer ec2"
  type        = list(string)
  default     = null
}

variable "public_key" {
  description = "Public SSH key"
  type        = string
}

variable "s3_source" {
  description = "List of allowed source IP addresses for S3 access"
  type        = list(string)
  default     = ["69.69.69.69/32" ]
}

variable "producer_access_key" {
  description = "Access key for the producer account"
  type        = string
  sensitive   = true
}

variable "producer_secret_key" {
  description = "Secret key for the producer account"
  type        = string
  sensitive   = true
}

variable "consumer_access_key" {
  description = "Access key for the consumer account"
  type        = string
  sensitive   = true
}

variable "consumer_secret_key" {
  description = "Secret key for the consumer account"
  type        = string
  sensitive   = true
}

variable "az_id" {
  description = "Set your az-id or else good luck trying to get anything to work between accounts"
  type        = string
  default     = "use1-az2"
}

variable "sid" {
  description = "Secure ID in AWS"
  type        = string
  default     = "8cj487d7"
}

variable "consumer_email" {
  description = "Email address associated with the consumer account used for guardduty invitation"
  type        = string
  default     = "smitty@example.com"
}

variable "pa_vm_count" {
  description = "how many pa vms do you want to test with"
  type        = string
  default     = "1"
}

variable "suricata_vm_count" {
  description = "how many suricata vms do you want to test with"
  type        = string
  default     = "1"
}