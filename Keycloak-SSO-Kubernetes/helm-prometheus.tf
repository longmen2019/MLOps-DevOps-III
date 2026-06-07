resource "helm_release" "kube_prometheus_stack" {
  name       = "prometheus"
  namespace  = "monitoring"
  create_namespace = true

  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "kube-prometheus-stack"
  version    = "45.7.1" # or whatever you used

  values = [
    file("${path.module}/monitoring-helm/values.yaml")
  ]
}
