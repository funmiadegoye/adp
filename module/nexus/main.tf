# Data source for RedHat AMI
data "aws_ami" "redhat" {
  most_recent = true
  owners      = ["309956199498"] # RedHat's owner ID

  filter {
    name   = "name"
    values = ["RHEL-9*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Security Group
resource "aws_security_group" "nexus_sg" {
  name        = "${var.name}-nexus-sg"
  description = "Security group for Nexus server"
  vpc_id      = var.vpc_id

  # SSH access from VPC
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  # Nexus port 8081
  ingress {
    from_port   = 8081
    to_port     = 8081
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Nexus port 8085
  ingress {
    from_port   = 8085
    to_port     = 8085
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.name}-nexus-sg"
  }
}

# EC2 Instance
resource "aws_instance" "nexus" {
  ami           = data.aws_ami.redhat.id
  instance_type = "t2.medium"
  subnet_id     = var.subnet_id
  key_name      = var.key_name

  vpc_security_group_ids = [aws_security_group.nexus_sg.id]

  tags = {
    Name = "${var.name}-nexus-server"
  }
}
