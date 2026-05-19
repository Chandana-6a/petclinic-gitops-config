#!/bin/bash
set -e

sudo apt update -y
sudo apt upgrade -y

# Install Java 21 (required for modern Jenkins) and Java 17 (required for Maven build)
sudo apt install -y fontconfig openjdk-21-jdk openjdk-17-jdk git maven

# Set Java 21 as default (Jenkins requires it)
sudo update-alternatives --set java /usr/lib/jvm/java-21-openjdk-amd64/bin/java

java -version

# Clean any old Jenkins repo entries
sudo rm -f /etc/apt/sources.list.d/jenkins.list
sudo rm -f /usr/share/keyrings/jenkins-keyring.*

# Add Jenkins repo
sudo wget -O /etc/apt/keyrings/jenkins-keyring.asc \
  https://pkg.jenkins.io/debian-stable/jenkins.io-2026.key
echo "deb [signed-by=/etc/apt/keyrings/jenkins-keyring.asc] \
  https://pkg.jenkins.io/debian-stable binary/" | \
  sudo tee /etc/apt/sources.list.d/jenkins.list > /dev/null

sudo apt update
sudo apt install -y jenkins

sudo systemctl start jenkins
sudo systemctl enable jenkins
sudo systemctl status jenkins

echo "Jenkins initial admin password:"
sudo cat /var/lib/jenkins/initialAdminPassword