# Rules for iac-sdd-app

1. **Tech Stack**:
   - Application: Golang.
   - Containerization: Docker (Alpine-based, multi-stage builds).
   - Infrastructure as Code: Terraform.
   - Orchestration/Deployment: K3s / Portainer.

2. **Project Structure**:
   - `app/`: Contains the Golang application code and `Dockerfile`.
   - `terraform/`: Contains Terraform configuration files.
   - `specs/`: Contains formal specification documents (e.g., `app.md`).
   - `.github/workflows/`: CI/CD workflows for GitHub Actions.

3. **Behavior**:
   - The Go application must respond with "Hello from k3s {podId}" on its endpoints.
   - Terraform configurations should remain modular (`main.tf`, `variables.tf`, `terraform.tfvars`).
   - Keep images as lightweight as possible using `alpine` or `scratch`.

4. **Development Methodology**:
   - This repository follows **Spec-Driven Development**.
   - Agents MUST ensure that all new features or logic changes are driven by formal specifications (placed in the `specs/` directory) and tests.
   - Before implementing or modifying features, agents should write or update the corresponding specification document in `specs/`, write the tests (e.g., in `main_test.go`), and ensure they pass upon completion.

5. **Infrastructure & CI/CD**:
   - Terraform MUST use the `kubernetes` remote backend for state management. State files `.tfstate` should never be generated locally or committed.
   - All deployments are executed via GitHub Actions on a local self-hosted runner (`gh-actions-runner`).
   - Container images are pushed to and pulled from a custom private registry, requiring explicit authentication logic in the pipelines.
