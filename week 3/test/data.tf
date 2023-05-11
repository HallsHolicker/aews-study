data "terraform_remote_state" "eks" {
  backend = "local"

  config = {
    path = "${path.module}/../terraform/terraform.tfstate"
  }
}

data "aws_eks_cluster_auth" "eks_cluster" {
  name = var.eks_cluster_name
}
