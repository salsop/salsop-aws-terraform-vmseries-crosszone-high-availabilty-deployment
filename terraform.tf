terraform {
  required_version = "> 0.13.4"

  required_providers {
    aws = {
      version = "= 3.21.0"
    }

    http = {
      version = "= 2.0.0"
    }

    template = {
      version = "= 2.2.0"
    }
  }

}