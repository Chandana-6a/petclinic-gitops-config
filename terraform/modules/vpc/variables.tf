variable "project_name" {
  description = "Project name used as prefix for all resource names and tags"
  type        = string
}

variable "cluster_name" {
  description = "EKS cluster name — used to tag subnets for ELB discovery"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "List of AZs to spread subnets across"
  type        = list(string)
}
