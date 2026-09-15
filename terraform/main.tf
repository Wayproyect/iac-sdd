terraform {
  required_version = ">= 1.0.0"

  backend "kubernetes" {
    secret_suffix = "iac-sdd-app"
    config_path   = "kubeconfig.yaml"
  }

  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.23"
    }
  }
}

provider "kubernetes" {
  config_path = var.kubeconfig_path
}

resource "kubernetes_secret" "registry_auth" {
  count = var.registry_server != "" ? 1 : 0
  metadata {
    name      = "registry-auth"
    namespace = var.namespace
  }

  type = "kubernetes.io/dockerconfigjson"

  data = {
    ".dockerconfigjson" = jsonencode({
      auths = {
        "${var.registry_server}" = {
          auth = base64encode("${var.registry_username}:${var.registry_password}")
        }
      }
    })
  }
}

resource "kubernetes_deployment" "app" {
  metadata {
    name      = "iac-sdd-app-app"
    namespace = var.namespace
    labels = {
      app = "iac-sdd-app"
    }
  }

  spec {
    # We do not define 'replicas' explicitly so that HPA can manage it without conflicts
    selector {
      match_labels = {
        app = "iac-sdd-app"
      }
    }

    template {
      metadata {
        labels = {
          app = "iac-sdd-app"
        }
      }

      spec {
        dynamic "image_pull_secrets" {
          for_each = var.registry_server != "" ? [1] : []
          content {
            name = kubernetes_secret.registry_auth[0].metadata[0].name
          }
        }

        container {
          name  = "app"
          image = var.app_image

          port {
            container_port = 8080
          }

          env {
            name  = "PORT"
            value = "8080"
          }

          # Minimum resources needed for HPA to work (CPU Autoscaling)
          resources {
            limits = {
              cpu    = "100m"
              memory = "128Mi"
            }
            requests = {
              cpu    = "50m"
              memory = "64Mi"
            }
          }

          liveness_probe {
            http_get {
              path = "/"
              port = 8080
            }
            initial_delay_seconds = 3
            period_seconds        = 10
          }

          readiness_probe {
            http_get {
              path = "/"
              port = 8080
            }
            initial_delay_seconds = 3
            period_seconds        = 10
          }
        }
      }
    }
  }

  lifecycle {
    ignore_changes = [
      spec[0].replicas,
    ]
  }
}

resource "kubernetes_service" "app" {
  metadata {
    name      = "iac-sdd-app-svc"
    namespace = var.namespace
  }
  spec {
    selector = {
      app = "iac-sdd-app"
    }
    port {
      port        = 80
      target_port = 8080
    }
    type = "ClusterIP"
  }
}

resource "kubernetes_horizontal_pod_autoscaler" "app" {
  metadata {
    name      = "iac-sdd-app-hpa"
    namespace = var.namespace
  }

  spec {
    max_replicas = 3
    min_replicas = 2

    scale_target_ref {
      api_version = "apps/v1"
      kind        = "Deployment"
      name        = kubernetes_deployment.app.metadata[0].name
    }

    target_cpu_utilization_percentage = 70
  }
}
