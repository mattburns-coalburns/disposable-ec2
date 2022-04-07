# Disposable EC2 Instance
Build a disposable, test EC2 instance in Terraform that only allows SSH access.</br>
Test a script, test User Data (bootstrap) script, an AMI you've created in Packer, or whatever you need.</br>
`main.tf` is a flat Terraform configuration file that builds an EC2 instance with all dependencies necessary to SSH to it and lab.</br>
This build will create an SSH keypair on the machine you run this Terraform code from.</br>
A `terraform destroy` will nuke the instance, the VPC, the SSH keypair, and everything created from this build.

## Prerequisites
- Install Terraform on your machine
- Install AWS CLI
- Configure AWS CLI: https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-quickstart.html#cli-configure-quickstart-config

## Instructions
- Clone this repo: `git clone https://github.com/mattburns-coalburns/throwaway-ec2.git`
- `cd disposable ec2`
- `terraform init`
- `terraform apply --auto-approve`
- Copy/paste the output into your terminal
- When you're done: `terraform destroy --auto-approve` 

# Resources in this lab
- VPC
- Subnet
- Internet Gateway
- Route Table
- Security Groups
- EC2 Instance
- RSA 4096 Keys