# Container Registries Configuration

## 1. Using a Custom Registry in GitHub Actions
If you want GitHub Actions to push your image to a private registry (e.g., `cr.corp.com`):
1. Go to **Settings -> Secrets and variables -> Actions** in your GitHub repository.
2. Create the following secrets (**New repository secret**):
   - `REGISTRY_URL`: Your registry URL (e.g., `cr.corp.com`)
   - `REGISTRY_USERNAME`: Your registry username.
   - `REGISTRY_PASSWORD`: Your password or token.
3. Make sure to add the `docker login` step in your `.github/workflows/deploy.yml` file before `docker build` and `docker push`.

## 2. Using GitHub Container Registry (GHCR) in K3s
If you prefer to push your images to the GitHub registry (`ghcr.io`) and need your K3s cluster to pull them despite being private:

**Step A: Generate a Token in GitHub**
1. In GitHub, go to **Settings** (from your account, top right) -> **Developer settings** -> **Personal access tokens** -> **Tokens (classic)**.
2. Click on **Generate new token (classic)**.
3. Assign a name (e.g., `k3s-ghcr-pull`) and select **ONLY the `read:packages` permission**.
4. Generate the token and copy it (starts with `ghp_...`).

**Step B: Configure Authentication**
Edit the `/etc/rancher/k3s/registries.yaml` file on your K3s nodes and add:
```yaml
configs:
  "ghcr.io":
    auth:
      username: "YourGitHubUsername"
      password: "ghp_yourGeneratedToken..."
```
Restart K3s (e.g., `rc-service k3s restart` or `systemctl restart k3s`).
