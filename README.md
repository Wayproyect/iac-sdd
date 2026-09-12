# Infrastructure as Code using Spec-Driven Development

[![Build Status](https://github.com/wayproyect/iac-sdd/actions/workflows/deploy.yml/badge.svg)](https://github.com/wayproyect/iac-sdd/actions)

Go web application that prints "Hello from k3s {podId}", deployed using Terraform on K3s.

## Project Structure

- `app/`: Contains the Go application source code and its `Dockerfile`.
- `terraform/`: Terraform scripts to configure the infrastructure.
- `specs/`: Contains the formal specification documents for the components.
- `docs/`: Additional operational manuals (e.g., registry setup).
- `.github/workflows/`: GitHub Actions CI/CD workflows for K3s.

## Prerequisites

- Go 1.26+ (for local development)
- Docker
- Terraform
- A K3s cluster with its API accessible (e.g., exposed via a host like `k3s.corp.com`, a VPN, or a secure tunnel)

## Local Development & Testing

### Running Locally
To test the Go application locally without Docker or Kubernetes:
```bash
cd app
PORT=8080 go run main.go
```
The application will be available at `http://localhost:8080`.
*Note: The application reads `PORT` and `HOSTNAME` environment variables. If `HOSTNAME` is not provided, it defaults to `unknown-pod` (see [specs/app.md](specs/app.md)).*

### Running Tests
Following the **Spec-Driven Development** methodology, ensure all tests pass before committing:
```bash
cd app
go test -v ./...
```

## Deployment with Terraform and K3s

The infrastructure is defined as code using Terraform (see `terraform/`), and connects directly to the K3s cluster API. Ensure your `kubeconfig.yaml` points to the correct endpoint (e.g., `https://k3s.corp.com:6443`).

### Required Connection Variables
To be able to deploy, Terraform needs to connect to Kubernetes using your Kubeconfig file.

> [!WARNING]
> Never commit your `terraform.tfvars` or `kubeconfig.yaml` to the repository. The infrastructure state is safely stored in the K3s cluster.

To configure your local development environment (if you want to run Terraform from your machine):
1. Copy the template file: `terraform.tfvars.example` to `terraform.tfvars`.
2. Fill in the values for `app_image`, `namespace`, and your private registry credentials if applicable.

To configure GitHub Actions, you must create a single **Repository Secret** named `KUBECONFIG_DATA`.
The value of this secret will be the content of your Kubeconfig file encoded in Base64.
1. Run the command to encode using docker: `docker run --rm -v "./path/to/kubeconfig.yaml:/kubeconfig.yaml" alpine base64 /kubeconfig.yaml`
2. Copy the result and paste it in GitHub Secrets.

### Container Registries Configuration
For detailed instructions on how to authenticate GitHub Actions and K3s with custom private registries or GitHub Container Registry (GHCR), please refer to the [Registry Setup Guide](docs/registry-setup.md).

### Running the Deployment
1. Navigate to the directory: `cd terraform`
2. Initialize the provider: `terraform init`
3. Review the changes to apply: `terraform plan`
4. Execute the deployment: `terraform apply`

*(Note: In continuous integration scenarios, GitHub Actions will inject these credentials using GitHub Secrets).*

### State Management (Remote State)
Terraform is configured to use the `kubernetes` remote backend. This means the state file (`terraform.tfstate`) **is not saved locally**, but is stored securely and encrypted as a `Secret` directly inside the K3s cluster.
- **Security:** The state is never uploaded to the repository, thus protecting credentials and sensitive data.
- **CI/CD:** Allows GitHub Actions (using your local Self-hosted Runner) and local developers to share exactly the same state, preventing infrastructure conflicts and the classic "resource already exists" error.

### Environments and Namespaces
In Kubernetes, a **Namespace** is like creating a "virtual folder" inside your cluster. It is used to group resources and prevent them from colliding. For example, you could have a `production` namespace and a `development` one.

**How to change it in this project?**
Your code is already prepared for this. In the `terraform/variables.tf` file, there is a variable named `namespace` that defaults to `"default"`.
To deploy your application in a different space:
1. Make sure to create the namespace in K3s first (e.g., `kubectl create namespace my-app`).
2. Edit your `terraform/terraform.tfvars` file and add the line:
   ```hcl
   namespace = "my-app"
   ```
3. Alternatively, you can have Terraform create the namespace automatically by adding a `kubernetes_namespace` resource in `main.tf`. Upon making your next *commit*, GitHub Actions will deploy your entire ecosystem inside that new logical container.

## Development Methodology

This repository is developed using **Spec-Driven Development**. Any new feature, behavior modification or endpoint must first be defined via a formal specification (documented in the `specs/` directory) and its automated tests (e.g., unit tests / BDD) before or alongside the code implementation. Agents must ensure they comply with these specifications and validate their changes by running the tests.
