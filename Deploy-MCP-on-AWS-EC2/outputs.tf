output "vpc_id" {
  value = aws_vpc.this.id
}

output "subnet_id" {
  value = aws_subnet.this.id
}

output "instance_id" {
  value = aws_instance.this.id
}

output "public_ip" {
  value = var.create_eip ? aws_eip.this[0].public_ip : aws_instance.this.public_ip
}

output "private_ip" {
  value = aws_instance.this.private_ip
}

output "security_group_id" {
  value = var.create_security_group ? aws_security_group.this[0].id : null
}
