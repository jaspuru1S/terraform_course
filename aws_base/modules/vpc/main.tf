# Create VPC resource
resource "aws_vpc" "default" {
  cidr_block = var.vpc_cidr

  tags = merge(
    local.module_tags,
    {
      "Name" = local.vpc_name
    },
  )
}

# Add public subnets
resource "aws_subnet" "public_default" {
  count             = length(local.public_subnets)
  vpc_id            = aws_vpc.default.id
  cidr_block        = element(values(local.public_subnets), count.index)
  availability_zone = element(keys(local.public_subnets), count.index)

  tags = merge(
    local.module_tags,
    var.inherited_public_subnet_tags,
    {
      "Name"       = "${local.expanded_name} Public Subnet ${count.index}",
      "SubnetType" = "public"
    },
  )
}

# Add default public route table
resource "aws_route_table" "public_default" {
  vpc_id = aws_vpc.default.id

  tags = merge(
    local.module_tags,
    {
      "Name"   = "${local.expanded_name} Public Subnet Route",
      "Public" = true
    },
  )
}

# Associate route table with public subnets
resource "aws_route_table_association" "public_default" {
  count          = length(local.public_subnets)
  subnet_id      = element(aws_subnet.public_default[*].id, count.index)
  route_table_id = aws_route_table.public_default.id
}

# Add internet gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.default.id

  tags = merge(
    local.module_tags,
    {
      "Name" = "${local.expanded_name} IGW"
    },
  )
}

# Add a public gateway to public route table
resource "aws_route" "public_gateway_route" {
  route_table_id         = aws_route_table.public_default.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id
  depends_on = [
    aws_route_table.public_default
  ]
}

# Add public network ACL
resource "aws_network_acl" "public_default_nacl" {
  vpc_id     = aws_vpc.default.id
  subnet_ids = aws_subnet.public_default[*].id

  egress {
    protocol   = "-1"
    rule_no    = 200
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }

  ingress {
    protocol   = "-1"
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }

  tags = merge(
    local.module_tags,
    {
      "Name" = "${local.expanded_name} public network ACL"
    },
  )
}

# Add Elastic IP resource for NAT gateway
resource "aws_eip" "nat_eip" {
  count = length(local.public_subnets)
  vpc   = true

  tags = merge(
    local.module_tags,
    {
      "Name" = "${local.expanded_name} Public ${count.index}"
    },
  )
}

# Add NAT gateway in public subnets for private subnets egress. 
resource "aws_nat_gateway" "nat_gw" {
  count         = length(local.public_subnets)
  allocation_id = element(aws_eip.nat_eip[*].id, count.index)
  subnet_id     = element(aws_subnet.public_default[*].id, count.index)
  depends_on = [
    aws_internet_gateway.igw
  ]

  tags = merge(
    local.module_tags,
    {
      "Name" = "${local.expanded_name} Public ${count.index}"
    },
  )
}

# Add private subnets
resource "aws_subnet" "private_default" {
  count             = length(local.private_subnets)
  vpc_id            = aws_vpc.default.id
  cidr_block        = element(values(local.private_subnets), count.index)
  availability_zone = element(keys(local.private_subnets), count.index)

  tags = merge(
    local.module_tags,
    var.inherited_private_subnet_tags,
    {
      "Name"       = "${local.expanded_name} Private Subnet ${count.index}",
      "SubnetType" = "private"
    },
  )
}

# Add default private route table
resource "aws_route_table" "private_default" {
  count  = length(local.private_subnets)
  vpc_id = aws_vpc.default.id

  tags = merge(
    local.module_tags,
    {
      "Name"    = "${local.expanded_name} Private Subnet Route ${count.index}",
      "Private" = true
    },
  )
}

# Associate route table with private subnets
resource "aws_route_table_association" "private_default" {
  count          = length(local.private_subnets)
  subnet_id      = element(aws_subnet.private_default[*].id, count.index)
  route_table_id = aws_route_table.private_default[count.index].id
}

# Add a NAT gateway to private route table
resource "aws_route" "private_nat_gateway_route" {
  count                  = length(local.private_subnets)
  route_table_id         = element(aws_route_table.private_default[*].id, count.index)
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = element(aws_nat_gateway.nat_gw[*].id, count.index)
  depends_on = [
    aws_route_table.private_default
  ]
}

# Add private network acl
resource "aws_network_acl" "private_default_nacl" {
  vpc_id     = aws_vpc.default.id
  subnet_ids = aws_subnet.private_default[*].id

  egress {
    protocol   = "-1"
    rule_no    = 200
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }

  ingress {
    protocol   = "-1"
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }

  tags = merge(
    local.module_tags,
    {
      "Name" = "${local.expanded_name} private network ACL"
    },
  )
}