output "EC2_BASTION_HOST_IP" {
  value = aws_instance.ec2_bastion_host.public_ip
}
