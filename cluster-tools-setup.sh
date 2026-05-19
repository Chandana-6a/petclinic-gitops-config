#!/bin/bash
set -e

# STEP 1: Update & install dependencies
apt update && apt install -y unzip curl

# STEP 2: AWS CLI
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
rm -rf aws awscliv2.zip
echo "AWS CLI version: $(aws --version)"

# STEP 3: kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x kubectl
mv kubectl /usr/local/bin/kubectl
echo "kubectl version: $(kubectl version --client)"

# STEP 4: eksctl
curl -sLO "https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_$(uname -s)_amd64.tar.gz"
tar -xzvf eksctl_$(uname -s)_amd64.tar.gz -C /usr/local/bin
rm -f eksctl_$(uname -s)_amd64.tar.gz
echo "eksctl version: $(eksctl version)"

echo ""
echo "Done. Now run: aws configure"
