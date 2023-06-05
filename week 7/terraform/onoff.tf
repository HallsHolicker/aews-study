variable "ebs_csi_driver" {
  type = bool
  default = "false"
}

variable "ebs_csi_drivce_sc_gp3" {
  type = bool
  default = "false"
}

variable "efs_csi_driver" {
  type = bool
  default = "false"
}

variable "externaldns" {
  type = bool
  default = "false"
}

variable "kube-prometheus-stack" {
  type = bool
  default = "false"
}

variable "kubecost" {
  type = bool
  default = "false"
}

variable "kapenter" {
  type = bool
  default = "false"
}

variable "keda" {
  type = bool
  default = "false"
}

variable "vault" {
  type = bool
  default = "false"
}

variable "ack-s3-controller" {
  type = bool
  default = "false"
}

variable "ack-ec2-controller" {
  type = bool
  default = "false"
}

variable "ack-rds-controller" {
  type = bool
  default = "false"
}

variable "crossplane" {
  type = bool
  default = "false"
}