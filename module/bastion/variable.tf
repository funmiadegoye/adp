variable "name" {
  description = "Name prefix for all resources"
  type        = string
  default     = "bastion"
}

variable "vpc_id" {
  description = "VPC ID where bastion host will be deployed"
  type        = string
}

variable "subnets" {
  description = "List of subnet IDs for Auto Scaling Group"
  type        = list(string)
}

variable "keypair" {
  description = "SSH key pair name for bastion host"
  type        = string
}

variable "privatekey" {
  description = "Private key content"
  type        = string
  sensitive   = true
}

variable "instance_type" {
  description = "EC2 instance type for bastion host"
  type        = string
  default     = "t2.micro"
}

variable "min_size" {
  description = "Minimum number of bastion instances"
  type        = number
  default     = 1
}

variable "max_size" {
  description = "Maximum number of bastion instances"
  type        = number
  default     = 3
}

variable "desired_capacity" {
  description = "Desired number of bastion instances"
  type        = number
  default     = 1
}

variable "cpu_utilization_target" {
  description = "Target CPU utilization for auto scaling"
  type        = number
  default     = 70.0
}


variable "common_tags" {
  description = "Common tags for all resources"
  type        = map(string)
  default = {
    Project     = "auto-discovery"
    Environment = "development"
    Terraform   = "true"
  }
}

variable "region" {
  default = "eu-west-2"
}

variable "nr-key" {
  description = "New Relic License Key"
  type        = string
  default     = "NRAK-EALLCYVB0O491YGB6UW105ED8ZT"
}

variable "nr-acc-id" {
  description = "New Relic Account ID"
  type        = number
  default     = 7181908
}