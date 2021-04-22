variable "license_type_map" {
  type = map(string)

  default = {
    "byol"    = "6njl1pau431dv1qxipg63mvah"
    "bundle1" = "e9yfvyj3uag5uo5j2hjikv74n"
    "bundle2" = "hd44w1chf26uv4p52cdynb2o"
  }
}

resource "aws_ebs_encryption_by_default" "security" {
  enabled = true
}

resource "aws_security_group" "management" {
  name        = "vmseries_management"
  description = "Allow management of the VM-Series NGFWs"
  vpc_id      = aws_vpc.vpc.id

  # Egress All
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  # Ingress TCP/22
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [local.my_ip]
  }

  # Ingress TCP/443
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [local.my_ip]
  }

  # Ingress ICMP
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "icmp"
    cidr_blocks = [local.my_ip]
  }

  ingress {
    from_port   = 0
    protocol    = "-1"
    to_port     = 0
    cidr_blocks = aws_subnet.management[*].cidr_block
  }
}

resource "aws_security_group" "data" {
  name        = "vmseries_data"
  description = "Allow all traffic for data ports of the VM-Series NGFWs"
  vpc_id      = aws_vpc.vpc.id

  # Egress All
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  # Ingress All
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


data "aws_ami" "panw_ngfw" {
  most_recent = true
  owners      = ["aws-marketplace"]

  filter {
    name   = "owner-alias"
    values = ["aws-marketplace"]
  }

  filter {
    name   = "product-code"
    values = [var.license_type_map[var.vmseries.license_type]]
  }

  filter {
    name   = "name"
    values = ["PA-VM-AWS-${var.vmseries.version}*"]
  }
}

data "aws_region" "current" {
  name = var.aws_region
}

resource "aws_network_interface" "management" {
  count     = 2
  subnet_id = aws_subnet.management[count.index].id
  #   private_ips       = [""]
  security_groups   = [aws_security_group.management.id]
  source_dest_check = true

  tags = {
    Name = "vmseries${count.index}_management"
  }
}

resource "aws_network_interface" "private" {
  count     = 2
  subnet_id = aws_subnet.private[count.index].id
  #   private_ips       = [""]
  security_groups   = [aws_security_group.data.id]
  source_dest_check = false

  tags = {
    Name = "vmseries${count.index}_private"
  }
}

resource "aws_network_interface" "ha2" {
  count     = 2
  subnet_id = aws_subnet.ha2[count.index].id
  #   private_ips       = [""]
  security_groups   = [aws_security_group.data.id]
  source_dest_check = true

  tags = {
    Name = "vmseries${count.index}_ha2"
  }
}

resource "aws_eip" "management" {
  count = 2

  vpc               = true
  network_interface = aws_network_interface.management[count.index].id

  tags = {
    Name = "vmseries${count.index}_management"
  }

  depends_on = [aws_internet_gateway.igw]
}

resource "aws_network_interface" "public" {
  count = 2

  subnet_id = aws_subnet.public[count.index].id
  #   private_ips       = [""]
  security_groups   = [aws_security_group.data.id]
  source_dest_check = false

  tags = {
    Name = "vmseries${count.index}_public"
  }
}

resource "aws_eip" "public" {
  count = 1

  vpc               = true
  network_interface = aws_network_interface.public[count.index].id

  tags = {
    Name = "vmseries${count.index}_public"
  }
}



resource "aws_instance" "ngfw" {
  count = 2

  disable_api_termination              = false
  instance_initiated_shutdown_behavior = "stop"
  iam_instance_profile                 = aws_iam_instance_profile.bootstrap_profile.name
  user_data                            = base64encode(join("", ["vmseries-bootstrap-aws-s3bucket=", aws_s3_bucket.bucket[count.index].bucket]))
  monitoring                           = true

  ebs_optimized = true
  ami           = data.aws_ami.panw_ngfw.image_id
  instance_type = var.vmseries.instance_type
  key_name      = var.vmseries.aws_key
  root_block_device {
    delete_on_termination = true
  }

  metadata_options {
    http_endpoint = "enabled"
    # Optional is required for VM-Series to work.
    http_tokens = "optional"
  }

  network_interface {
    device_index         = 0
    network_interface_id = aws_network_interface.management[count.index].id
  }

  network_interface {
    device_index         = 1
    network_interface_id = aws_network_interface.ha2[count.index].id
  }

  network_interface {
    device_index         = 2
    network_interface_id = aws_network_interface.public[count.index].id
  }

  network_interface {
    device_index         = 3
    network_interface_id = aws_network_interface.private[count.index].id
  }

  tags = {
    Name = "vmseries${count.index}"
  }

  depends_on = [aws_eip.management, aws_route_table.public, aws_route_table_association.management, aws_route.default_to_igw]
}
