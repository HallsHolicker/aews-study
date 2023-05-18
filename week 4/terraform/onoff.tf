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
