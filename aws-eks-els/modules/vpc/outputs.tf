output "vpc_id" {
  value = aws_vpc.cloudquicklabs.id
}

output "public_subnets" {
  value = aws_subnet.public_cloudquicklabs_subnet[*].id
}
