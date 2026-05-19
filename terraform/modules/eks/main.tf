# ─── EKS Control Plane ────────────────────────────────────────────────────────

resource "aws_eks_cluster" "this" {
  name     = var.cluster_name
  role_arn = var.cluster_role_arn

  vpc_config {
    subnet_ids         = var.subnet_ids
    security_group_ids = [var.cluster_sg_id]
  }

  depends_on = [var.cluster_role_arn]
}

# ─── OIDC Provider ────────────────────────────────────────────────────────────
# Enables IRSA — allows Kubernetes service accounts to assume AWS IAM roles.
# Required for the EBS CSI driver to call ec2:CreateVolume when a PVC is created.

data "tls_certificate" "this" {
  url = aws_eks_cluster.this.identity[0].oidc[0].issuer
}

resource "aws_iam_openid_connect_provider" "this" {
  url             = aws_eks_cluster.this.identity[0].oidc[0].issuer
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.this.certificates[0].sha1_fingerprint]
}

# ─── Node Group ───────────────────────────────────────────────────────────────

resource "aws_eks_node_group" "this" {
  cluster_name    = aws_eks_cluster.this.name
  node_group_name = var.node_group_name
  node_role_arn   = var.node_group_role_arn
  subnet_ids      = var.subnet_ids

  scaling_config {
    desired_size = var.node_desired_size
    max_size     = var.node_max_size
    min_size     = var.node_min_size
  }

  instance_types = var.node_instance_types

  remote_access {
    ec2_ssh_key               = var.ssh_key_name
    source_security_group_ids = [var.node_sg_id]
  }

  depends_on = [aws_eks_cluster.this]
}

# ─── EBS CSI Driver Addon ─────────────────────────────────────────────────────
# Installs the AWS EBS CSI driver into the cluster as a managed addon.
# This is what allows Prometheus and Grafana PVCs to bind to real EBS volumes.
# Without this addon, all PVCs stay in Pending and monitoring pods never start.

resource "aws_eks_addon" "ebs_csi_driver" {
  cluster_name             = aws_eks_cluster.this.name
  addon_name               = "aws-ebs-csi-driver"
  service_account_role_arn = var.ebs_csi_driver_role_arn

  depends_on = [aws_eks_node_group.this]
}
