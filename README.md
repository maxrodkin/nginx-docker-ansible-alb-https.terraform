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
cd ./ssl
chmod +x create_self_cert.sh ; ./create_self_cert.sh
```

Left the created files as is.

## Create the infrastructure (terraform , AWS CLI setup is omitted)

```
cd ..
terraform init
terraform plan -out terraform.tfplan
terraform apply "terraform.tfplan"
```

use the terraform output to connect to the instances and ALB.\
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

shut down 2 instances. Check them from ansible:
```
$ sudo su
# cd /opt/mydir
# /usr/local/bin/ansible -i inventory nginx --key-file ansible.pem -m ping
```

Check the service with curl or browser immidiatelly. You will get the HTTP 503 error.
In 1 minute the target group rebuilds the service with health-check and switches all trafick on last alive nginx.

Start the instances again. It will be restored in service in couple of minutes.

## Destroy the infrastructure
```
terraform plan -destroy -out terraform.tfplan
terraform apply "terraform.tfplan"
```
## Further improvements of current code:

1. put all af assets in S3 and read them during cloud-init
2. use different AZs for nginx
3. use last "terraform-aws-modules/alb/aws" as the "8.7.0" is outdated
4. use signed certificate with legal DNS zone
   
## Further scaling:

1. nginx redis cache
2. EFS for single instance of content
3. AutScaing Groups
4. ECS/EKS
5. S3 for static content
6. ElastiCache
7. Route53 health-checks, DNS failover , advanced routing
8. CloudFront
9. AWS Global Accelerator
   