################################################################################
# Minimal EC2 deployment (single instance + security group + optional EIP)
################################################################################

locals {
  ami = coalesce(var.ami, try(nonsensitive(data.aws_ssm_parameter.this[0].value), null))
}

# Only look up the SSM AMI parameter if no explicit AMI was given
data "aws_ssm_parameter" "this" {
  count = var.ami == null ? 1 : 0
  name  = var.ami_ssm_parameter
}

################################################################################
# Security Group
################################################################################

resource "aws_security_group" "this" {
  count = var.create_security_group ? 1 : 0

  name        = var.name
  description = "Security group for ${var.name}"
  vpc_id      = aws_vpc.this.id

  dynamic "ingress" {
    for_each = var.ingress_rules
    content {
      description = lookup(ingress.value, "description", null)
      from_port   = ingress.value.from_port
      to_port     = ingress.value.to_port
      protocol    = ingress.value.protocol
      cidr_blocks = ingress.value.cidr_blocks
    }
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, { Name = var.name })
}

################################################################################
# EC2 Instance
################################################################################

resource "aws_instance" "this" {
  ami                         = local.ami
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.this.id
  key_name                    = aws_key_pair.this.key_name
  associate_public_ip_address = var.associate_public_ip_address

  vpc_security_group_ids = var.create_security_group ? [aws_security_group.this[0].id] : var.vpc_security_group_ids

  user_data = var.user_data

  root_block_device {
    volume_size = var.root_volume_size
    volume_type = var.root_volume_type
    encrypted   = true
  }

  tags = merge(var.tags, { Name = var.name })
}

################################################################################
# Elastic IP (optional)
################################################################################

resource "aws_eip" "this" {
  count = var.create_eip ? 1 : 0

  domain   = "vpc"
  instance = aws_instance.this.id

  tags = merge(var.tags, { Name = var.name })
}

resource "tls_private_key" "this" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "this" {
  key_name   = "my-key"
  public_key = tls_private_key.this.public_key_openssh
}

output "private_key_pem" {
  value     = tls_private_key.this.private_key_pem
  sensitive = true
}
