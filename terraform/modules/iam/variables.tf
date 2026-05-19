variable "project_name" {
  description = "Project name used as prefix for all IAM resource names"
  type        = string
}

variable "oidc_provider" {
  description = "OIDC provider URL without https:// — from eks module output, used for EBS CSI IRSA trust policy"
  type        = string
}
