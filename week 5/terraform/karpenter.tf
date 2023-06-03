module "karpenter_iam_role" {
  source = "terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc"

  create_role = var.kapenter

  role_name = "${var.eks_cluster_name}-AWSKerpenterControllerIAMRole"

  provider_url = module.eks.oidc_provider
  role_policy_arns = [try(aws_iam_policy.karpenter_controller[0].arn, "")]
  oidc_fully_qualified_subjects = ["system:serviceaccount:karpenter:karpenter"]
}

resource "aws_iam_policy" "karpenter_controller" {
  count = var.kapenter ? 1 : 0

  name_prefix = "${var.eks_cluster_name}-AWSKarpenterControllerIAMRole"
  description = "EKS Karpenter controller policy for ${var.eks_cluster_name}"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "ec2:CreateLaunchTemplate",
          "ec2:CreateFleet",
          "ec2:RunInstances",
          "ec2:CreateTags",
          "iam:PassRole",
          "ec2:TerminateInstances",
          "ec2:DescribeLaunchTemplates",
          "ec2:DescribeInstances",
          "ec2:DescribeSecurityGroups",
          "ec2:DescribeSubnets",
          "ec2:DescribeInstanceTypes",
          "ec2:DescribeInstanceTypeOfferings",
          "ec2:DescribeAvailabilityZones",
          "ssm:GetParameter"
        ]
        Effect   = "Allow"
        Resource = "*"
      },
    ]
  })
}

data "aws_iam_policy" "ssm_managed_instance" {
  arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}
resource "aws_iam_role_policy_attachment" "karpenter_ssm_policy" {
  count = var.kapenter ? 1 : 0
  role       = module.eks.eks_managed_node_groups.eks_cluster-nodegroup.iam_role_name
  policy_arn = data.aws_iam_policy.ssm_managed_instance.arn
}
resource "aws_iam_instance_profile" "karpenter" {
  count = var.kapenter ? 1 : 0
  name = "KarpenterNodeInstanceProfile-${var.eks_cluster_name}"
  role = module.eks.eks_managed_node_groups.eks_cluster-nodegroup.iam_role_name
}

resource "helm_release" "karpenter" {
  count = var.kapenter ? 1 : 0
  depends_on       = [module.eks.kubeconfig]
  namespace        = "karpenter"
  create_namespace = true
  name       = "karpenter"
  repository = "https://charts.karpenter.sh"
  chart      = "karpenter"
  version    = "v0.27.5"
  set {
    name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = module.karpenter_iam_role.iam_role_arn
  }
  set {
    name  = "controller.clusterName"
    value = var.eks_cluster_name
  }
  set {
    name  = "controller.clusterEndpoint"
    value = module.eks.cluster_endpoint
  }
  set {
    name  = "aws.defaultInstanceProfile"
    value = aws_iam_instance_profile.karpenter[0].name
  }
}