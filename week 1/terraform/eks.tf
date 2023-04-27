resource "aws_eks_cluster" "eks_cluster" {

  name     = var.eks_cluster_name
  version  = var.eks_cluster_version
  role_arn = aws_iam_role.eks_master_role.arn

  vpc_config {
    subnet_ids = [
      aws_subnet.subnet_eks_cluster_private_1.id,
      aws_subnet.subnet_eks_cluster_private_2.id
    ]
    security_group_ids = [
      aws_security_group.security_group_eks_cluster.id
    ]
    endpoint_private_access = true
    endpoint_public_access  = false
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks_master_role_policy_AmazoneEKSCluster,
    aws_iam_role_policy_attachment.eks_master_role_policy_AmazoneEKSService,
    aws_iam_role_policy_attachment.eks_master_role_policy_AmazonEKSVPCResourceController
  ]

  tags = {
    "Name" = "eks_cluster"
  }
}


resource "aws_iam_role" "eks_master_role" {
  name               = "eks_master_role"
  assume_role_policy = <<POLICY
  {
    "Version": "2012-10-17",
    "Statement": [
      {
        "Action": "sts:AssumeRole",
        "Principal": {
          "Service": "eks.amazonaws.com"
        },
        "Effect": "Allow",
        "Sid": ""
      }
    ]
  }
  POLICY
}

resource "aws_iam_role_policy_attachment" "eks_master_role_policy_AmazoneEKSCluster" {
  role       = aws_iam_role.eks_master_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

resource "aws_iam_role_policy_attachment" "eks_master_role_policy_AmazoneEKSService" {
  role       = aws_iam_role.eks_master_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSServicePolicy"
}

resource "aws_iam_role_policy_attachment" "eks_master_role_policy_AmazonEKSVPCResourceController" {
  role       = aws_iam_role.eks_master_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
}


resource "aws_eks_node_group" "eks_cluster_nodegroup" {

  cluster_name    = aws_eks_cluster.eks_cluster.name
  node_group_name = var.eks_cluster_node_group_name
  node_role_arn   = aws_iam_role.eks_nodegroup_role.arn

  subnet_ids = [
    aws_subnet.subnet_eks_cluster_private_1.id,
    aws_subnet.subnet_eks_cluster_private_2.id
  ]

  instance_types = var.worker_node_instance_type
  disk_size      = 30

  scaling_config {
    desired_size = var.worker_node_desired_size
    max_size     = var.worker_node_max_size
    min_size     = var.worker_node_min_size
  }

  remote_access {
    ec2_ssh_key = var.ec2_key_pair
    source_security_group_ids = [
      aws_security_group.security_group_eks_cluster.id
    ]
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks_nodegroup_role_policy_AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.eks_nodegroup_role_policy_AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.eks_nodegroup_role_policy_AmazonEC2ContainerRegistryReadOnly
  ]

  tags = {
    "Name" = "eks_cluster_node"
  }
}


resource "aws_iam_role" "eks_nodegroup_role" {
  name = "eks_nodegroup_role"
  assume_role_policy = jsonencode({
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
    Version = "2012-10-17"
  })
}

resource "aws_iam_role_policy_attachment" "eks_nodegroup_role_policy_AmazonEKSWorkerNodePolicy" {
  role       = aws_iam_role.eks_nodegroup_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "eks_nodegroup_role_policy_AmazonEKS_CNI_Policy" {
  role       = aws_iam_role.eks_nodegroup_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

resource "aws_iam_role_policy_attachment" "eks_nodegroup_role_policy_AmazonEC2ContainerRegistryReadOnly" {
  role       = aws_iam_role.eks_nodegroup_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}
