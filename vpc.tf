# Calculate Subnets

locals {
  vpc_subnets = cidrsubnets(var.vpc_cidr, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4)
}

# VPC

resource "aws_vpc" "vpc" {
  cidr_block = var.vpc_cidr
  tags = {
    Name = "crosszone-ha-deployment"
  }
}

# Get Available Zones (Use 0 and 1)
data "aws_availability_zones" "available" {
  state = "available"
}

# Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id
}

# Route Tables
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.vpc.id
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.vpc.id
}

resource "aws_route" "default_to_igw" {
  route_table_id = aws_route_table.public.id

  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id
}

# Subnets - Management

resource "aws_subnet" "management" {
  count             = 2
  cidr_block        = local.vpc_subnets[0 + count.index]
  vpc_id            = aws_vpc.vpc.id
  availability_zone = data.aws_availability_zones.available.names[count.index]
  tags = {
    Name = "vmseries-management-az${count.index}-${random_string.unique_id.result}"
  }
}

resource "aws_route_table_association" "management" {
  count          = 2
  route_table_id = aws_route_table.public.id
  subnet_id      = aws_subnet.management[count.index].id
}

# Subnet - HA2

resource "aws_subnet" "ha2" {
  count             = 2
  cidr_block        = local.vpc_subnets[2 + count.index]
  vpc_id            = aws_vpc.vpc.id
  availability_zone = data.aws_availability_zones.available.names[count.index]
  tags = {
    Name = "vmseries-ha2-az${count.index}-${random_string.unique_id.result}"
  }
}

resource "aws_subnet" "private" {
  count             = 2
  cidr_block        = local.vpc_subnets[4 + count.index]
  vpc_id            = aws_vpc.vpc.id
  availability_zone = data.aws_availability_zones.available.names[count.index]
  tags = {
    Name = "vmseries-private-az${count.index}-${random_string.unique_id.result}"
  }

}

resource "aws_route_table_association" "private" {
  count          = 2
  route_table_id = aws_route_table.private.id
  subnet_id      = aws_subnet.private[count.index].id
}

resource "aws_subnet" "public" {
  count             = 2
  cidr_block        = local.vpc_subnets[6 + count.index]
  vpc_id            = aws_vpc.vpc.id
  availability_zone = data.aws_availability_zones.available.names[count.index]
  tags = {
    Name = "vmseries-public-az${count.index}-${random_string.unique_id.result}"
  }

}

resource "aws_route_table_association" "public" {
  count          = 2
  route_table_id = aws_route_table.public.id
  subnet_id      = aws_subnet.public[count.index].id
}

resource "aws_subnet" "tgw" {
  count             = 2
  cidr_block        = local.vpc_subnets[8 + count.index]
  vpc_id            = aws_vpc.vpc.id
  availability_zone = data.aws_availability_zones.available.names[count.index]
  tags = {
    Name = "vmseries-tgw-az${count.index}-${random_string.unique_id.result}"
  }
}

resource "aws_route_table" "tgw" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = "tgw-${random_string.unique_id.result}"
  }
}

resource "aws_route" "tgw_default_route" {
  destination_cidr_block = "0.0.0.0/0"
  network_interface_id   = aws_network_interface.private[0].id
  route_table_id         = aws_route_table.tgw.id
}