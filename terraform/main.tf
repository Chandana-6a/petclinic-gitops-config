provider "aws" {
  region = var.aws_region
}

module "vpc" {
  source = "./modules/vpc"

  project_name       = var.project_name
  cluster_name       = var.cluster_name
  vpc_cidr           = var.vpc_cidr
  availability_zones = var.availability_zones
}

module "eks" {
  source = "./modules/eks"

  cluster_name            = var.cluster_name
  node_group_name         = var.node_group_name
  cluster_role_arn        = module.iam.cluster_role_arn
  node_group_role_arn     = module.iam.node_group_role_arn
  ebs_csi_driver_role_arn = module.iam.ebs_csi_driver_role_arn
  subnet_ids              = module.vpc.subnet_ids
  cluster_sg_id           = module.vpc.cluster_sg_id
  node_sg_id              = module.vpc.node_sg_id
  node_instance_types     = var.node_instance_types
  node_desired_size       = var.node_desired_size
  node_min_size           = var.node_min_size
  node_max_size           = var.node_max_size
  ssh_key_name            = var.ssh_key_name
}

module "iam" {
  source = "./modules/iam"

  project_name  = var.project_name
  oidc_provider = module.eks.oidc_provider
}

# ─── Cleanup ELBs before VPC destroy ─────────────────────────────────────────
# Kubernetes LoadBalancer services create classic ELBs outside Terraform.
# They must be deleted before subnets/IGW/VPC can be destroyed.

resource "null_resource" "cleanup_elbs" {
  triggers = {
    vpc_id     = module.vpc.vpc_id
    aws_region = var.aws_region
  }

  provisioner "local-exec" {
    when    = destroy
    command = <<-EOT
      echo "Deleting classic ELBs in VPC ${self.triggers.vpc_id}..."
      ELB_NAMES=$(aws elb describe-load-balancers \
        --region ${self.triggers.aws_region} \
        --query "LoadBalancerDescriptions[?VPCId=='${self.triggers.vpc_id}'].LoadBalancerName" \
        --output text)
      for name in $ELB_NAMES; do
        echo "Deleting ELB: $name"
        aws elb delete-load-balancer \
          --load-balancer-name "$name" \
          --region ${self.triggers.aws_region}
      done
      sleep 30
    EOT
  }

  depends_on = [module.eks, module.vpc]
}

# ─── Cleanup EBS volumes created by Kubernetes PVCs ──────────────────────────
# Prometheus and Grafana PVCs create EBS volumes outside Terraform's knowledge.
# These must be deleted before the cluster is fully destroyed.

resource "null_resource" "cleanup_ebs_volumes" {
  triggers = {
    cluster_name = var.cluster_name
    aws_region   = var.aws_region
  }

  provisioner "local-exec" {
    when    = destroy
    command = <<-EOT
      echo "Deleting EBS volumes created by Kubernetes PVCs..."
      VOLUME_IDS=$(aws ec2 describe-volumes \
        --region ${self.triggers.aws_region} \
        --filters "Name=tag:kubernetes.io/cluster/${self.triggers.cluster_name},Values=owned" \
                  "Name=status,Values=available" \
        --query "Volumes[*].VolumeId" \
        --output text)
      for vol in $VOLUME_IDS; do
        echo "Deleting EBS volume: $vol"
        aws ec2 delete-volume \
          --volume-id "$vol" \
          --region ${self.triggers.aws_region}
      done
    EOT
  }

  depends_on = [module.eks]
}

# ─── Cleanup ELBs before VPC destroy ─────────────────────────────────────────
# Kubernetes LoadBalancer services create classic ELBs outside Terraform.
# They must be deleted before subnets/IGW/VPC can be destroyed.

resource "null_resource" "cleanup_elbs" {
  triggers = {
    vpc_id     = module.vpc.vpc_id
    aws_region = var.aws_region
  }

  provisioner "local-exec" {
    when    = destroy
    command = <<-EOT
      echo "Deleting classic ELBs in VPC ${self.triggers.vpc_id}..."
      ELB_NAMES=$(aws elb describe-load-balancers \
        --region ${self.triggers.aws_region} \
        --query "LoadBalancerDescriptions[?VPCId=='${self.triggers.vpc_id}'].LoadBalancerName" \
        --output text)
      for name in $ELB_NAMES; do
        echo "Deleting ELB: $name"
        aws elb delete-load-balancer \
          --load-balancer-name "$name" \
          --region ${self.triggers.aws_region}
      done
      sleep 30
    EOT
  }

  depends_on = [module.eks, module.vpc]
}

# ─── Cleanup EBS volumes created by Kubernetes PVCs ──────────────────────────
# Prometheus and Grafana PVCs create EBS volumes outside Terraform's knowledge.
# These must be deleted before the cluster is fully destroyed.

resource "null_resource" "cleanup_ebs_volumes" {
  triggers = {
    cluster_name = var.cluster_name
    aws_region   = var.aws_region
  }

  provisioner "local-exec" {
    when    = destroy
    command = <<-EOT
      echo "Deleting EBS volumes created by Kubernetes PVCs..."
      VOLUME_IDS=$(aws ec2 describe-volumes \
        --region ${self.triggers.aws_region} \
        --filters "Name=tag:kubernetes.io/cluster/${self.triggers.cluster_name},Values=owned" \
                  "Name=status,Values=available" \
        --query "Volumes[*].VolumeId" \
        --output text)
      for vol in $VOLUME_IDS; do
        echo "Deleting EBS volume: $vol"
        aws ec2 delete-volume \
          --volume-id "$vol" \
          --region ${self.triggers.aws_region}
      done
    EOT
  }

  depends_on = [module.eks]
}