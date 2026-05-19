output "vpc_id" {
  description = "ID of the created VPC"
  value       = aws_vpc.this.id
}

output "subnet_ids" {
  description = "List of public subnet IDs"
  value       = aws_subnet.this[*].id
}

output "cluster_sg_id" {
  description = "Security group ID for the EKS control plane"
  value       = aws_security_group.cluster.id
}

output "node_sg_id" {
  description = "Security group ID for EKS worker nodes"
  value       = aws_security_group.node.id
}
