module "eks-ack-crossplane_iam_role" {
  source = "terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc"

  create_role = var.crossplane

  role_name = "${var.eks_cluster_name}-AckS3ControllerIAMRole"

  provider_url = module.eks.oidc_provider
  role_policy_arns = ["arn:aws:iam::aws:policy/AmazonS3FullAccess", "arn:aws:iam::aws:policy/AmazonEC2FullAccess", "arn:aws:iam::aws:policy/AmazonRDSFullAccess"]
  oidc_fully_qualified_subjects = ["system:serviceaccount:crossplane-system:crossplane"]
}

resource "helm_release" "crossplane" {
  count = var.crossplane ? 1 : 0

  name = "ack-s3-controller"
  namespace = "crossplane-system"
  create_namespace = true
  chart = "crossplane"
  repository = "https://charts.crossplane.io/stable"
  wait = true
  version = "1.3.1"

  set {
    name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = "${module.eks-ack-s3-controller_iam_role.iam_role_arn}"
  }
}
