#!/bin/bash

cd gcp-terraform
terraform apply
cd ../k8s-ansible
ansible-playbook cluster.yml