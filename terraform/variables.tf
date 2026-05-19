variable "aws_region" {
  description = "AWS region where all resources are created"
  type        = string
  default     = "ap-south-1"
}

variable "project_name" {
  description = "Project name — used as prefix for all resource names and tags"
  type        = string
  default     = "GitOps-ArgoCD-Project"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "List of AZs to spread subnets across"
  type        = list(string)
  default     = ["ap-south-1a", "ap-south-1b"]
}

variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
  default     = "GitOps-ArgoCD-Project-cluster"
}

variable "node_group_name" {
  description = "EKS node group name"
  type        = string
  default     = "GitOps-ArgoCD-Project-node-group"
}

variable "node_instance_types" {
  description = "EC2 instance types for worker nodes"
  type        = list(string)
  default     = ["c7i-flex.large"]
}

variable "node_desired_size" {
  description = "Desired number of worker nodes"
  type        = number
  default     = 3
}

variable "node_min_size" {
  description = "Minimum number of worker nodes"
  type        = number
  default     = 3
}

variable "node_max_size" {
  description = "Maximum number of worker nodes"
  type        = number
  default     = 3
}

variable "ssh_key_name" {
  description = "EC2 key pair name for SSH access to worker nodes"
  type        = string
  default     = "GitOps-ArgoCD-Project key pair"
}
