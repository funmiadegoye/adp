output "instance_id" {
  description = "ID of the Nexus EC2 instance"
  value       = aws_instance.nexus.id
}

output "private_ip" {
  description = "Private IP of the Nexus EC2 instance"
  value       = aws_instance.nexus.private_ip
}

output "security_group_id" {
  description = "ID of the Nexus security group"
  value       = aws_security_group.nexus_sg.id
}
