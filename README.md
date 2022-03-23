# ow-gcp

To deploy the cluster on Google Cloud Platform there is a terraform script in the folder terraform.

1. Update terraform.tfvars with the correct values for your Google cloud user and project
2. Update credentials.json accordingly (retrievable from Google Cloud Platform)
3. Provide an ssh key pair called ow-gcp-key, which will be used to setup ssh access for ansible
4. Run `terraform apply` in terraform folder in order to deploy 8 virtual machines (1 K8S master, 3 OpenWhisk controllers and 4 Invokers)
5. Wait a few seconds and move into ansible folder
6. Run `ansible-playbook cluster.yaml` to deploy a K8S cluster and OpenWhisk on top of it

You're good to go. To set up the wsk command-line tool to be used with the deployed platform, checkout the [official repository](https://github.com/apache/openwhisk-cli#downloading-released-binaries).

You can see the IPs of the deployed machines in the file hosts.ini in the ansible folder (after running terraform).