locals {
  name = "f-auto-discov"
}

# NETWORKING CORE
# Create VPC
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "${local.name}-vpc"
  }
}

# Create Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${local.name}-igw"
  }
}

#SUBNETS AND ROUTING
# Create Public Subnets
resource "aws_subnet" "public_2a" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "eu-west-2a"
  map_public_ip_on_launch = true

  tags = {
    Name = "${local.name}-public-subnet-2a"
  }
}

resource "aws_subnet" "public_2b" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "eu-west-2b"
  map_public_ip_on_launch = true

  tags = {
    Name = "${local.name}-public-subnet-2b"
  }
}

# Create Route Table
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "${local.name}-public-rt"
  }
}

# Associate Route Tables with Subnets
resource "aws_route_table_association" "public_rt_assoc_2a" {
  subnet_id      = aws_subnet.public_2a.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table_association" "public_rt_assoc_2b" {
  subnet_id      = aws_subnet.public_2b.id
  route_table_id = aws_route_table.public_rt.id
}

#SECURITY AND KEYS
#Creating kms key
resource "aws_kms_key" "kms-key" {
  description             = "${local.name}-vault-kms-key" // the kms key 
  deletion_window_in_days = 30                            // 30 days
  enable_key_rotation     = true                          // true
}
# alias of the kms key
resource "aws_kms_alias" "kms-key" {
  name          = "alias/${local.name}-kms-key"
  target_key_id = aws_kms_key.kms-key.key_id
}

# Create keypair resource
resource "tls_private_key" "keypair" {
  algorithm = "RSA"
  rsa_bits  = 4096
}
resource "local_file" "private_key" {
  content         = tls_private_key.keypair.private_key_pem
  filename        = "${local.name}-key.pem"
  file_permission = "400"
}
resource "aws_key_pair" "public_key" {
  key_name   = "${local.name}-key"
  public_key = tls_private_key.keypair.public_key_openssh
}


#IAM ROLES AND POLICIES FOR SERVERS
# Create IAM role for Vault
resource "aws_iam_role" "vault_role" {
  name = "${local.name}-vault-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "ec2.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
}


resource "aws_iam_role_policy" "vault_kms_access" {
  name = "${local.name}-vault_kms-access"
  role = aws_iam_role.vault_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:DescribeKey"
        ],
        Resource = "${aws_kms_key.kms-key.arn}"
      }
    ]
  })
}
# Attach SSM Core Policy for Session Manager Access
resource "aws_iam_role_policy_attachment" "vault_ssm_attachment" {
  role       = aws_iam_role.vault_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "vault-profile" {
  name = "${local.name}-vault-profile"
  role = aws_iam_role.vault_role.name
}


# Create IAM role for Jenkins
resource "aws_iam_role" "jenkins-role" {
  name = "${local.name}-jenkins-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "ec2.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
}
# Attach the policy to the role
resource "aws_iam_role_policy_attachment" "jenkins-role-attachment" {
  role       = aws_iam_role.jenkins-role.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}
# Attach SSM Core Policy for Session Manager Access
resource "aws_iam_role_policy_attachment" "jenkins_ssm_attachment" {
  role       = aws_iam_role.jenkins-role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# Attach the policy to the role
resource "aws_iam_instance_profile" "jenkins-profile" {
  name = "${local.name}-jenkins-profile"
  role = aws_iam_role.jenkins-role.name
}

#SECURITY GROUPS 
# Create Vault Security Group
resource "aws_security_group" "vault_sg" {
  name        = "vault-sg"
  description = "Allow SSH, HTTP, HTTPS, and Vault UI/API"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 8200
    to_port     = 8200
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
# Create jenkins security group
resource "aws_security_group" "jenkins_sg" {
  name        = "${local.name}-jenkins-sg"
  description = "Allow SSH and HTTPS"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

#COMPUTE INSTANCES
# Ubuntu AMI lookup
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Data source to get the latest RedHat AMI
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
  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}
#VAULT SERVER
resource "aws_instance" "vault_server" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "t2.medium"
  key_name               = aws_key_pair.public_key.key_name
  vpc_security_group_ids = [aws_security_group.vault_sg.id]
  iam_instance_profile   = aws_iam_instance_profile.vault-profile.id
  subnet_id              = aws_subnet.public_2a.id
  user_data = templatefile("./vault-install.sh", {
    var1 = "eu-west-2",
    var2 = aws_kms_key.kms-key.id
  })

  tags = {
    Name = "${local.name}-VaultServer"
  }
}

#JENKINS SERVER
resource "aws_instance" "jenkins-server" {
  ami                         = data.aws_ami.redhat.id
  instance_type               = "t2.medium"
  key_name                    = aws_key_pair.public_key.id
  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.jenkins_sg.id]
  iam_instance_profile        = aws_iam_instance_profile.jenkins-profile.id
  subnet_id                   = aws_subnet.public_2a.id
  root_block_device {
    volume_size = 30
    volume_type = "gp3"
    encrypted   = true
  }
  user_data = templatefile("./jenkins_userdata.sh", {
    nr-key    = var.nr-key
    nr-acc-id = var.nr-acc-id
    region    = var.region
  })

  tags = {
    Name = "${local.name}-jenkins-server"
  }
}

#DNS AND CERTIFICATES
# Create ACM certificate with DNS validation
resource "aws_acm_certificate" "acm-cert" {
  domain_name               = var.domain
  subject_alternative_names = ["*.${var.domain}"]
  validation_method         = "DNS"
  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name = "${local.name}-acm-cert"
  }
}

data "aws_route53_zone" "acp-zone" {
  name         = var.domain
  private_zone = false
}

# Fetch DNS Validation Records for ACM Certificate
resource "aws_route53_record" "acm_validation_record" {
  for_each = {
    for dvo in aws_acm_certificate.acm-cert.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  # Create DNS Validation Record for ACM Certificate
  zone_id         = data.aws_route53_zone.acp-zone.zone_id
  allow_overwrite = true
  name            = each.value.name
  type            = each.value.type
  ttl             = 60
  records         = [each.value.record]
  depends_on      = [aws_acm_certificate.acm-cert]
}

# Validate the ACM Certificate after DNS Record Creation
resource "aws_acm_certificate_validation" "team2_cert_validation" {
  certificate_arn         = aws_acm_certificate.acm-cert.arn
  validation_record_fqdns = [for record in aws_route53_record.acm_validation_record : record.fqdn]
  depends_on              = [aws_acm_certificate.acm-cert]
}

#CCREATING ELB FOR VAULT AND JENKINS, ROUTE 53 FOR BOTH  AND SECURITY GROUPS FOR THE ELB
#Create Security Group for Vault Elastic Load Balancer
# Create load balancer for Vault Server
resource "aws_elb" "elb-vault" {
  name            = "vault-elb"
  subnets         = [aws_subnet.public_2a.id, aws_subnet.public_2b.id]
  security_groups = [aws_security_group.elb-vault-sg.id]

  listener {
    instance_port      = 8200
    instance_protocol  = "http"
    lb_port            = 443
    lb_protocol        = "https"
    ssl_certificate_id = aws_acm_certificate.acm-cert.arn
  }

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    target              = "TCP:8200"
    interval            = 30
  }

  instances                   = [aws_instance.vault_server.id]
  cross_zone_load_balancing   = true
  idle_timeout                = 400
  connection_draining         = true
  connection_draining_timeout = 400

  tags = {
    Name = "${local.name}-elb-vault"
  }
}

# Create Route 53 Hosted Zone
data "aws_route53_zone" "vault-zone" {
  name         = var.domain
  private_zone = false
}

# Create Route 53 A Record for Vault Server
resource "aws_route53_record" "vault-record" {
  zone_id = data.aws_route53_zone.vault-zone.zone_id
  name    = "vault.${var.domain}"
  type    = "A"
  alias {
    name                   = aws_elb.elb-vault.dns_name
    zone_id                = aws_elb.elb-vault.zone_id
    evaluate_target_health = true
  }
}

resource "aws_security_group" "elb-vault-sg" {
  name        = "elb-vault-sg"
  description = "Allow HTTPS"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


# Create elastic Load Balancer for Jenkins
resource "aws_elb" "elb_jenkins" {
  name            = "elb-jenkins"
  security_groups = [aws_security_group.jenkins-elb-sg.id]
  subnets         = [aws_subnet.public_2a.id, aws_subnet.public_2b.id]
  listener {
    instance_port      = 8080
    instance_protocol  = "HTTP"
    lb_port            = 443
    lb_protocol        = "HTTPS"
    ssl_certificate_id = aws_acm_certificate.acm-cert.id
  }
  health_check {
    healthy_threshold   = 3
    unhealthy_threshold = 2
    interval            = 30
    timeout             = 5
    target              = "TCP:8080"
  }
  instances                   = [aws_instance.jenkins-server.id]
  cross_zone_load_balancing   = true
  idle_timeout                = 400
  connection_draining         = true
  connection_draining_timeout = 400
  tags = {
    Name = "${local.name}-jenkins-server"
  }
}
# Create Route 53 record for jenkins server
resource "aws_route53_record" "jenkins-record" {
  zone_id = data.aws_route53_zone.acp-zone.zone_id
  name    = "jenkins.${var.domain}"
  type    = "A"
  alias {
    name                   = aws_elb.elb_jenkins.dns_name
    zone_id                = aws_elb.elb_jenkins.zone_id
    evaluate_target_health = true
  }
}

# Create Security group for the jenkins elb
resource "aws_security_group" "jenkins-elb-sg" {
  name        = "${local.name}-jenkins-elb-sg"
  description = "Allow HTTPS"
  vpc_id      = aws_vpc.main.id
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

#create null resource to fetch vault token
resource "null_resource" "fetch_token" {
  depends_on = [time_sleep.wait_3_min]
  # create terraform provisioner to help fetch token file from the vault server
  provisioner "local-exec" {
    command = "scp -o StrictHostKeyChecking=no -i ./${local.name}-key.pem ubuntu@${aws_instance.vault_server.public_ip}:/home/ubuntu/token.txt ."
  }

  #  provisioner "locai-exec" {
  #    interpreter=["bash", "-c"]
  #    command= "sed -i '' \"s/token = \\\".*\\\"/token = \\\"$(cat ./token.txt)\\\"/\" ../provider.t"
  #  }
  provisioner "local-exec" {
    when    = destroy
    command = "rm -f ./token.txt"
  }
}


#create a time sleep resource that allow terraform to wait till vault server is ready
resource "time_sleep" "wait_3_min" {
  depends_on      = [aws_instance.vault_server]
  create_duration = "180s"
}