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

variable "ami_id" {
  description = "The AMI ID for the EC2 instance"
  type        = string
  default     = "ami-0427090fd1714168b" # Adjust as necessary
}

variable "instance_type" {
  description = "The instance type for the EC2 instance"
  type        = string
  default     = "t2.micro"
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
