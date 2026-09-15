# Infrastructure Specification (Terraform Spec)

This document defines the requirements for deploying the `app` application infrastructure using Terraform, following the Spec-Driven Development methodology.

## 1. Purpose
Define and provision the necessary resources within the K3s cluster to run the Go web application, ensuring high availability, basic scalability, and load balancing.

## 2. Deployment Requirements (Kubernetes / K3s)

### 2.1. Terraform Provider
- The official Terraform provider for Kubernetes (`hashicorp/kubernetes`) will be used.
- The K3s cluster access configuration (kubeconfig) will be provided dynamically via variables or the execution environment (GitHub Actions / Local).

### 2.2. State Management (Remote State)
- The infrastructure state (`terraform.tfstate`) **must** be stored remotely using the `kubernetes` backend.
- This state file will be stored securely and encrypted as a `Secret` inside the K3s cluster, allowing seamless synchronization between local and CI/CD environments.
- Under no circumstances should local generation of the `.tfstate` file be allowed or persisted when performing final infrastructure operations.

### 2.3. Workload (Deployment)
- **Container Image:** Will use the resulting image from the application's `Dockerfile` (defined via variable in Terraform).
- **Ports:** The container exposes port `8080`.
- **Environment Variables:** The `PORT` variable will be injected with the value `8080`. (Note: The `HOSTNAME` variable is automatically resolved by Kubernetes).
- **Resource Allocation (Requests/Limits):** For auto-scaling to work, the Deployment must define minimum requirements (e.g., `50m` CPU and `64Mi` RAM).
- **Health Checks (Probes):** The Deployment must include both `liveness_probe` and `readiness_probe` pointing to the `/` HTTP endpoint on port `8080` to ensure zero-downtime rollouts.

### 2.4. Autoscaling (Horizontal Pod Autoscaler)
- **Instances (Pods):**
  - **Minimum:** 2 instances.
  - **Maximum:** 3 instances.
- A `kubernetes_horizontal_pod_autoscaler` (HPA) resource associated with the Deployment will be implemented, scaling the number of pods up or down based on CPU usage (e.g., 70% usage target).

### 2.5. Service Exposure (Service)
- A `kubernetes_service` resource will be created to route network traffic to the application instances.
- **Service Type:** Must be `ClusterIP` to expose the service internally within the cluster, mapping port `80` to internal container port `8080`.

## 3. File Structure
All changes will occur in the `terraform/` directory:
- `main.tf`: Resource declaration (`kubernetes_deployment`, `kubernetes_service`, `kubernetes_horizontal_pod_autoscaler`).
- `variables.tf`: Configurable parameters (like container image, namespace).
- `terraform.tfvars`: Default or mock values for these variables.

## 4. Acceptance Criteria
1. A `terraform apply` must successfully create the 3 resources in the cluster (Deployment, Service, HPA).
2. At least **2 application pods** must be created after applying the configuration.
3. The HPA must clearly show its defined limits (`Min pods: 2`, `Max pods: 3`).
4. When consuming the service multiple times concurrently, the HTTP responses must alternate showing different pod identifiers (`Hello from k3s {podId}`).
