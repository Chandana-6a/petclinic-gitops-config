#!/bin/bash
set -e

# Delete the legacy gp2 auto-created by EKS before recreating with CSI provisioner
kubectl delete storageclass gp2 --ignore-not-found=true
sleep 5

# Prometheus + Grafana on EKS — Installation Script
# The EBS CSI driver addon (provisioned by Terraform) handles all PVC creation.

# ─── Step 1: Install Helm ─────────────────────────────────────────────────────
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
echo "Helm version: $(helm version --short)"

# ─── Step 2: Configure kubectl ────────────────────────────────────────────────
aws eks update-kubeconfig --region ap-south-1 --name GitOps-ArgoCD-Project-cluster

# Verify nodes are Ready
kubectl get nodes

# ─── Step 3: Verify EBS CSI driver is running ─────────────────────────────────
kubectl get pods -n kube-system | grep ebs-csi
# Expected: ebs-csi-controller pods Running, ebs-csi-node daemonset pods Running

# ─── Step 4: Create the gp2 StorageClass (set as default) ────────────────────
# This tells Kubernetes to use EBS gp2 volumes for all PVCs by default.
# kube-prometheus-stack creates several PVCs — without this StorageClass
# they would stay Pending and all monitoring pods would never start.

cat <<EOF | kubectl apply -f -
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: gp2
  annotations:
    storageclass.kubernetes.io/is-default-class: "true"
provisioner: ebs.csi.aws.com
volumeBindingMode: WaitForFirstConsumer
reclaimPolicy: Retain
parameters:
  type: gp2
  encrypted: "true"
EOF

# Verify it shows (default)
kubectl get storageclass

# ─── Step 5: Add Helm repos ───────────────────────────────────────────────────
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add stable https://charts.helm.sh/stable
helm repo update

# ─── Step 6: Install kube-prometheus-stack ────────────────────────────────────
# This single Helm chart installs:
#   - Prometheus (with persistent storage via EBS)
#   - Grafana    (with persistent storage via EBS)
#   - Alertmanager
#   - Node exporter daemonset
#   - kube-state-metrics

kubectl create namespace monitoring

helm install monitoring prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --set prometheus.prometheusSpec.storageSpec.volumeClaimTemplate.spec.storageClassName=gp2 \
  --set prometheus.prometheusSpec.storageSpec.volumeClaimTemplate.spec.resources.requests.storage=20Gi \
  --set grafana.persistence.enabled=true \
  --set grafana.persistence.storageClassName=gp2 \
  --set grafana.persistence.size=5Gi \
  --set grafana.service.type=LoadBalancer \
  --set prometheus.service.type=LoadBalancer \
  --set alertmanager.alertmanagerSpec.storage.volumeClaimTemplate.spec.storageClassName=gp2 \
  --set alertmanager.alertmanagerSpec.storage.volumeClaimTemplate.spec.resources.requests.storage=5Gi

# ─── Step 7: Wait for pods to be Ready ────────────────────────────────────────
echo "Waiting for monitoring pods to be Ready..."
kubectl wait --for=condition=Ready pods --all -n monitoring --timeout=300s

kubectl get pods -n monitoring

# ─── Step 8: Get Prometheus URL ───────────────────────────────────────────────
echo "Prometheus URL:"
kubectl get svc -n monitoring monitoring-kube-prometheus-prometheus
# Open EXTERNAL-IP in browser on port 9090

# ─── Step 9: Get Grafana URL and password ─────────────────────────────────────
echo "Grafana URL:"
kubectl get svc -n monitoring monitoring-grafana
# Open EXTERNAL-IP in browser on port 80

echo "Grafana admin password:"
kubectl get secret -n monitoring monitoring-grafana \
  -o jsonpath="{.data.admin-password}" | base64 --decode; echo

# ─── Step 10: Verify PVCs are Bound ───────────────────────────────────────────
kubectl get pvc -n monitoring