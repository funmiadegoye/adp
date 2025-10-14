# VPC Module - Output Values
output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.this.id
}

output "vpc_cidr_block" {
  description = "CIDR block of the VPC"
  value       = aws_vpc.this.cidr_block
}

output "public_subnet_ids" {
  description = "List of public subnet IDs"
  value       = aws_subnet.public[*].id
}

output "public_route_table_id" {
  description = "ID of the public route table"
  value       = aws_route_table.public.id
}  # ← This was missing the closing brace

# Add private subnet outputs
output "private_subnet_ids" {
  description = "List of private subnet IDs"
  value       = aws_subnet.private[*].id
}

output "private_route_table_id" {
  description = "ID of the private route table"
  value       = try(aws_route_table.private[0].id, null)
}

output "internet_gateway_id" {
  description = "ID of the internet gateway"
  value       = aws_internet_gateway.this.id
}

output "nat_gateway_id" {
  description = "ID of the NAT Gateway"
  value       = try(aws_nat_gateway.this[0].id, null)
}

output "nat_gateway_public_ip" {
  description = "Public IP of the NAT Gateway"
  value       = try(aws_eip.nat[0].public_ip, null)
}

output "elastic_ip_id" {
  description = "ID of the Elastic IP for NAT Gateway"
  value       = try(aws_eip.nat[0].id, null)
}