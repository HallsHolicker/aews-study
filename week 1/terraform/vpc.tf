resource "aws_vpc" "vpc_eks_cluster" {
  assign_generated_ipv6_cidr_block = false
  cidr_block                       = var.var_vpc_cidr
  enable_dns_hostnames             = true
  enable_dns_support               = true
  tags = {
    "Name" = "vpc_eks_cluster"
  }
}

resource "aws_subnet" "subnet_public_bastion_host" {
  vpc_id            = aws_vpc.vpc_eks_cluster.id
  cidr_block        = var.var_subnet_public_bastion_host_cidr
  availability_zone = var.var_subnet_public_bastion_host_az
  tags = {
    "Name" = "subnet_eks_cluster_public_bastion_host"
  }
}

resource "aws_subnet" "subnet_nat_gateway_public_1" {
  vpc_id                  = aws_vpc.vpc_eks_cluster.id
  cidr_block              = var.var_subnet_public_1_cidr
  availability_zone       = var.var_subnet_public_1_az
  map_public_ip_on_launch = false
  tags = {
    "Name" = "subnet_eks_cluster_public_1"
  }
}

resource "aws_subnet" "subnet_nat_gateway_public_2" {
  vpc_id                  = aws_vpc.vpc_eks_cluster.id
  cidr_block              = var.var_subnet_public_2_cidr
  availability_zone       = var.var_subnet_public_2_az
  map_public_ip_on_launch = false
  tags = {
    "Name" = "subnet_eks_cluster_public_2"
  }
}

resource "aws_subnet" "subnet_eks_cluster_private_1" {
  vpc_id                  = aws_vpc.vpc_eks_cluster.id
  cidr_block              = var.var_subnet_private_1_cidr
  availability_zone       = var.var_subnet_private_1_az
  map_public_ip_on_launch = false
  tags = {
    "Name"                                          = "subnet_eks_cluster_private_1"
    "kubernetes.io/role/internal-elb"               = "1"
    "kubernetes.io/cluster/${var.eks_cluster_name}" = "shared"
  }
}

resource "aws_subnet" "subnet_eks_cluster_private_2" {
  vpc_id                  = aws_vpc.vpc_eks_cluster.id
  cidr_block              = var.var_subnet_private_2_cidr
  availability_zone       = var.var_subnet_private_2_az
  map_public_ip_on_launch = false
  tags = {
    "Name"                                          = "subnet_eks_cluster_private_2"
    "kubernetes.io/role/internal-elb"               = "1"
    "kubernetes.io/cluster/${var.eks_cluster_name}" = "shared"
  }
}

resource "aws_internet_gateway" "internet_gateway_eks_cluster" {
  vpc_id = aws_vpc.vpc_eks_cluster.id
  tags = {
    "Name" = "internet_gateway_eks_cluster"
  }
}

resource "aws_route_table" "route_table_public_bastion_host" {
  vpc_id = aws_vpc.vpc_eks_cluster.id
  tags = {
    "Name" = "route_table_public_bastion_host"
  }
}

resource "aws_route_table" "route_table_eks_cluster_private_1" {
  vpc_id = aws_vpc.vpc_eks_cluster.id
  tags = {
    "Name" = "route_table_eks_cluster_private_1"
  }
}

resource "aws_route_table" "route_table_eks_cluster_private_2" {
  vpc_id = aws_vpc.vpc_eks_cluster.id
  tags = {
    "Name" = "route_table_eks_cluster_private_2"
  }
}

resource "aws_route_table_association" "route_table_association_public_bastion_host" {
  subnet_id      = aws_subnet.subnet_public_bastion_host.id
  route_table_id = aws_route_table.route_table_public_bastion_host.id
}

resource "aws_route_table_association" "route_table_association_nat_gateway_public_1" {
  subnet_id      = aws_subnet.subnet_nat_gateway_public_1.id
  route_table_id = aws_route_table.route_table_public_bastion_host.id
}

resource "aws_route_table_association" "route_table_association_nat_gateway_public_2" {
  subnet_id      = aws_subnet.subnet_nat_gateway_public_2.id
  route_table_id = aws_route_table.route_table_public_bastion_host.id
}

resource "aws_route_table_association" "route_table_association_eks_cluster_private_1" {
  subnet_id      = aws_subnet.subnet_eks_cluster_private_1.id
  route_table_id = aws_route_table.route_table_eks_cluster_private_1.id
}

resource "aws_route_table_association" "route_table_association_eks_cluster_private_2" {
  subnet_id      = aws_subnet.subnet_eks_cluster_private_2.id
  route_table_id = aws_route_table.route_table_eks_cluster_private_2.id
}

resource "aws_route" "route_table_public_bastion_host" {
  route_table_id         = aws_route_table.route_table_public_bastion_host.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.internet_gateway_eks_cluster.id
}

resource "aws_eip" "eip_eks_cluster_private_1" {
  vpc = true
  tags = {
    "Name" = "eip_eks_cluster_private_1"
  }
}

resource "aws_nat_gateway" "nat_gateway_eks_cluster_private_1" {
  allocation_id = aws_eip.eip_eks_cluster_private_1.id
  subnet_id     = aws_subnet.subnet_nat_gateway_public_1.id
  tags = {
    "Name" = "nat_gateway_public_1"
  }
}

resource "aws_route" "route_eks_cluster_private_1" {
  route_table_id         = aws_route_table.route_table_eks_cluster_private_1.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat_gateway_eks_cluster_private_1.id
}

resource "aws_eip" "eip_eks_cluster_private_2" {
  vpc = true
  tags = {
    "Name" = "eip_eks_cluster_private_2"
  }
}

resource "aws_nat_gateway" "nat_gateway_eks_cluster_private_2" {
  allocation_id = aws_eip.eip_eks_cluster_private_2.id
  subnet_id     = aws_subnet.subnet_nat_gateway_public_2.id
  tags = {
    "Name" = "nat_gateway_public_2"
  }
}

resource "aws_route" "route_eks_cluster_private_2" {
  route_table_id         = aws_route_table.route_table_eks_cluster_private_2.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat_gateway_eks_cluster_private_2.id
}

