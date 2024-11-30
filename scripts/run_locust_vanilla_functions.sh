
# Path to the file
HOSTS_FILE="ansible/hosts.ini"

# Extract the line containing 'eu_worker'
line=$(grep "^eu_worker " "$HOSTS_FILE")

# Check if the line was found
if [[ -z $line ]]; then
    echo "Error: 'eu_worker' line not found in $HOSTS_FILE"
    exit 1
fi

# Extract the private IP (value of 'private_ip=...')
eu_private_worker_ip=$(echo "$line" | sed -n 's/.*private_ip=\([^ ]*\).*/\1/p')

# Check if a private IP was found
if [[ -z $eu_private_worker_ip ]]; then
    echo "Error: private_ip not found in the 'eu_worker' line"
    exit 1
fi

# Export the private IP as an environment variable
export DATA_SERVER_IP="$eu_private_worker_ip"

# Print the value for confirmation
echo "DATA_SERVER_IP has been set to: $DATA_SERVER_IP"

control_line=$(grep "^control " "$HOSTS_FILE")

# Check if the line was found
if [[ -z $control_line ]]; then
    echo "Error: 'control' line not found in $HOSTS_FILE"
    exit 1
fi

# Extract the ansible_host for control
control_ip=$(echo "$control_line" | sed -n 's/.*ansible_host=\([^ ]*\).*/\1/p')

# Check if ansible_host was found
if [[ -z $control_ip ]]; then
    echo "Error: ansible_host not found in the 'control' line"
    exit 1
fi

# Export OWDEV_IP environment variable
export OWDEV_IP="$control_ip"
echo "OWDEV_IP has been set to: $OWDEV_IP"

cd bench
source venv/bin/activate
locust --headless --users 1 --spawn-rate 1 --host https://${OWDEV_IP}:31001