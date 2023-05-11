
### AWS Load Balancer Controlleer IAM Policy

resource "aws_iam_policy" "AWSLoadBalancerController_iam_policy" {
  name        = "${var.eks_cluster_name}-AWSLoadBalancerControllerIAMPolicy"
  path        = "/"
  description = "AWS Load Balancer Controller IAM Policy"
  policy      = data.http.AWSLoadBalancerController_iam_policy.response_body
}

resource "aws_iam_role" "AWSLoadBalancerController_iam_role" {
  name = "${var.eks_cluster_name}-AWSLoadBalancerControllerIAMRole"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRoleWithWebIdentity"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Federated = "${module.eks.oidc_provider_arn}"
        }
        Condition = {
          StringEquals = {
            "${module.eks.oidc_provider}:aud" : "sts.amazonaws.com",
            "${module.eks.oidc_provider}:sub" : "system:serviceaccount:kube-system:aws-load-balancer-controller"
          }
        }
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "AWSLoadBalancerController_iam_role_policy_attachment" {
  policy_arn = aws_iam_policy.AWSLoadBalancerController_iam_policy.arn
  role       = aws_iam_role.AWSLoadBalancerController_iam_role.name

}

### Install AWS Load Balancer Controller 

resource "helm_release" "helm_AWSLoadBalancerController" {
  depends_on = [module.eks]
  name       = "aws-load-balancer-controller"

  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"

  namespace = "kube-system"

  set {
    name  = "image.repository"
    value = "602401143452.dkr.ecr.ap-northeast-2.amazonaws.com/amazon/aws-load-balancer-controller"
  }

  set {
    name  = "serviceAccount.create"
    value = "true"
  }

  set {
    name  = "serviceAccount.name"
    value = "aws-load-balancer-controller"
  }

  set {
    name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = aws_iam_role.AWSLoadBalancerController_iam_role.arn
  }

  set {
    name  = "vpcId"
    value = module.vpc.vpc_id
  }

  set {
    name  = "region"
    value = var.aws_region
  }

  set {
    name  = "clusterName"
    value = var.eks_cluster_name
  }
}
