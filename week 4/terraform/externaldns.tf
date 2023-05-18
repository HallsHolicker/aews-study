module "eks-externaldns_iam_role" {
  source = "terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc"

  create_role = var.externaldns

  role_name = "${var.eks_cluster_name}-ExternalDNSIAMRole"

  provider_url = module.eks.oidc_provider
  role_policy_arns = [try(aws_iam_policy.externaldns[0].arn, "")]
  oidc_fully_qualified_subjects = ["system:serviceaccount:kube-system:external-dns"]
}

resource "aws_iam_policy" "externaldns" {
  count = var.externaldns ? 1 : 0

  name_prefix = "${var.eks_cluster_name}-ExternalDNSIAMRole"
  description = "EKS External DNS policy for ${var.eks_cluster_name}"
  policy      = join("", data.aws_iam_policy_document.externaldns.*.json)
}

data "aws_iam_policy_document" "externaldns" {
  count = var.externaldns ? 1 : 0
  statement {
    effect = "Allow"

    actions = [
      "route53:ChangeResourceRecordSets"
    ]

    resources = ["arn:aws:route53:::hostedzone/*"]
  }

  statement {
    effect = "Allow"

    actions = [
      "route53:ListHostedZones",
      "route53:ListResourceRecordSets"
    ]

    resources = ["*"]

  }  
}

locals {
  values_externaldns = <<VALUES
    provider: aws
    txtPrefix: "ext-dns-"
    txtOwnerId: ${var.eks_cluster_name}
    logFormat: json
    policy: sync
    serviceAccount:
      name: external-dns
      annotations:
        eks.amazonaws.com/role-arn: "${module.eks-externaldns_iam_role.iam_role_arn}"
VALUES
}

resource "helm_release" "externaldns" {
  count = var.externaldns ? 1 : 0

  name = "external-dns"
  namespace = "kube-system"
  chart = "external-dns"
  repository = "https://kubernetes-sigs.github.io/external-dns/"
  wait = true

  values = [
    local.values_externaldns
  ]
}

