module "efs_csi_driver_controller_iam_role" {
  source = "terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc"

  create_role = var.efs_csi_driver

  role_name = "${var.eks_cluster_name}-AWSEFsCsiControllerIAMRole"

  provider_url = module.eks.oidc_provider
  role_policy_arns = [try(aws_iam_policy.efs_csi_driver_controller[0].arn, "")]
  oidc_fully_qualified_subjects = ["system:serviceaccount:kube-system:efs-csi-driver"]
}

resource "aws_iam_policy" "efs_csi_driver_controller" {
  count = var.efs_csi_driver ? 1 : 0

  name_prefix = "${var.eks_cluster_name}-AWSEbsCsiControllerIAMRole"
  description = "EKS EFS CSI driver controller policy for ${var.eks_cluster_name}"
  policy      = join("", data.aws_iam_policy_document.efs_csi_driver_controller.*.json)
}

data "aws_iam_policy_document" "efs_csi_driver_controller" {
  count = var.efs_csi_driver ? 1 : 0

  statement {
    effect = "Allow"
    actions = [
      "elasticfilesystem:DescribeAccessPoints",
      "elasticfilesystem:DescribeFileSystems"
    ]
    resources = ["*"]
  }

  statement {
    effect = "Allow"
    actions = [
      "elasticfilesystem:CreateAcessPoint"
    ]
    resources = ["*"]
    condition {
      test     = "StringLike"
      variable = "aws:RequestTag/efs.csi.aws.com/cluster"
      values   = ["true"]
    }
  }
  statement {
    effect = "Allow"
    actions = [
      "elasticfilesystem:DeleteAccessPoint"
    ]
    resources = ["*"]
    condition {
      test     = "StringLike"
      variable = "aws:ResourceTag/efs.csi.aws.com/cluster"
      values   = ["true"]
    }
  }
}


resource "aws_efs_file_system" "aws_efs_csi_driver_efs" {
  count = var.efs_csi_driver ? 1 : 0

  creation_token = "${var.eks_cluster_name}-efs-csi-driver"
  encrypted = "true"
  performance_mode = "generalPurpose"
  provisioned_throughput_in_mibps = 0
  throughput_mode = "bursting"
}

resource "aws_efs_mount_target" "aws_efs_csi_driver_efs_mount_target" {
  count = var.efs_csi_driver ? length(module.vpc.private_subnets) : 0
  file_system_id = aws_efs_file_system.aws_efs_csi_driver_efs.0.id
  subnet_id = element(module.vpc.private_subnets, count.index)
  security_groups = [module.security-group-efs-csi-driver.0.security_group_id]
}

module "security-group-efs-csi-driver" {
  count = var.efs_csi_driver ? 1 : 0
  source = "terraform-aws-modules/security-group/aws//modules/nfs"
  name = "${var.eks_cluster_name}-efs-csi-driver-sg"
  vpc_id = module.vpc.vpc_id
  ingress_cidr_blocks = ["0.0.0.0/0"]
}

locals {
  values_aws-efs-csi-driver = <<VALUES
    controller:
      extraCreateMetadata: true
      serviceAccount:
        annotations:
          eks.amazonaws.com/role-arn: ${module.efs_csi_driver_controller_iam_role.iam_role_arn}
VALUES
}

resource "helm_release" "efs_csi_driver" {
  count = var.efs_csi_driver ? 1 : 0

  name = "efs-csi-driver"
  namespace = "kube-system"
  chart = "aws-efs-csi-driver"
  repository = "https://kubernetes-sigs.github.io/aws-efs-csi-driver"

  values = [
    local.values_aws-efs-csi-driver
  ]
}

resource "kubernetes_storage_class" "aws-efs-csi-driver-storage-class" {
  count = var.efs_csi_driver ? 1 : 0

  metadata {
    name = "efs-sc"
  }
  storage_provisioner = "efs.csi.aws.com"
}