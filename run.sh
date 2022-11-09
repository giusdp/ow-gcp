#!/bin/bash

cd terraform
terraform apply -auto-approve
cd ../ansible
ansible-playbook cluster.yaml

https://www.mongodb.com/docs/v6.0/tutorial/deploy-replica-set-for-testing/

https://stackoverflow.com/questions/38524150/mongodb-replica-set-with-simple-password-authentication

rsconf = {
  _id: "rs0",
  members: [
    {
     _id: 0,
     host: "10.132.0.3:27017"
    },
    {
     _id: 1,
     host: "10.142.0.2:27018"
    }
   ]
}

rs.initiate( rsconf )
