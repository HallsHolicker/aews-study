resource "kubernetes_persistent_volume_claim" "ebs-claim" {
  count = var.ebs-test ? 1 : 0
  metadata {
    name = "ebs-claim"
  }
  spec {
    access_modes = ["ReadWriteOnce"]
    resources {
      requests = {
        storage = "4Gi"
      }
    }
    storage_class_name = "gp3"
  }
}

resource "kubernetes_deployment" "ebs-test" {
  count = var.ebs-test ? 1 : 0

  metadata {
    name = "app"
  }

  spec {
    replicas = 1
    selector {
      match_labels = {
        "app.kubernetes.io/name" = "app"
      }
    }
    template {
      metadata {
        labels = {
          "app.kubernetes.io/name" = "app"
        }
      }
      spec {
        container {
          image = "centos"
          name  = "app"
          command = ["/bin/sh"]
          args = ["-c", "while true; do echo $(date -u) >> /data/out.txt; sleep 5; done"]
          volume_mount {
            name = "persistent-storage"
            mount_path = "/data"
          }
        }
        volume {
          name = "persistent-storage"
          persistent_volume_claim {
            claim_name = "ebs-claim"
          }
        }
      }
    }
  }
}