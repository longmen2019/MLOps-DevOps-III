resource "helm_release" "keycloak" {
  name             = "keycloak"
  namespace        = "keycloak"
  create_namespace = true

  repository = "https://codecentric.github.io/helm-charts"
  chart      = "keycloakx"

  set = [
    {
      name  = "command[0]"
      value = "/opt/keycloak/bin/kc.sh"
    },
    {
      name  = "command[1]"
      value = "start-dev"
    }
  ]

  values = [
    file("${path.module}/keycloak-helm/values.yaml")
  ]
}
