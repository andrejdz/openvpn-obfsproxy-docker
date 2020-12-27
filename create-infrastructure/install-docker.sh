#!/bin/bash

set -e

echo "Upgrading existing packages."
sudo apt-get update
sudo apt-get upgrade --yes
sudo apt-get autoremove --yes
sudo apt-get autoclean --yes

echo "Removing existing docker required packages."
sudo apt-get purge \
    --yes \
    docker \
    docker-engine \
    docker.io \
    containerd \
    runc

sudo rm -rf /var/lib/docker

echo "Installing required for docker installation packages."
sudo apt-get install \
    --yes \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg-agent \
    software-properties-common

echo "Installing docker GPG key."
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -

echo "Setting up docker stable repository."
sudo add-apt-repository \
   "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
   $(lsb_release -cs) \
   stable"

echo "Installing docker and required packages."
sudo apt-get install \
    --yes \
    docker-ce \
    docker-ce-cli \
    containerd.io

echo "Adding an user to docker group."
sudo usermod -aG docker $1

echo "Enabling docker daemon."
sudo systemctl enable docker

echo "Installing docker compose."
sudo curl \
    -sSL "https://github.com/docker/compose/releases/download/1.27.4/docker-compose-$(uname -s)-$(uname -m)" \
    -o /usr/local/bin/docker-compose

sudo chmod +x /usr/local/bin/docker-compose