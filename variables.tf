variable "aws_region" {
  description = "AWS Region for Deployment"
  default     = "eu-west-1"
}

variable "vpc_cidr" {
  description = "AWS VPC CIDR (/24 Minimum Required)"
  default     = "10.0.0.0/24"
}

variable "vmseries" {
  default = {
    # License Type, Available options are "byol", "bundle1" or "bundle2"
    license_type = "bundle2"

    # Possible Versions: 9.1.2 9.1 10.0 9.1.3 9.0.9.xfr 10.0.3 10.0.4
    version = "10.0.3"

    instance_type = "m5.xlarge" # c4.4xlarge
    aws_key       = "eu-west-1"
    authcodes     = ""
  }
}

variable "panorama" {
  default = {
    primary             = ""
    secondary           = ""
    vm_auth_key         = ""
    template_stack_name = ""
    device_group_name   = ""
    pin_id              = ""
    pin_value           = ""
  }
}