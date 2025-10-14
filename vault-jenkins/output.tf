# Outputs
output "vault_server_ip" {
  description = "Public IP of the Vault server"
  value       = aws_instance.vault_server.public_ip
}

output "jenkins_server_ip" {
  description = "Public IP of the Jenkins server"
  value       = aws_instance.jenkins-server.public_ip
}

output "vault_url" {
  description = "URL to access Vault"
  value       = "https://vault.${var.domain}"
}

output "jenkins_url" {
  description = "URL to access Jenkins"
  value       = "https://jenkins.${var.domain}"
}

output "ssh_key_name" {
  description = "Name of the SSH key pair"
  value       = aws_key_pair.public_key.key_name
}

output "load_balancer_dns" {
  description = "DNS names of load balancers"
  value = {
    vault   = aws_elb.elb-vault.dns_name
    jenkins = aws_elb.elb_jenkins.dns_name
  }
}