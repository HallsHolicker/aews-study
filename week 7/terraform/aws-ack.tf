module "eks-ack-s3-controller_iam_role" {
  source = "terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc"

  create_role = var.ack-s3-controller

  role_name = "${var.eks_cluster_name}-AckS3ControllerIAMRole"

  provider_url = module.eks.oidc_provider
  role_policy_arns = ["arn:aws:iam::aws:policy/AmazonS3FullAccess"]
  oidc_fully_qualified_subjects = ["system:serviceaccount:ack-system:ack-s3-controller"]
}

resource "helm_release" "ack-s3-controller" {
  count = var.ack-s3-controller ? 1 : 0

  name = "ack-s3-controller"
  namespace = "ack-system"
  create_namespace = true
  chart = "s3-chart"
  repository = "oci://public.ecr.aws/aws-controllers-k8s/"
  wait = true

  set {
    name  = "aws.region"
    value = var.aws_region
  }

  set {
    name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = "${module.eks-ack-s3-controller_iam_role.iam_role_arn}"
  }
}


module "eks-ack-ec2-controller_iam_role" {
  source = "terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc"

  create_role = var.ack-ec2-controller

  role_name = "${var.eks_cluster_name}-AckEC2ControllerIAMRole"

  provider_url = module.eks.oidc_provider
  role_policy_arns = ["arn:aws:iam::aws:policy/AmazonEC2FullAccess"]
  oidc_fully_qualified_subjects = ["system:serviceaccount:ack-system:ack-ec2-controller"]
}

resource "helm_release" "ack-ec2-controller" {
  count = var.ack-ec2-controller ? 1 : 0

  name = "ack-ec2-controller"
  namespace = "ack-system"
  create_namespace = true
  chart = "ec2-chart"
  repository = "oci://public.ecr.aws/aws-controllers-k8s/"
  wait = true

  set {
    name  = "aws.region"
    value = var.aws_region
  }

  set {
    name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = "${module.eks-ack-ec2-controller_iam_role.iam_role_arn}"
  }
}

module "eks-ack-rds2-controller_iam_role" {
  source = "terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc"

  create_role = var.ack-rds-controller

  role_name = "${var.eks_cluster_name}-AckRdsControllerIAMRole"

  provider_url = module.eks.oidc_provider
  role_policy_arns = ["arn:aws:iam::aws:policy/AmazonRDSFullAccess"]
  oidc_fully_qualified_subjects = ["system:serviceaccount:ack-system:ack-rds-controller"]
}

resource "helm_release" "ack-rds-controller" {
  count = var.ack-rds-controller ? 1 : 0

  name = "ack-rds-controller"
  namespace = "ack-system"
  create_namespace = true
  chart = "rds-chart"
  repository = "oci://public.ecr.aws/aws-controllers-k8s/"
  wait = true

  set {
    name  = "aws.region"
    value = var.aws_region
  }

  set {
    name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = "${module.eks-ack-ec2-controller_iam_role.iam_role_arn}"
  }
}