variable "name" {
  description = "Name prefix for tagging resources"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where Nexus EC2 will be deployed"
  type        = string
}

variable "subnet_id" {
  description = "Private subnet ID for the Nexus EC2"
  type        = string
}

variable "key_name" {
  description = "EC2 Key pair name"
  type        = string
}
