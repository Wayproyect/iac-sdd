variable "kubeconfig_path" {
  type        = string
  description = "Path to the kubeconfig file for authentication."
  default     = "kubeconfig.yaml"
}

variable "app_image" {
  type        = string
  description = "Docker image of the application"
  default     = "cr.corp.com/iac-sdd-app:latest"
}

variable "namespace" {
  type        = string
  description = "Kubernetes namespace to deploy to"
  default     = "default"
}

variable "registry_server" {
  type        = string
  description = "Container registry URL (e.g. cr.corp.com)"
  default     = ""
}

variable "registry_username" {
  type        = string
  description = "User for the container registry"
  default     = ""
}

variable "registry_password" {
  type        = string
  description = "Password or Token for the container registry"
  default     = ""
  sensitive   = true
}
