output "bastion_security_group_id" {
  description = "ID of the bastion host security group"
  value       = aws_security_group.bastion_sg.id
}

output "bastion_launch_template_id" {
  description = "ID of the bastion launch template"
  value       = aws_launch_template.bastion_lt.id
}

output "bastion_autoscaling_group_id" {
  description = "ID of the bastion autoscaling group"
  value       = aws_autoscaling_group.bastion_asg.id
}

output "bastion_iam_role_arn" {
  description = "ARN of the bastion IAM role"
  value       = aws_iam_role.bastion_ssm_role.arn
}

output "bastion_ssm_command" {
  description = "SSM session command for bastion host"
  value       = "aws ssm start-session --target <instance-id>"
}