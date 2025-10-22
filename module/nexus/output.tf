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

output "alb_dns_name" {
  description = "ALB DNS name"
  value       = aws_lb.nexus_lb.dns_name
}

output "alb_arn" {
  description = "ALB ARN"
  value       = aws_lb.nexus_lb.arn
}

output "elb_security_group_id" {
  description = "Security group ID for the ALB"
  value       = aws_security_group.elb_sg.id
}
