# Task description

We would like you to deploy three NGINX instances to the public cloud provider of your choice, with the following caveats:
All instances should sit behind a load balancer
All instances should be running NGINX in a container
While all instances of NGINX should be accessible through the internet via the load balancer, direct internet access to the VMs themselves should not be possible
If two instances go down, service should not be interrupted
HTTPS should be supported
The /phrase endpoint should return a 200 OK status code
Final notes
Feel free to install any tooling you'd like on the instances
While not mandatory, making the config repeatable is a bonus - consider using Ansible
Please include a brief guide/document in your submission that outlines your approach, any potential future improvements, as well as instructions on how to run the deployment in a fresh environment

# Work flow

## Create SSL self-signed certificale files

```
cd .\ssl
chmod +x create_self_cert.sh ; .\create_self_cert.sh
```

Left the created files as is.

## Create the infrastructure (terraform , AWS CLI setup is omitted)

```
terraform init
terraform plan -out terraform.tfplan
terraform apply "terraform.tfplan"
```

use the terraform output to connect to the instances and ALB
on an ansible instance you may check the reacability of nginx instances:

```
 cat /opt/mydir/ansible-ping-test.txt
10.0.0.236 | SUCCESS => {
...
10.0.0.16 | SUCCESS => {
...
10.0.0.156 | SUCCESS => {
...
```

## Destroy the infrastructure
```
terraform plan -destroy -out terraform.tfplan
terraform apply "terraform.tfplan"
```
