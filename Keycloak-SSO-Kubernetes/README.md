# 📘 **Keycloak SSO on AKS with Grafana & kube‑prometheus‑stack**  
A fully automated, Terraform‑driven deployment of:

- Azure Kubernetes Service (AKS)  
- Keycloak (Helm)  
- kube‑prometheus‑stack (Prometheus + Grafana)  
- OAuth2 SSO integration between Grafana and Keycloak  
- Role‑based access control (RBAC) using Keycloak realm roles  

This project demonstrates a production‑grade identity and monitoring stack using modern cloud‑native tooling.

---

## 🚀 **Architecture Overview**

```
+---------------------------+
|        Terraform          |
|  (AKS + Helm Releases)    |
+------------+--------------+
             |
             v
+---------------------------+
| Azure Kubernetes Service  |
|        (AKS)              |
+---------------------------+
   |                    |
   |                    |
   v                    v
+--------+       +------------------+
|Keycloak|<----->|Grafana (OAuth2) |
|  Helm  |       | kube-prom-stack |
+--------+       +------------------+
   |
   | Internal DNS:
   | keycloak-keycloakx-http.keycloak.svc.cluster.local
   |
   v
+---------------------------+
| OAuth2 Authorization Code |
|   Token + Userinfo Flow   |
+---------------------------+
```

---

## 📦 **Components**

### **1. AKS Cluster**
Provisioned via Terraform:

- 1 node pool  
- Azure CNI  
- RBAC enabled  
- Network + resource group fully managed  

### **2. Keycloak (Helm: keycloakx)**
- Runs in namespace: `keycloak`  
- Exposed internally via ClusterIP  
- Admin user created via Helm values  
- Realm: `grafana`  
- Client: `grafana`  
- Client Scope: includes realm roles  
- Role mapping: `admin`, `viewer`, etc.

### **3. kube‑prometheus‑stack**
Includes:

- Prometheus  
- Grafana  
- Node Exporter  
- Kube State Metrics  
- Alertmanager  

Grafana is configured to authenticate **exclusively through Keycloak**.

---

## 🔐 **Grafana SSO Configuration**

Grafana uses OAuth2 Generic Provider with Keycloak.

### **Keycloak URLs (internal to AKS)**

```
http://localhost:8080/auth/realms/grafana/protocol/openid-connect/auth
http://keycloak-keycloakx-http.keycloak.svc.cluster.local/auth/realms/grafana/protocol/openid-connect/token
http://keycloak-keycloakx-http.keycloak.svc.cluster.local/auth/realms/grafana/protocol/openid-connect/userinfo
```

### **Grafana OAuth Block (values.yaml)**

```yaml
grafana:
  grafana.ini:
    auth:
      disable_login_form: false

    auth.generic_oauth:
      enabled: true
      name: Keycloak
      allow_sign_up: true
      client_id: grafana
      client_secret: "<YOUR-SECRET>"
      scopes: openid email profile

      auth_url:  http://localhost:8080/auth/realms/grafana/protocol/openid-connect/auth
      token_url: http://keycloak-keycloakx-http.keycloak.svc.cluster.local/auth/realms/grafana/protocol/openid-connect/token
      api_url:   http://keycloak-keycloakx-http.keycloak.svc.cluster.local/auth/realms/grafana/protocol/openid-connect/userinfo

      role_attribute_path: "contains(realm_access.roles[*], 'admin') && 'Admin' || 'Viewer'"
      login_attribute_path: preferred_username
      name_attribute_path: name
      email_attribute_path: email
```

---

## 🧩 **Role Mapping (Keycloak → Grafana)**

Keycloak realm roles included in the access token:

```
realm_access.roles = ["admin", "default-roles-grafana", ...]
```

Grafana maps:

- `admin` → Grafana Admin  
- everything else → Viewer  

This is controlled by:

```
role_attribute_path: "contains(realm_access.roles[*], 'admin') && 'Admin' || 'Viewer'"
```

---

## 🛠️ **Deployment Steps**

### **1. Deploy AKS**
```
terraform init
terraform apply
```

### **2. Connect kubectl**
```
az aks get-credentials -g <resource-group> -n <aks-name> --overwrite-existing
kubectl get nodes
```

### **3. Deploy Keycloak**
Terraform Helm release:

```
helm_release.keycloak
```

### **4. Deploy kube‑prometheus‑stack**
Terraform Helm release:

```
helm_release.kube_prometheus_stack
```

### **5. Restart Grafana after config changes**
```
kubectl delete pod -n monitoring -l app.kubernetes.io/name=grafana
```

### **6. Port-forward Grafana**
```
kubectl port-forward -n monitoring \
  $(kubectl get pod -n monitoring -l app.kubernetes.io/name=grafana -o jsonpath='{.items[0].metadata.name}') \
  3000:3000
```

Open:

```
http://localhost:3000
```

You will be redirected to Keycloak for login.

---

## 🧪 **Testing SSO**

### **Using Postman**
```
POST /auth/realms/grafana/protocol/openid-connect/token
grant_type=password
client_id=grafana
client_secret=<secret>
username=<user>
password=<password>
```

A valid response includes:

- `access_token`
- `refresh_token`
- `id_token`

### **Decoded Token Includes**
- `preferred_username`
- `email`
- `realm_access.roles`
- `name`

This confirms Keycloak → Grafana identity flow is correct.

---

## 📁 **Repository Structure**

```
.
├── main.tf
├── variables.tf
├── outputs.tf
├── keycloak-helm/
│   └── values.yaml
├── monitoring-helm/
│   └── values.yaml
└── README.md
```

---

## 🧹 **Cleanup**

```
terraform destroy
```

---

## 🏁 **Status**

✔ AKS deployed  
✔ Keycloak deployed  
✔ kube‑prometheus‑stack deployed  
✔ Grafana SSO working  
✔ Role mapping working  
✔ Tokens validated  
✔ Terraform fully automated  