![Support:Community](https://img.shields.io/badge/Support-Community-blue)
![License:MIT](https://img.shields.io/badge/License-MIT-blue)
[![CI/CD](https://github.com/salsop/salsop-aws-terraform-vmseries-crosszone-high-availabilty-deployment/actions/workflows/terraform.yml/badge.svg)](https://github.com/salsop/salsop-aws-terraform-vmseries-crosszone-high-availabilty-deployment/actions/workflows/terraform.yml)

# AWS Cross-Zone High Availability Deployment

## Overview

Deploying the Palo Alto Networks VM-Series in a High Availability pair across AWS Availability Zones is useful for terminating site to site VPN IPSEC with a single VPN tunnel, or without the need for dynamic routing protocols.

This deployment uses the 'Secondary IP' High Availability Mode of the VM-Series Plug-in v2.0.3 (or above) that allows for cross-zone high availability pairs.

The use cases for this deployment are:
- VPN Termination of IPSEC Tunnels onto VM-Series Firewalls in AWS. This providing a Security and NAT Boundary between the networks.

### Deployed Resources

The following resources are deployed as part of this plan:

- 1x VPC
- 1x Internet Gateway
- 10x Subnets
  - Management (x2) **(PUBLIC)**
  - HA2 (x2) **(PRIVATE)**
  - Public (x2) **(PUBLIC)**    
  - Private (x2) **(PRIVATE)**
  - TGW (x2) **(PRIVATE)**
- 3x Route Tables
  - Public
  - Private
  - TGW
- 2x VM-Series EC2 Instances
  - VM-Series (AZ0)
  - VM-Series (AZ1)
- 2x Security Groups
  - Management Security Group
  - Data Security Group
- 2x S3 Bucket
  - VM-Series Bootstrap (AZ0)
  - VM-Series Bootstrap (AZ1)
- IAM Role
  - EC2 Instance Role for BootStrapping and High-Availability Fail-over.

### Security Groups

#### Management Security Group (vmseries_management)

This security group is associated to the Management Interface of the VM-Series EC2 Instances.

|Direction|Protocol|Port|Source IP|
|:-----|:-----:|:-----:|:-----|
|Inbound|TCP|22|Internet IP of the Terraform Client|
|Inbound|TCP|443|Internet IP of the Terraform Client|
|Inbound|ICMP|Any|Internet IP of the Terraform Client|
|Inbound|Any|Any|Management Subnet CIDR Range|
|Outbound|Any|Any|0.0.0.0/0|

#### VM-Series Data Security Group (vmseries_data)

This security group is associated to all the Data Interfaces on the VM-Series EC2 Instances.

|Direction|Protocol|Port|Source IP|
|:-----|:-----:|:-----:|:-----|
|Inbound|Any|Any|0.0.0.0/0|
|Outbound|Any|Any|0.0.0.0/0|

### Example Subnet Allocation

From the VPC CIDR the Terraform plan uses 4 bits to allow for subnetting the VPC CIDR into the required subnets, so a VPC CIDR of /24 uses subnets of CIDR /28.

|Default VPC CIDR Range|10.0.0.0/24|
|:-----------|:-----------:|
|vmseries-management-az0|10.0.0.0/28|
|vmseries-management-az1|10.0.0.16/28|
|vmseries-ha2-az0|10.0.0.32/28|
|vmseries-ha2-az1|10.0.0.48/28|
|vmseries-private-az0|10.0.0.64/28|
|vmseries-private-az1|10.0.0.80/28|
|vmseries-public-az0|10.0.0.96/28|
|vmseries-public-az1|10.0.0.112/28|
|vmseries-tgw-az0|10.0.0.128/28|
|vmseries-tgw-az1|10.0.0.144/28|

## Deployment

This deployment uses terraform and has the following prerequisites:

- **Terraform 0.13 (or above)** installed.
- **AWS CLI** installed and configured with access to your AWS Environment.
- A reserved **/24 CIDR Block** for the VM-Series VPC.
- An **EC2 Key Pair** created in the region you wish to deploy to.

### Step 1: Clone the Repository

Clone the repository locally on your computer to allow for you to run the deployment.
```
$ git clone https://github.com/salsop/aws-terraform-vmseries-crosszone-high-availabilty-deployment/actions
```

:exclamation: Change any of the default values as needed prior to the next steps.

Variables can be found in the `variables.tf` file.

You must change the following variables:
|Variable Name|Usage|
|:-----|:-----|
|`vmseries.aws_key`|Name of an existing AWS EC2 Key Pair.

You can also optionally change the following:

|Variable Name|Usage|
|:-----|:-----|
|`aws_region`|AWS Region Name for deployment (e.g. `eu-west-1`)|
|`vpc_cidr`|AWS VPC CIDR (e.g. `10.0.0.0/24`)|
|`vmseries.license_type`|VM-Series License Type. Possible options are: `byol`, `bundle1` or `bundle2`|
|`vmseries.version`|VM-Series Version. Select the appropriate version you wish to deploy. This deployment was tested with `10.0.3`|
|`vmseries.instance_type`|AWS EC2 Instance Type for the VM-Series Instances.|
|`vmseries.authcodes`|VM-Series Licensing Auth-Code. This is only required if you select `byol` as the license type, otherwise leave blank.|

### Step 2: Initialize Terraform

Initialize the working directory containing Terraform configuration files:

```bash
$ terraform init
```

### Step 3: Review the Terraform Plan

Run this command to view the resources Terraform will create as part of this plan. Confirm you are happy and understand the changes that will be made as part of this deployment.

```bash
$ terraform plan
```

### Step 4: Deploy the Infrastructure

Ensure you have reviewed the Terraform Plan in Step 2 above before proceeding with this step.

:exclamation: Running this command will immediately start the deployment.
```bash
$ terraform apply -auto-approve
```

After the deployment you will see the following Terraform Outputs, to inform you of any IPs you may need to setup and configure, if you chose not to bootstrap the VM-Series.

```bash
Outputs:

floating_eip = 1.2.3.4 --------------> External IP that moves to the Active VM-Series
vmseries0_ha2_gateway = 10.0.0.33 ---> VMSeries0 -> HA2 Default Gateway
vmseries0_ha2_ip = 10.0.0.39 --------> VMSeries0 -> HA2 IP
vmseries0_mgmt_eip = 1.2.3.4 --------> VMSeries0 -> Management Elastic IP
vmseries0_mgmt_ip = 10.0.0.7 --------> VMSeries0 -> Management Private IP
vmseries1_ha2_gateway = 10.0.0.49 ---> VMSeries1 -> HA2 Default Gateway
vmseries1_ha2_ip = 10.0.0.54 --------> VMSeries1 -> HA2 IP
vmseries1_mgmt_eip = 1.2.3.4 --------> VMSeries1 -> Management Elastic IP
vmseries1_mgmt_ip = 10.0.0.28 -------> VMSeries1 -> Management Private IP
```

:exclamation: The default username `admin` and password `Pal0ALto!` will be set when bootstrapped please ensure you change these immediately after provisioning.

### Step 5: Configure VPNs & TGW

You can now proceed with configuring the VM-Series for connectivity to any systems by IPSEC VPNs. 

You can also connect this VM-Series to a TGW using the TGW Subnets as needed.
