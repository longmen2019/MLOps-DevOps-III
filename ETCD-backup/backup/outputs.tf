output "namespace" {
  value = kubernetes_namespace_v1.backup.metadata[0].name
}

output "pvc_name" {
  value = kubernetes_persistent_volume_claim_v1.backup.metadata[0].name
}
