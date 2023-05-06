module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "vpc-eks-study"
  cidr = var.var_vpc_cidr

  azs = [
    "${var.var_subnet_1_az}",
    "${var.var_subnet_2_az}"
  ]
  private_subnets = [
    "${var.var_subnet_private_1_cidr}",
    "${var.var_subnet_private_2_cidr}"
  ]

  public_subnets = [
    "${var.var_subnet_public_1_cidr}",
    "${var.var_subnet_public_2_cidr}"
  ]

  enable_dns_hostnames = true

  enable_nat_gateway = true
  single_nat_gateway = false

  public_subnet_tags = {
    "kubernetes.io/cluster/${var.eks_cluster_name}" = "shared"
    "kubernetes.io/role/elb"                        = "1"
  }

  private_subnet_tags = {
    "kubernetes.io/cluster/${var.eks_cluster_name}" = "shared"
    "kubernetes.io/role/internal-elb"               = "1"
  }
}


resource "aws_security_group" "security_group_eks_cluster" {
  name        = "security_group_eks_cluster"
  description = "security_group_eks_cluster"
  vpc_id      = module.vpc.vpc_id
  tags = {
    "Name" = "security_group_eks_cluster"
  }
}

resource "aws_security_group_rule" "security_group_rule_eks_cluster_ingress" {
  type              = "ingress"
  from_port         = 0
  to_port           = 65535
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.security_group_eks_cluster.id
}

resource "aws_security_group_rule" "security_group_rule_eks_cluster_egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 65535
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.security_group_eks_cluster.id
}
