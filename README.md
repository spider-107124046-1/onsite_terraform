# GCP Infrastructure Automation with Terraform

## Prerequisites

- Terraform ≥ 1.5
- gcloud CLI (for authentication)
- GCP Project with billing enabled
- Enabled APIs:
  - Compute Engine API
  - Kubernetes Engine API
  - Cloud SQL Admin API
  - Secret Manager API
  - IAM API
  - Cloud Storage API
- A GCS bucket for storing remote Terraform state

---

## Authentication Setup

### Option 1: Local Developer Machine

```bash
gcloud auth application-default login
```

This sets up [Application Default Credentials (ADC)](https://cloud.google.com/docs/authentication/provide-credentials-adc) locally.

### Option 2: CI (Jenkins)

1. Create a service account:

   ```bash
   gcloud iam service-accounts create terraform-ci \
     --display-name="Terraform CI/CD"
   ```

2. Grant required IAM roles:

   ```bash
   gcloud projects add-iam-policy-binding YOUR_PROJECT_ID \
     --member="serviceAccount:terraform-ci@YOUR_PROJECT_ID.iam.gserviceaccount.com" \
     --role="roles/editor"
   ```

3. Generate a key:

   ```bash
   gcloud iam service-accounts keys create terraform-ci.json \
     --iam-account=terraform-ci@YOUR_PROJECT_ID.iam.gserviceaccount.com
   ```

4. Upload the JSON key to Jenkins as a **secret file** with ID: `gcp-service-account`.

---

## Codebase Structure

```
infra/
├── main.tf                  # Root module calls all infra modules
├── backend.tf               # Terraform backend configuration
├── variables.tf             # Global variables
├── outputs.tf               # Shared outputs
├── data.tf                  # GCP secrets & resources
├── locals.tf                # Local derived values
├── envs/                    # Environment tfvars & backend configs (examples)
│   ├── dev.tfvars.example
│   ├── staging.tfvars.example
│   └── prod.tfvars.example
├── modules/                 # Reusable modules
│   ├── gke_cluster/
│   ├── vpc/
│   ├── database/
│   ├── cloud_storage/
│   └── secrets/
```

---

## Environment Overview

| Environment | Purpose                | Workspace   | tfvars File           |
| ----------- | ---------------------- | ----------- | --------------------- |
| `dev`       | Local/dev testing      | `dev`       | `envs/dev.tfvars`     |
| `staging`   | Pre-production testing | `staging`   | `envs/staging.tfvars` |
| `prod`      | Live production        | `prod`      | `envs/prod.tfvars`    |
| `feature/*` | Ephemeral preview envs | `feature-*` | auto-generated        |

*(due to time constraints, only the staging environment is used in the codebase for now)*

---

## Terraform Usage

### Prerequisites

The environment variable `GOOGLE_APPLICATION_CREDENTIALS` must be set to the account key json file obtained from the [Service Accounts](https://console.cloud.google.com/iam-admin/serviceaccounts) page in GCP Console, for terraform to work with it.

```bash
export GOOGLE_APPLICATION_CREDENTIALS=/path/to/terraform-serviceacc-key.json
```

Additionally, a storage bucket to sync the state lock is to be created, and updated to enable versioning.

```bash
gcloud storage buckets create gs://${BUCKET_NAME} \
  --project=${PROJECT_ID} \
  --location=${LOCATION} \
  --uniform-bucket-level-access

gcloud storage buckets update gs://${BUCKET_NAME} \
  --versioning
```

Then, terraform's backend must be set to use this bucket:

```hcl
terraform {
  backend "gcs" {
    bucket  = "<BUCKET_NAME>"
    prefix  = "gke-cluster"
  }
}
```

### Initialize Terraform

Inside the `infra` folder,

```bash
terraform init -backend-config=backend.tf
```

### Plan

Edit the appropriate .tfvars file with valid credentials, then use the path of that file in the `-var-file` flag:

```bash
terraform plan -var-file=envs/staging.tfvars -out=tfplan.out
```

### Apply

```bash
terraform apply tfplan.out
```

### Destroy

```bash
terraform destroy -var-file=envs/staging.tfvars
```

### Workspaces (Optional)

```bash
terraform workspace new staging
terraform workspace select staging
```

---

## Environment Deployment

Run the commands while in the `infra` folder.

### Dev/Staging

```bash
terraform init -backend-config=backend.tf
terraform workspace select staging || terraform workspace new staging
terraform apply -var-file=envs/staging.tfvars
```

### Production

**Only apply from CI with manual approval.**

```bash
terraform init -backend-config=backend.tf
terraform workspace select prod || terraform workspace new prod
terraform apply -var-file=envs/prod.tfvars
```

### Feature Branch (CI Auto-Generated)

In CI, `.tfvars` are generated dynamically from branch name and applied with:

```bash
terraform apply -var-file=envs/feature-<feature>.tfvars
```

After merge/close, Jenkins destroys the ephemeral environment.

---

## CI/CD Pipeline (Jenkins)

The `Jenkinsfile` automates:

* `terraform init`, `plan`, `apply` for staging/main
* Approval gates for production
* Auto-destroy for `feature/*` branches
* Uses a secret file (`GOOGLE_APPLICATION_CREDENTIALS`) for GCP auth

---

## Secrets & Configuration

Secrets (e.g. DB credentials) are stored securely in **GCP Secret Manager**.

To create credentials in secret manager,

```bash
echo -n '<username>' | gcloud secrets create db-user \                  
  --replication-policy="automatic" \
  --data-file=-

echo -n 'super-secure-password' | gcloud secrets create db-password \
  --replication-policy="automatic" \
  --data-file=-
```

Accessed in Terraform using (`data.tf` and `locals.tf`):

```hcl
data "google_secret_manager_secret_version" "db_user" {
  secret  = "db-user"
  project = var.project_id
  version = "latest"
}

data "google_secret_manager_secret_version" "db_password" {
  secret  = "db-password"
  project = var.project_id
  version = "latest"
}

locals {
  db_user     = data.google_secret_manager_secret_version.db_user.secret_data
  db_password = data.google_secret_manager_secret_version.db_password.secret_data
}
```

**Never commit secrets or `.tfvars` with sensitive values to Git!**

---

## Contribution & Development

1. Fork the repo and clone it
2. Set up GCP credentials
3. Create a new feature branch
4. Write code and push → ephemeral environment will be provisioned
5. Submit a PR

---