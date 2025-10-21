output "vpc_id" {
  description = "The ID of the VPC"
  value       = aws_vpc.this.id  
}

output "public_subnet_ids" {
  description = "List of public subnet IDs"
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "List of private subnet IDs"
  value       = aws_subnet.private[*].id
}
output "public_key_name" {
  description = "The name of the key pair"
  value       = aws_key_pair.this.key_name
}

output "private_key_pem" {
  description = "The private key in PEM format"
  value       = tls_private_key.key.private_key_pem
}
