#!/bin/bash

cd opentofu
tofu apply -auto-approve

echo "Created VMs"

sleep 30

cd ../ansible
ansible-playbook site.yaml

echo "Deployed OpenWhisk"

echo "Sleeping for 5 minutes..."
sleep 300 # sleep for another 5 minutes to give more time to OpenWhisk

cd ..
./scripts/prepare_wsk.sh

# Create action refresh with simple hello.js
wsk -i action update refresh hello.js

echo "Action refresh created"

# Run refresh action to ensure configuration is loaded
wsk -i action invoke refresh -p controller_config_refresh true
wsk -i action invoke refresh -p controller_config_refresh true -r

echo "Refreshed configuration."

./scripts/create_tagged_actions.sh

echo "Created actions"

echo "Sleeping for 30 seconds..."

sleep 30 # sleep for good measure

./scripts/run_locust_tapp_functions.sh