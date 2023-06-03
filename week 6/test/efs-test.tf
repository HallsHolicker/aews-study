resource "kubernetes_persistent_volume" "efs-pv" {
  count = var.efs-test ? 1 : 0
  metadata {
    name = "efs-pv"
  }
  spec {
    capacity = {
      storage = "5Gi"
    }
    access_modes = ["ReadWriteMany"]
    persistent_volume_reclaim_policy = "Retain"
    volume_mode = "Filesystem"
    storage_class_name = "efs-sc"
    persistent_volume_source {
      csi {
        driver = "efs.csi.aws.com"
        volume_handle = data.terraform_remote_state.eks.outputs.efs_filesystem_id
      } 
    }
  }
}

resource "kubernetes_persistent_volume_claim" "efs-claim" {
  count = var.efs-test ? 1 : 0
  metadata {
    name = "efs-claim"
  }
  spec {
    access_modes = ["ReadWriteMany"]
    resources {
      requests = {
        storage = "5Gi"
      }
    }
    storage_class_name = "efs-sc"
  }
}

resource "kubernetes_deployment" "efs-test_app1" {
  count = var.efs-test ? 1 : 0

  metadata {
    name = "app1"
  }

  spec {
    replicas = 1
    selector {
      match_labels = {
        "app.kubernetes.io/name" = "app1"
      }
    }
    template {
      metadata {
        labels = {
          "app.kubernetes.io/name" = "app1"
        }
      }
      spec {
        container {
          image = "busybox"
          name  = "app1"
          command = ["/bin/sh"]
          args = ["-c", "while true; do echo \"$(date -u) app1\" >> /data/out.txt; sleep 5; done"]
          volume_mount {
            name = "persistent-storage"
            mount_path = "/data"
          }
        }
        volume {
          name = "persistent-storage"
          persistent_volume_claim {
            claim_name = "efs-claim"
          }
        }
      }
    }
  }
}

resource "kubernetes_deployment" "efs-test_app2" {
  count = var.efs-test ? 1 : 0

  metadata {
    name = "app2"
  }

  spec {
    replicas = 1
    selector {
      match_labels = {
        "app.kubernetes.io/name" = "app2"
      }
    }
    template {
      metadata {
        labels = {
          "app.kubernetes.io/name" = "app2"
        }
      }
      spec {
        container {
          image = "busybox"
          name  = "app2"
          command = ["/bin/sh"]
          args = ["-c", "while true; do echo \"$(date -u) app2\" >> /data/out.txt; sleep 5; done"]
          volume_mount {
            name = "persistent-storage"
            mount_path = "/data"
          }
        }
        volume {
          name = "persistent-storage"
          persistent_volume_claim {
            claim_name = "efs-claim"
          }
        }
      }
    }
  }
}