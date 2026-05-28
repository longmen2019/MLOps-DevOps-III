## Keycloak Deployment on AKS with Ingress, TLS, and OAuth2‑Proxy Preparation  
This project documents the end‑to‑end setup of a production‑ready Keycloak environment running on Azure Kubernetes Service (AKS). The work includes cluster preparation, namespace organization, Helm‑based deployments, ingress configuration, TLS enablement, and the initial foundation for integrating OAuth2‑Proxy as an authentication layer.

This README captures everything completed up to the point before the final OAuth provider configuration.

---

## 📌 Architecture Overview  
The environment consists of:

- **AKS Cluster** (Azure Kubernetes Service)  
- **Keycloak** deployed via Helm  
- **NGINX Ingress Controller**  
- **TLS termination** using self‑signed or external certificates  
- **Dedicated namespaces** for clean separation  
- **Service exposure** through Ingress  
- **OAuth2‑Proxy groundwork** (deployment + service, before provider configuration)

The goal is to create a secure, modular identity platform suitable for internal applications, testing, and future expansion.

---

## 🏗️ 1. Cluster & Namespace Setup  
A dedicated namespace was created to isolate identity‑related components:

```bash
kubectl create namespace keycloak
```

This ensures clean separation between Keycloak, ingress resources, and future authentication components.

---

## 🚀 2. Deploying Keycloak via Helm  
Keycloak was deployed using the official Helm chart, configured for:

- Stateful operation  
- External database or embedded DB (depending on your values file)  
- Admin credentials  
- Service exposure inside the cluster  

Example deployment:

```bash
helm repo add bitnami https://charts.bitnami.com/bitnami
helm install keycloak bitnami/keycloak -n keycloak -f keycloak-values.yaml
```

After deployment:

```bash
kubectl get pods -n keycloak
```

Keycloak became reachable internally via:

```
http://keycloak.keycloak.svc.cluster.local:8080
```

---

## 🌐 3. Installing NGINX Ingress Controller  
To expose Keycloak externally, the NGINX ingress controller was installed:

```bash
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm install ingress-nginx ingress-nginx/ingress-nginx -n ingress-nginx --create-namespace
```

This provides:

- Load balancing  
- Path‑based routing  
- TLS termination  
- Compatibility with OAuth2‑Proxy  

---

## 🔐 4. TLS Certificate Setup  
A TLS secret was created to secure the Keycloak endpoint:

```bash
kubectl create secret tls keycloak-tls \
  --cert=keycloak.crt \
  --key=keycloak.key \
  -n keycloak
```

This certificate is referenced by the ingress resource.

---

## 🚪 5. Keycloak Ingress Configuration  
An ingress resource was created to expose Keycloak externally:

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: keycloak
  namespace: keycloak
  annotations:
    nginx.ingress.kubernetes.io/backend-protocol: "HTTP"
spec:
  tls:
    - hosts:
        - keycloak.local
      secretName: keycloak-tls
  rules:
    - host: keycloak.local
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: keycloak
                port:
                  number: 8080
```

After updating `/etc/hosts`, Keycloak became accessible at:

```
https://keycloak.local
```

---

## 🧱 6. Preparing OAuth2‑Proxy (Deployment + Service Only)  
Before configuring the provider, OAuth2‑Proxy was deployed via Helm:

```bash
helm repo add oauth2-proxy https://oauth2-proxy.github.io/manifests
helm install oauth2-proxy oauth2-proxy/oauth2-proxy -n keycloak
```

This created:

- Deployment  
- Service  
- ConfigMap (default)  

At this stage, OAuth2‑Proxy was installed but **not yet configured** to use Keycloak or any other provider.

This is where we intentionally stop — before the provider configuration and troubleshooting.

---

## 📂 Project Structure  
```
.
├── keycloak-values.yaml
├── oauth2-values.yaml        # (initial placeholder before provider config)
├── ingress/
│   ├── keycloak-ingress.yaml
│   └── tls/
│       ├── keycloak.crt
│       └── keycloak.key
└── README.md
```

---

## ✅ Current Status  
As of this stage:

- AKS cluster is running  
- Keycloak is deployed and reachable  
- Ingress + TLS are fully functional  
- OAuth2‑Proxy is installed and ready for provider configuration  
- Environment is prepared for OIDC integration  

The next step (not included here) would be configuring OAuth2‑Proxy to authenticate against Keycloak.

---

