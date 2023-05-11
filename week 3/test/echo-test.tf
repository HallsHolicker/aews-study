resource "kubernetes_deployment" "echo" {
  count = var.echo-server ? 1 : 0
  metadata {
    name = "echo"
  }

  spec {
    replicas = 1
    selector {
      match_labels = {
        "app.kubernetes.io/name" = "echo"
      }
    }
    template {
      metadata {
        labels = {
          "app.kubernetes.io/name" = "echo"
        }
      }
      spec {
        container {
          image = "k8s.gcr.io/echoserver:1.10"
          name  = "echo"
        }
      }
    }
  }
}

resource "kubernetes_service" "echo" {
  count = var.echo-server ? 1 : 0
  metadata {
    name = "echo"
  }
  spec {
    selector = {
      "app.kubernetes.io/name" = "echo"
    }
    port {
      port        = 8080
      target_port = 8080
    }
    type = "NodePort"
  }
}

resource "kubernetes_ingress_v1" "alb" {
  metadata {
    name = "alb"
    annotations = {
      "alb.ingress.kubernetes.io/scheme"      = "internet-facing",
      "alb.ingress.kubernetes.io/target-type" = "ip",
    }
  }
  spec {
    ingress_class_name = "alb"
    rule {
      http {
        path {
          backend {
            service {
              name = "echo"
              port {
                number = 8080
              }
            }
          }
          path = "/*"
        }
      }
    }
  }
}
