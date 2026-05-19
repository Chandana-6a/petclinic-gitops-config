output "cluster_id" {
  description = "EKS cluster ID"
  value       = module.eks.cluster_id
}

output "cluster_name" {
  description = "EKS cluster name"
  value       = module.eks.cluster_name
}

output "cluster_endpoint" {
  description = "EKS API server endpoint"
  value       = module.eks.cluster_endpoint
}

output "node_group_id" {
  description = "EKS node group ID"
  value       = module.eks.node_group_id
}

output "vpc_id" {
  description = "VPC ID"
  value       = module.vpc.vpc_id
}

output "subnet_ids" {
  description = "List of subnet IDs"
  value       = module.vpc.subnet_ids
}

output "cluster_security_group_id" {
  description = "Security group ID for the EKS control plane"
  value       = module.vpc.cluster_sg_id
}

output "node_security_group_id" {
  description = "Security group ID for EKS worker nodes"
  value       = module.vpc.node_sg_id
}

output "ebs_csi_driver_role_arn" {
  description = "EBS CSI driver IRSA role ARN — useful for debugging PV issues"
  value       = module.iam.ebs_csi_driver_role_arn
}

output "oidc_provider_arn" {
  description = "OIDC provider ARN — needed for any future IRSA roles"
  value       = module.eks.oidc_provider_arn
}

output "kubeconfig_command" {
  description = "Run this after apply to configure kubectl"
  value       = "aws eks update-kubeconfig --region ${var.aws_region} --name ${var.cluster_name}"
}
