#!/bin/bash

set -e

# Enable universe repo and update
sudo add-apt-repository universe -y
sudo apt-get update

# Install Python and pip
sudo apt-get install -y python3 python3-pip python3-venv

# Upgrade pip and install Ansible with Azure support
sudo pip3 install --upgrade pip
sudo pip3 install 'ansible[azure]'

# Ensure ansible is in PATH
echo 'export PATH=$PATH:/usr/local/bin' >> ~/.bashrc
source ~/.bashrc

# Install Azure collection
ansible-galaxy collection install azure.azcollection

# Install additional Azure dependencies
wget https://raw.githubusercontent.com/ansible-collections/azure/dev/requirements-azure.txt
sudo pip3 install -r requirements-azure.txt
