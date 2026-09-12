# Application Specification (App Spec)

This document defines the behavior and formal requirements of the Go web application contained in the `app/` directory. According to the **Spec-Driven Development** methodology, any change in the application must first, or in parallel, be reflected in this document and in the tests (e.g., `main_test.go`).

## 1. Purpose
The application is a simple and ultra-lightweight web microservice designed to be deployed in a K3s cluster using Terraform. Its main function is to identify and return the ID of the pod from which it is responding to verify proper load balancing and deployment.

## 2. Functional Requirements

### 2.1. Main Endpoint
- **Path:** `/` (and by default, any unspecified path catches and responds with the same message if `http.HandleFunc("/")` is used).
- **HTTP Method:** `GET` (Accepts requests by default, although strictly a GET).
- **Response (Body):** `Hello from k3s {podId}\n`
- **Status Code:** `200 OK`

### 2.2. Pod Identification (`podId`)
- The `{podId}` value must be resolved by reading the `HOSTNAME` environment variable.
- In Docker/Kubernetes environments, `HOSTNAME` is by default the container/pod ID.
- **Failure case:** If the `HOSTNAME` variable is not defined or is empty, the default value must be `unknown-pod`.

### 2.3. Network Configuration
- **Listening Port:** The application must read the `PORT` environment variable.
- If `PORT` is not defined, the application must start on the default port `8080`.

## 3. Non-Functional Requirements

### 3.1. Performance and Build
- **Language:** Go (Golang).
- **Dependencies:** Should attempt to remain free of complex external dependencies (use the standard library `net/http`, `os`, `fmt`).
- **Packaging (Docker):** The resulting container must be based on `alpine` (or `scratch`) and use a multi-stage build approach to maintain minimal weight.
- **Linking:** The binary must be compiled with `CGO_ENABLED=0` to ensure it is completely static.

## 4. Acceptance Criteria (Tests)

Automated tests (`main_test.go`) must cover at least the following scenarios:
1. **Base Scenario:** Given a GET request to `/` with the variable `HOSTNAME=test-pod`, the response must be `Hello from k3s test-pod\n` with a 200 code.
2. **No Hostname Scenario:** Given a GET request to `/` without the `HOSTNAME` variable defined, the response must be `Hello from k3s unknown-pod\n` with a 200 code.
