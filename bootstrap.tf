#----------------------------------------------------------------------------------------------------------------------
# Generate Unique Name for S3 Bucket
#----------------------------------------------------------------------------------------------------------------------

locals {
  s3_bootstrap_bucket_name = "vmseriesbootstrap${random_string.unique_id.result}"
}

#----------------------------------------------------------------------------------------------------------------------
# Create S3 Bucket for Bootstrap
#----------------------------------------------------------------------------------------------------------------------

resource "aws_s3_bucket" "bucket" {
  count         = 2
  bucket        = "${local.s3_bootstrap_bucket_name}${count.index}"
  acl           = "private"
  force_destroy = true

  versioning {
    enabled = true
  }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }

  tags = {
    Name = "${local.s3_bootstrap_bucket_name}${count.index}"
  }
}

#----------------------------------------------------------------------------------------------------------------------
# Create Folder Structure & Populate Files
#----------------------------------------------------------------------------------------------------------------------

# /config
resource "aws_s3_bucket_object" "config" {
  count   = 2
  bucket  = aws_s3_bucket.bucket[count.index].id
  acl     = "private"
  key     = "config/"
  content = " "
}

# /config/init-cfg.txt

data "template_file" "initcfg_txt" {
  template = file("bootstrap_templates/init-cfg.txt.template")
  vars = {
    panorama_server1 = var.panorama.primary
    panorama_server2 = var.panorama.secondary
    template_stack   = var.panorama.template_stack_name
    device_group     = var.panorama.device_group_name
    vm_auth_key      = var.panorama.vm_auth_key
    pin_id           = var.panorama.pin_id
    pin_value        = var.panorama.pin_value
  }
}

resource "aws_s3_bucket_object" "initcfg_txt" {
  count   = 2
  bucket  = aws_s3_bucket.bucket[count.index].id
  acl     = "private"
  key     = "config/init-cfg.txt"
  content = data.template_file.initcfg_txt.rendered
}



# /config/bootstrap.xml - vmseries0
data "template_file" "vmseries0_bootstrap_xml" {
  template = file("bootstrap_templates/bootstrap.xml.template")
  vars = {
    hostname           = "vmseries0"
    ha2_ip             = aws_network_interface.ha2[0].private_ip
    ha2_subnet_mask    = cidrnetmask(aws_subnet.ha2[0].cidr_block)
    ha2_aws_router     = cidrhost(aws_subnet.ha2[0].cidr_block, 1)
    public_ip          = "${aws_network_interface.public[0].private_ip}/${split("/", local.vpc_subnets[4])[1]}"
    private_ip         = "${aws_network_interface.private[0].private_ip}/${split("/", local.vpc_subnets[6])[1]}"
    peer_mgmt_ip       = aws_network_interface.management[1].private_ip
    public_aws_router  = cidrhost(aws_subnet.public[0].cidr_block, 1)
    private_aws_router = cidrhost(aws_subnet.private[0].cidr_block, 1)
  }
}

# /config/bootstrap.xml - vmseries1
data "template_file" "vmseries1_bootstrap_xml" {
  template = file("bootstrap_templates/bootstrap.xml.template")
  vars = {
    hostname           = "vmseries1"
    ha2_ip             = aws_network_interface.ha2[1].private_ip
    ha2_subnet_mask    = cidrnetmask(aws_subnet.ha2[1].cidr_block)
    ha2_aws_router     = cidrhost(aws_subnet.ha2[1].cidr_block, 1)
    public_ip          = "${aws_network_interface.public[1].private_ip}/${split("/", local.vpc_subnets[5])[1]}"
    private_ip         = "${aws_network_interface.private[1].private_ip}/${split("/", local.vpc_subnets[7])[1]}"
    peer_mgmt_ip       = aws_network_interface.management[0].private_ip
    public_aws_router  = cidrhost(aws_subnet.public[1].cidr_block, 1)
    private_aws_router = cidrhost(aws_subnet.private[1].cidr_block, 1)
  }
}

# /config/bootstrap.xml
resource "aws_s3_bucket_object" "bootstrap0_xml" {
  bucket  = aws_s3_bucket.bucket[0].id
  acl     = "private"
  key     = "config/bootstrap.xml"
  content = data.template_file.vmseries0_bootstrap_xml.rendered
}

resource "aws_s3_bucket_object" "bootstrap1_xml" {
  bucket  = aws_s3_bucket.bucket[1].id
  acl     = "private"
  key     = "config/bootstrap.xml"
  content = data.template_file.vmseries1_bootstrap_xml.rendered
}

# /software
resource "aws_s3_bucket_object" "software" {
  count   = 2
  bucket  = aws_s3_bucket.bucket[count.index].id
  acl     = "private"
  key     = "software/"
  content = " "
}

# /plugins
resource "aws_s3_bucket_object" "plugins" {
  count   = 2
  bucket  = aws_s3_bucket.bucket[count.index].id
  acl     = "private"
  key     = "plugins/"
  content = " "
}

# /config/vm_series-2.0.3
resource "aws_s3_bucket_object" "plugin_update" {
  count  = 2
  bucket = aws_s3_bucket.bucket[count.index].id
  acl    = "private"
  key    = "plugins/vm_series-2.0.3"
  source = "./bootstrap/plugins/vm_series-2.0.3"
}


# /license
resource "aws_s3_bucket_object" "license" {
  count   = 2
  bucket  = aws_s3_bucket.bucket[count.index].id
  acl     = "private"
  key     = "license/"
  content = " "
}

# /license/autocodes
data "template_file" "authcodes" {
  template = file("bootstrap_templates/authcodes.template")
  vars = {
    authcodes = var.vmseries.authcodes
  }
}

resource "local_file" "authcodes" {
  filename = "${path.module}/tmp/license/authcodes"
  content  = data.template_file.authcodes.rendered
}

resource "aws_s3_bucket_object" "authcodes" {
  count  = 2
  bucket = aws_s3_bucket.bucket[count.index].id
  acl    = "private"
  key    = "license/authcodes"
  source = "./tmp/license/authcodes"

  depends_on = [local_file.authcodes]
}

# /content
resource "aws_s3_bucket_object" "content" {
  count   = 2
  bucket  = aws_s3_bucket.bucket[count.index].id
  acl     = "private"
  key     = "content/"
  content = ""
}

# /content/panupv2-all-contents-8313-6289
//resource "aws_s3_bucket_object" "content_update" {
//  count = 2
//  bucket  = aws_s3_bucket.bucket[count.index].id
//  acl    = "private"
//  key    = "content/panupv2-all-contents-8313-6289"
//  source = "./bootstrap_contents/panupv2-all-contents-8313-6289"
//}





