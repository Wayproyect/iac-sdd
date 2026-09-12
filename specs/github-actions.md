# CI/CD Specification (GitHub Actions)

This document defines the expected behavior for the continuous integration and continuous deployment (CI/CD) of the application using GitHub Actions, under the Spec-Driven Development approach.

## 1. Purpose
Automate the building of the application's Docker image and its subsequent deployment in K3s via Terraform, ensuring that deployments only occur on versioned code (Tags).

## 2. Execution Requirements (Triggers and Environment)
- **Deployment condition:** The Build and Deploy workflow must **only** run when a **Tag** is pushed to GitHub (e.g., `v1.0.0`).
- **Execution Environment:** Deployments must run in a locally managed environment (e.g., using the `runs-on: self-hosted` label) to allow access to the internal network if necessary.
- **Permissions:** The workflow must explicitly define `packages: write` permissions to allow the default `GITHUB_TOKEN` to push images to the GitHub Container Registry.

## 3. Workflow Phases (Jobs)

### 3.1. Tests (Test)
- **Behavior:** Run `go test -v ./...` inside the `app/` folder.

### 3.2. Image Build (Build & Push)
- **Dynamic Registry Selection & Authentication:** The workflow must determine the target registry dynamically based on the presence of the `REGISTRY_URL` secret.
  - **Custom Registry (if `REGISTRY_URL` exists):** Authenticate using `REGISTRY_USERNAME` and `REGISTRY_PASSWORD`. The image name will be `${REGISTRY_URL}/${APP_NAME}`.
  - **GitHub Container Registry (Fallback default):** If no secret is provided, default to `ghcr.io`. Authenticate using `${{ github.actor }}` and `${{ secrets.GITHUB_TOKEN }}`. The image name will be `ghcr.io/<owner_lowercase>/${APP_NAME}`.
- **Behavior:** Build the image from `app/Dockerfile`.
- **Tagging and Pushing:** Tag the image using the dynamically resolved image name and the triggered `<TAG>` (e.g., `v1.0.0`), and push it to the selected registry.

### 3.3. Deployment (Deploy)
- **Credentials and Variables Injection:**
  - `KUBECONFIG_DATA`: Secret containing the K3s Kubeconfig file in Base64.
  - `APP_NAME`: Workflow environment variable defining the application name (e.g., `iac-sdd-app`).
  - `NAMESPACE`: Workflow environment variable defining in which K3s namespace to deploy (e.g., `lab`).
- **Actions:**
  1. Decode the `KUBECONFIG_DATA` secret and save it in `terraform/kubeconfig.yaml`.
  2. Initialize Terraform (`terraform init`) to load the remote state from the Kubernetes backend.
  3. Execute `terraform apply` injecting the dynamic image URL. 
  4. **Conditional Registry Secrets in Terraform:** If using a custom registry, inject its credentials into Terraform to create the `imagePullSecrets` in K3s. If falling back to GHCR, do **not** inject the temporary `GITHUB_TOKEN` into Terraform (as it expires); instead, rely on the global K3s registry configuration or public repository access.

## 4. Acceptance Criteria
1. Pushing a tag (e.g., `v1.0.0`) triggers the workflow automatically.
2. If `REGISTRY_URL` is omitted, the image is successfully published to GHCR.
3. If `REGISTRY_URL` is provided, the image is published to the custom registry and Terraform is supplied with the matching credentials.
4. Terraform applies the changes dynamically by connecting to the K3s API and updating the Deployment with the newly generated image tag.
