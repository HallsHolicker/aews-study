output "EC2_BASTION_HOST_IP" {
  value = aws_instance.ec2_bastion_host.public_ip
}

output "EKS_NodeGroup_Name" {
  value = element(split(":", module.eks.eks_managed_node_groups.eks_cluster-nodegroup.node_group_id), 1)
}


output "cluster_endpoint" {
  value = module.eks.cluster_endpoint
}

output "cluster_certificate_authority_data" {
  value = module.eks.cluster_certificate_authority_data
}

# output "efs_filesystem_id" {
#   value = aws_efs_file_system.aws_efs_csi_driver_efs.0.id
# }

# output "test" {
#   value = module.eks
# }