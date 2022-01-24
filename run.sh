#!/bin/bash

cd terraform
terraform apply -auto-approve
cd ../ansible
ansible-playbook cluster.yaml