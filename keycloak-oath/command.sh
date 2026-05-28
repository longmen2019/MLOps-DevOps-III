#!/bin/bash

###############################################
# 1. Update WSL and install kubectl
###############################################

# Update package index
sudo apt update

# Install required packages for Kubernetes repo
sudo apt install -y ca-certificates curl apt-transport-https gnupg

# Create keyring directory
sudo mkdir -p /etc/apt/keyrings

# Add Kubernetes apt repo GPG key
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.30/deb/Release.key \
  | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

# Add Kubernetes apt repository
echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] \
https://pkgs.k8s.io/core:/stable:/v1.30/deb/ /" \
  | sudo tee /etc/apt/sources.list.d/kubernetes.list

# Update package index again
sudo apt update

# Install kubectl
sudo apt install -y kubectl

# Verify kubectl installation
kubectl version --client


###############################################
# 2. Configure kubeconfig inside WSL
###############################################

# Create kube directory
mkdir -p ~/.kube

# Copy kubeconfig from Windows into WSL
cp /mnt/c/Users/men_l/.kube/config ~/.kube/config

# Secure kubeconfig permissions
chmod 600 ~/.kube/config

# Test cluster connectivity
kubectl get nodes


###############################################
# 3. Add Helm repositories
###############################################

# Add Bitnami repo
helm repo add bitnami https://charts.bitnami.com/bitnami

# Add Codecentric repo (KeycloakX)
helm repo add codecentric https://codecentric.github.io/helm-charts

# Update repo index
helm repo update


###############################################
# 4. Install KeycloakX (successful deployment)
###############################################

# Install KeycloakX with working configuration
helm install keycloak codecentric/keycloakx \
  --namespace keycloak \
  --create-namespace \
  --set command[0]="/opt/keycloak/bin/kc.sh" \
  --set command[1]="start-dev" \
  --set keycloak.username=admin \
  --set keycloak.password="SuperSecurePassword123" \
  --set ingress.enabled=true \
  --set ingress.className=nginx \
  --set ingress.rules[0].host=keycloak.20.22.71.178.nip.io \
  --set ingress.rules[0].paths[0].path="/" \
  --set ingress.rules[0].paths[0].pathType=Prefix

# Check Keycloak pod status
kubectl get pods -n keycloak

# Check ingress resource
kubectl get ingress -n keycloak

# View Keycloak logs
kubectl logs -n keycloak keycloak-keycloakx-0


###############################################
# 5. Verify NGINX ingress controller
###############################################

kubectl get svc -n ingress-nginx


###############################################
# 6. Port-forward Keycloak service to localhost
###############################################

# Forward Keycloak HTTP service to local port 8080
kubectl port-forward -n keycloak svc/keycloak-keycloakx-http 8080:80
