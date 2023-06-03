module "ebs_csi_driver_controller_iam_role" {
  source = "terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc"

  create_role = var.ebs_csi_driver

  role_name = "${var.eks_cluster_name}-AWSEbsCsiControllerIAMRole"

  provider_url = module.eks.oidc_provider
  role_policy_arns = [try(aws_iam_policy.ebs_csi_driver_controller[0].arn, "")]
  oidc_fully_qualified_subjects = ["system:serviceaccount:kube-system:ebs-csi-driver"]
}

resource "aws_iam_policy" "ebs_csi_driver_controller" {
  count = var.ebs_csi_driver ? 1 : 0

  name_prefix = "${var.eks_cluster_name}-AWSEbsCsiControllerIAMRole"
  description = "EKS EBS CSI driver controller policy for ${var.eks_cluster_name}"
  policy      = join("", data.aws_iam_policy_document.ebs_csi_driver_controller.*.json)
}

data "aws_iam_policy_document" "ebs_csi_driver_controller" {
  count = var.ebs_csi_driver ? 1 : 0

  statement {
    effect = "Allow"
    actions = [
      "ec2:CreateSnapshot",
      "ec2:AttachVolume",
      "ec2:DetachVolume",
      "ec2:ModifyVolume",
      "ec2:DescribeAvailabilityZones",
      "ec2:DescribeInstances",
      "ec2:DescribeSnapshots",
      "ec2:DescribeTags",
      "ec2:DescribeVolumes",
      "ec2:DescribeVolumesModifications",
    ]
    resources = ["*"]
  }

  statement {
    effect  = "Allow"
    actions = ["ec2:CreateTags"]
    resources = [
      "arn:aws:ec2:*:*:volume/*",
      "arn:aws:ec2:*:*:snapshot/*"
    ]
    condition {
      test     = "StringEquals"
      variable = "ec2:CreateAction"
      values = [
        "CreateVolume",
        "CreateSnapshot"
      ]
    }
  }

  statement {
    effect  = "Allow"
    actions = ["ec2:DeleteTags"]
    resources = [
      "arn:aws:ec2:*:*:volume/*",
      "arn:aws:ec2:*:*:snapshot/*"
    ]
  }

  statement {
    effect    = "Allow"
    actions   = ["ec2:CreateVolume"]
    resources = ["*"]
    condition {
      test     = "StringLike"
      variable = "aws:RequestTag/ebs.csi.aws.com/cluster"
      values   = ["true"]
    }
  }

  statement {
    effect    = "Allow"
    actions   = ["ec2:CreateVolume"]
    resources = ["*"]
    condition {
      test     = "StringLike"
      variable = "aws:RequestTag/CSIVolumeName"
      values   = ["*"]
    }
  }

  statement {
    effect    = "Allow"
    actions   = ["ec2:DeleteVolume"]
    resources = ["*"]
    condition {
      test     = "StringLike"
      variable = "ec2:ResourceTag/CSIVolumeName"
      values   = ["*"]
    }
  }

  statement {
    effect    = "Allow"
    actions   = ["ec2:DeleteVolume"]
    resources = ["*"]
    condition {
      test     = "StringLike"
      variable = "ec2:ResourceTag/ebs.csi.aws.com/cluster"
      values   = ["true"]
    }
  }

  statement {
    effect    = "Allow"
    actions   = ["ec2:DeleteSnapshot"]
    resources = ["*"]
    condition {
      test     = "StringLike"
      variable = "ec2:ResourceTag/CSIVolumeSnapshotName"
      values   = ["*"]
    }
  }

  statement {
    effect    = "Allow"
    actions   = ["ec2:DeleteSnapshot"]
    resources = ["*"]
    condition {
      test     = "StringLike"
      variable = "ec2:ResourceTag/ebs.csi.aws.com/cluster"
      values   = ["true"]
    }
  }
}


locals {
  values_aws-ebs-csi-driver = <<VALUES
    controller:
      extraCreateMetadata: true
      serviceAccount:
        name: "ebs-csi-driver"
        annotations:
          eks.amazonaws.com/role-arn: ${module.ebs_csi_driver_controller_iam_role.iam_role_arn}
VALUES
}

resource "helm_release" "ebs_csi_driver" {
  count = var.ebs_csi_driver ? 1 : 0

  name = "ebs-csi-driver"
  namespace = "kube-system"
  chart = "aws-ebs-csi-driver"
  repository = "https://kubernetes-sigs.github.io/aws-ebs-csi-driver"

  values = [
    local.values_aws-ebs-csi-driver
  ]
}

resource "kubernetes_storage_class" "aws-ebs-csi-driver-sc-gp3" {
  count = var.ebs_csi_drivce_sc_gp3 ? 1 : 0
  metadata {
    name = "gp3"
  }
  storage_provisioner = "ebs.csi.aws.com"
  volume_binding_mode = "WaitForFirstConsumer"
  allow_volume_expansion = true

  parameters = merge(
    {
      type = "gp3"
      allowAutoIOPSPerGBIncrease = "true"
      encrypted = "true"
    }
  )
}