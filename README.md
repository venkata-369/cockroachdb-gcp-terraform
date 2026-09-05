## CockroachDB GCP Terraform

Terraform project to provision a 3-node CockroachDB lab environment on Google Cloud Platform using GitHub Actions.

## Architecture

```text
                    GitHub
                       |
                       |
                GitHub Actions
                       |
                       | OIDC
                       v
             GCP Workload Identity
                       |
                       v
        terraform-github@crdb-learning
                       |
                       v
                 GCP Project
                 crdb-learning
                       |
              +--------+--------+
              |        |        |
              v        v        v
           Subnet-1 Subnet-2 Subnet-3
              |        |        |
              v        v        v
           Node-1   Node-2   Node-3
```

## Infrastructure

The Terraform configuration creates:

* Google Cloud VPC
* Three custom subnets
* Three Compute Engine instances
* Firewall rules
* Internal network communication
* ICMP/ping access
* SSH access
* CockroachDB DB Console access
* CockroachDB SQL/inter-node communication

## Network

| Resource | CIDR           |
| -------- | -------------- |
| Subnet 1 | `10.10.1.0/24` |
| Subnet 2 | `10.10.2.0/24` |
| Subnet 3 | `10.10.3.0/24` |

Example node addresses:

```text
Node 1 → 10.10.1.x
Node 2 → 10.10.2.x
Node 3 → 10.10.3.x
```

## Firewall

The lab environment uses:

| Port  | Purpose                            |
| ----- | ---------------------------------- |
| 22    | SSH                                |
| 8080  | CockroachDB DB Console             |
| 25267 | Requested custom port              |
| 26257 | CockroachDB SQL/inter-node traffic |
| ICMP  | Ping                               |

For production environments, SSH and DB Console access should be restricted rather than exposed to `0.0.0.0/0`.

## GCP Project

```text
Project ID:
crdb-learning
```

## Service Account

GitHub Actions uses:

```text
terraform-github@crdb-learning.iam.gserviceaccount.com
```

Authentication is performed using Google Cloud Workload Identity Federation.

No long-lived GCP service-account JSON key is required.

## GitHub Repository

```text
https://github.com/venkata-369/cockroachdb-gcp-terraform
```

## GitHub Actions Authentication

The workflow uses:

```yaml
permissions:
  contents: read
  id-token: write
```

Google Cloud authentication:

```yaml
- name: Authenticate to Google Cloud
  uses: google-github-actions/auth@v2
  with:
    workload_identity_provider: ${{ secrets.GCP_WORKLOAD_IDENTITY_PROVIDER }}
    service_account: ${{ secrets.GCP_SERVICE_ACCOUNT }}
```

## Required GitHub Secrets

Create the following repository secrets:

```text
GCP_WORKLOAD_IDENTITY_PROVIDER
GCP_SERVICE_ACCOUNT
```

`GCP_SERVICE_ACCOUNT`:

```text
terraform-github@crdb-learning.iam.gserviceaccount.com
```

`GCP_WORKLOAD_IDENTITY_PROVIDER`:

```text
projects/PROJECT_NUMBER/locations/global/workloadIdentityPools/github-pool/providers/github-provider
```

Replace `PROJECT_NUMBER` with the GCP project number.

## Terraform Commands

For local testing:

```bash
terraform init
```

Format:

```bash
terraform fmt
```

Validate:

```bash
terraform validate
```

Create a plan:

```bash
terraform plan
```

Apply:

```bash
terraform apply
```

Destroy the lab:

```bash
terraform destroy
```

## Git Workflow

Clone the repository:

```bash
git clone https://github.com/venkata-369/cockroachdb-gcp-terraform.git
```

Enter the directory:

```bash
cd cockroachdb-gcp-terraform
```

Create a branch:

```bash
git checkout -b terraform-gcp
```

Add files:

```bash
git add .
```

Commit:

```bash
git commit -m "Create GCP CockroachDB infrastructure"
```

Push:

```bash
git push origin terraform-gcp
```

Create a Pull Request on GitHub.

After merging into `main`, GitHub Actions runs Terraform Apply.

## Deployment Flow

```text
Developer
   |
   | git push
   v
GitHub Repository
   |
   v
Pull Request
   |
   v
Terraform Format
   |
   v
Terraform Validate
   |
   v
Terraform Plan
   |
   v
Merge to main
   |
   v
Terraform Apply
   |
   v
GCP Infrastructure
   |
   +---- VPC
   |
   +---- Subnet 1 ---- CockroachDB Node 1
   |
   +---- Subnet 2 ---- CockroachDB Node 2
   |
   +---- Subnet 3 ---- CockroachDB Node 3
```

## CockroachDB

The infrastructure is intended for a CockroachDB learning and testing environment.

CockroachDB normally uses:

```text
26257
```

for SQL and inter-node communication and:

```text
8080
```

for the DB Console.

The custom port `25267` is also included because it was requested for this lab.

## Important Security Note

The service account currently has the `Owner` role for the `crdb-learning` project.

This is convenient for initial learning and testing but is **not recommended for production**.

For a production GitHub Actions deployment, replace Owner with a least-privilege set of IAM roles.

Do not commit:

* Service-account private keys
* `.tfstate` files
* Passwords
* API keys
* Private certificates
* Secret configuration files

## Cleanup

To remove all Terraform-managed infrastructure:

```bash
terraform destroy
```

Or use a GitHub Actions destroy workflow if one is configured.

## Project

GitHub:

https://github.com/venkata-369/cockroachdb-gcp-terraform
