output "cluster_name" {
  description = "EKS cluster name"
  value       = aws_eks_cluster.cloudquicklabs.name
}

output "cluster_endpoint" {
  description = "EKS cluster API endpoint"
  value       = aws_eks_cluster.cloudquicklabs.endpoint
}

output "cluster_ca_certificate" {
  description = "Base64 encoded certificate for cluster auth"
  value       = aws_eks_cluster.cloudquicklabs.certificate_authority[0].data
}