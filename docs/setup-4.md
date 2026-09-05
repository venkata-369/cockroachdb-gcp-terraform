Now we can move to the **actual Terraform deployment**.

Your target is:

* GCP project: `crdb-learning`
* 3-node CockroachDB cluster
* 3 separate subnets
* VPC
* Firewall: TCP `22`, `8080`, `25267`, `26257`, ICMP
* Terraform executed through GitHub Actions
* Authentication through **Workload Identity Federation**
* No service-account JSON key in GitHub
* `docs/` stays on GitHub but is ignored locally

I recommend we do this in **two phases**:

1. Terraform creates the GCP networking + 3 VMs.
2. Then we install/configure CockroachDB on those VMs.

Don't try to configure the CockroachDB cluster inside the first Terraform script yet. First make sure the infrastructure is working.

---

## 1. First finish your Git merge

You were at:

```bash
git fetch origin main
```

Now run:

```bash
git merge origin/main
```

If successful:

```bash
git status
```

Then:

```bash
git push origin main
```

After that, continue below.

---

# 2. Your local repository

You should have:

```text
cockroachdb-gcp-terraform/
│
├── .github/
│   └── workflows/
│       └── gcp-auth-test.yml
│
├── .gitignore
├── README.md
│
├── main.tf
├── variables.tf
├── outputs.tf
└── versions.tf
```

You **do not need `docs/` locally**.

---

# 3. Create `versions.tf`

From Git Bash:

```bash
touch versions.tf
```

Put this inside:

```hcl
terraform {
  required_version = ">= 1.6.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 7.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
  zone    = var.zone
}
```

---

# 4. Create `variables.tf`

```bash
touch variables.tf
```

Put:

```hcl
variable "project_id" {
  description = "GCP project ID"
  type        = string
  default     = "crdb-learning"
}

variable "region" {
  description = "GCP region"
  type        = string
  default     = "asia-south1"
}

variable "zone" {
  description = "GCP zone"
  type        = string
  default     = "asia-south1-a"
}

variable "machine_type" {
  description = "GCP VM machine type"
  type        = string
  default     = "e2-standard-2"
}

variable "vpc_name" {
  description = "VPC name"
  type        = string
  default     = "cockroach-vpc"
}

variable "subnet_1_cidr" {
  description = "CIDR for subnet 1"
  type        = string
  default     = "10.10.1.0/24"
}

variable "subnet_2_cidr" {
  description = "CIDR for subnet 2"
  type        = string
  default     = "10.10.2.0/24"
}

variable "subnet_3_cidr" {
  description = "CIDR for subnet 3"
  type        = string
  default     = "10.10.3.0/24"
}

variable "ssh_source_ranges" {
  description = "CIDR ranges allowed to SSH"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}
```

### Important

For a learning environment, `0.0.0.0/0` is convenient.

For production, restrict SSH to your actual public IP.

---

# 5. Create `main.tf`

```bash
touch main.tf
```

Put this:

```hcl
# ------------------------------------------------------------
# VPC
# ------------------------------------------------------------

resource "google_compute_network" "cockroach_vpc" {
  name                    = var.vpc_name
  auto_create_subnetworks = false
  routing_mode            = "REGIONAL"
}

# ------------------------------------------------------------
# Subnet 1
# ------------------------------------------------------------

resource "google_compute_subnetwork" "subnet_1" {
  name          = "cockroach-subnet-1"
  ip_cidr_range = var.subnet_1_cidr
  region        = var.region
  network       = google_compute_network.cockroach_vpc.id
}

# ------------------------------------------------------------
# Subnet 2
# ------------------------------------------------------------

resource "google_compute_subnetwork" "subnet_2" {
  name          = "cockroach-subnet-2"
  ip_cidr_range = var.subnet_2_cidr
  region        = var.region
  network       = google_compute_network.cockroach_vpc.id
}

# ------------------------------------------------------------
# Subnet 3
# ------------------------------------------------------------

resource "google_compute_subnetwork" "subnet_3" {
  name          = "cockroach-subnet-3"
  ip_cidr_range = var.subnet_3_cidr
  region        = var.region
  network       = google_compute_network.cockroach_vpc.id
}

# ------------------------------------------------------------
# Firewall - SSH
# ------------------------------------------------------------

resource "google_compute_firewall" "allow_ssh" {
  name    = "cockroach-allow-ssh"
  network = google_compute_network.cockroach_vpc.name

  direction = "INGRESS"

  source_ranges = var.ssh_source_ranges

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  target_tags = ["cockroachdb"]
}

# ------------------------------------------------------------
# Firewall - CockroachDB and requested ports
# ------------------------------------------------------------

resource "google_compute_firewall" "allow_cockroach" {
  name    = "cockroach-allow-internal"
  network = google_compute_network.cockroach_vpc.name

  direction = "INGRESS"

  source_ranges = [
    var.subnet_1_cidr,
    var.subnet_2_cidr,
    var.subnet_3_cidr
  ]

  allow {
    protocol = "tcp"
    ports = [
      "25267",
      "26257"
    ]
  }

  target_tags = ["cockroachdb"]
}

# ------------------------------------------------------------
# Firewall - Port 8080
# ------------------------------------------------------------

resource "google_compute_firewall" "allow_8080" {
  name    = "cockroach-allow-8080"
  network = google_compute_network.cockroach_vpc.name

  direction = "INGRESS"

  source_ranges = ["0.0.0.0/0"]

  allow {
    protocol = "tcp"
    ports    = ["8080"]
  }

  target_tags = ["cockroachdb"]
}

# ------------------------------------------------------------
# Firewall - ICMP
# ------------------------------------------------------------

resource "google_compute_firewall" "allow_icmp" {
  name    = "cockroach-allow-icmp"
  network = google_compute_network.cockroach_vpc.name

  direction = "INGRESS"

  source_ranges = [
    var.subnet_1_cidr,
    var.subnet_2_cidr,
    var.subnet_3_cidr
  ]

  allow {
    protocol = "icmp"
  }

  target_tags = ["cockroachdb"]
}

# ------------------------------------------------------------
# VM 1
# ------------------------------------------------------------

resource "google_compute_instance" "cockroach_1" {
  name         = "cockroach-1"
  machine_type = var.machine_type
  zone         = var.zone

  tags = ["cockroachdb"]

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2404-lts-amd64"
      size  = 30
      type  = "pd-balanced"
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.subnet_1.id

    access_config {
      # Ephemeral public IP
    }
  }

  metadata = {
    enable-oslogin = "TRUE"
  }
}

# ------------------------------------------------------------
# VM 2
# ------------------------------------------------------------

resource "google_compute_instance" "cockroach_2" {
  name         = "cockroach-2"
  machine_type = var.machine_type
  zone         = var.zone

  tags = ["cockroachdb"]

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2404-lts-amd64"
      size  = 30
      type  = "pd-balanced"
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.subnet_2.id

    access_config {
      # Ephemeral public IP
    }
  }

  metadata = {
    enable-oslogin = "TRUE"
  }
}

# ------------------------------------------------------------
# VM 3
# ------------------------------------------------------------

resource "google_compute_instance" "cockroach_3" {
  name         = "cockroach-3"
  machine_type = var.machine_type
  zone         = var.zone

  tags = ["cockroachdb"]

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2404-lts-amd64"
      size  = 30
      type  = "pd-balanced"
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.subnet_3.id

    access_config {
      # Ephemeral public IP
    }
  }

  metadata = {
    enable-oslogin = "TRUE"
  }
}
```

---

# 6. Create `outputs.tf`

```bash
touch outputs.tf
```

Put:

```hcl
output "vpc_name" {
  description = "VPC name"
  value       = google_compute_network.cockroach_vpc.name
}

output "subnet_1_name" {
  value = google_compute_subnetwork.subnet_1.name
}

output "subnet_2_name" {
  value = google_compute_subnetwork.subnet_2.name
}

output "subnet_3_name" {
  value = google_compute_subnetwork.subnet_3.name
}

output "cockroach_1_internal_ip" {
  value = google_compute_instance.cockroach_1.network_interface[0].network_ip
}

output "cockroach_1_external_ip" {
  value = google_compute_instance.cockroach_1.network_interface[0].access_config[0].nat_ip
}

output "cockroach_2_internal_ip" {
  value = google_compute_instance.cockroach_2.network_interface[0].network_ip
}

output "cockroach_2_external_ip" {
  value = google_compute_instance.cockroach_2.network_interface[0].access_config[0].nat_ip
}

output "cockroach_3_internal_ip" {
  value = google_compute_instance.cockroach_3.network_interface[0].network_ip
}

output "cockroach_3_external_ip" {
  value = google_compute_instance.cockroach_3.network_interface[0].access_config[0].nat_ip
}
```

---

# 7. Format and validate locally

Run:

```bash
terraform fmt
```

Then:

```bash
terraform init
```

Then:

```bash
terraform validate
```

You should get:

```text
Success! The configuration is valid.
```

---

# 8. Very important — don't use the JSON key

For local Terraform, you can authenticate with your own GCP login:

```bash
gcloud auth application-default login
```

Then:

```bash
gcloud config set project crdb-learning
```

Check:

```bash
gcloud auth application-default print-access-token
```

You do **not** need:

```bash
export GOOGLE_APPLICATION_CREDENTIALS=crdb-learning-28b4564feaeb.json
```

Don't upload that key.

---

# 9. Test Terraform locally

Run:

```bash
terraform plan
```

You should see Terraform planning approximately:

```text
1 VPC
3 subnets
4 firewall rules
3 VM instances
```

Don't run `terraform apply` locally yet.

We want GitHub Actions to perform the deployment.

---

# 10. Create Terraform GitHub Actions workflow

Create:

```text
.github/workflows/terraform.yml
```

Put:

```yaml
name: Terraform

on:
  workflow_dispatch:

permissions:
  contents: read
  id-token: write

jobs:
  terraform:
    name: Terraform
    runs-on: ubuntu-latest

    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Authenticate to Google Cloud
        uses: google-github-actions/auth@v2
        with:
          workload_identity_provider: ${{ secrets.GCP_WORKLOAD_IDENTITY_PROVIDER }}
          service_account: ${{ secrets.GCP_SERVICE_ACCOUNT }}

      - name: Setup gcloud
        uses: google-github-actions/setup-gcloud@v2

      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v3

      - name: Terraform Init
        run: terraform init

      - name: Terraform Format Check
        run: terraform fmt -check

      - name: Terraform Validate
        run: terraform validate

      - name: Terraform Plan
        run: terraform plan
```

### First run only PLAN

Notice that I have **not** put:

```yaml
terraform apply
```

yet.

That's intentional.

First we'll verify that GitHub Actions can authenticate to GCP and that Terraform can successfully create the plan.

---

# 11. Commit the Terraform files

Run:

```bash
git status
```

You should see something like:

```text
modified: ...
new file: main.tf
new file: variables.tf
new file: outputs.tf
new file: versions.tf
new file: .github/workflows/terraform.yml
```

Then:

```bash
git add main.tf variables.tf outputs.tf versions.tf .github/workflows/terraform.yml
```

Commit:

```bash
git commit -m "Add Terraform GCP infrastructure"
```

Then:

```bash
git push origin main
```

Because your `docs/` is ignored locally, it won't be added.

---

# 12. Run Terraform from GitHub Actions

Go to:

[https://github.com/venkata-369/cockroachdb-gcp-terraform/actions](https://github.com/venkata-369/cockroachdb-gcp-terraform/actions)

You should now see:

```text
GCP Authentication Test
Terraform
```

First run:

### GCP Authentication Test

Make sure this is green.

Then:

### Terraform

Click:

**Run workflow → main → Run workflow**

The expected sequence:

```text
Checkout                  ✅
Authenticate GCP          ✅
Setup gcloud              ✅
Setup Terraform           ✅
Terraform Init            ✅
Terraform Format          ✅
Terraform Validate        ✅
Terraform Plan            ✅
```

---

# 13. After PLAN succeeds

Only after the plan is successful will we change:

```yaml
- name: Terraform Plan
  run: terraform plan
```

to an apply workflow.

But I recommend that we **don't automatically apply on every `git push`** for your learning cluster.

We'll use:

```text
GitHub Actions
      |
      v
terraform plan
      |
      v
Manual approval
      |
      v
terraform apply
```

This prevents accidentally recreating/destroying your CockroachDB infrastructure.

---

# 14. One architectural point

You requested **3 subnets** and a **3-node CockroachDB cluster**.

The above creates:

```text
Subnet 1 → Node 1
Subnet 2 → Node 2
Subnet 3 → Node 3
```

However, all three VMs are currently in:

```text
asia-south1-a
```

That is intentional for the **first infrastructure test**.

Once this works, we can improve the architecture to something closer to:

```text
Region: asia-south1

        VPC
         |
   +-----+-----+-----+
   |           |     |
   v           v     v
Subnet-1    Subnet-2 Subnet-3
   |           |     |
   v           v     v
Node-1      Node-2  Node-3
zone-a      zone-b  zone-c
```

That gives better failure-domain separation.

---

## Your immediate sequence

Don't jump ahead. Do this:

```bash
git merge origin/main
```

then:

```bash
git status
```

then create:

```text
versions.tf
variables.tf
main.tf
outputs.tf
```

Then:

```bash
terraform fmt
terraform init
terraform validate
terraform plan
```

Then create:

```text
.github/workflows/terraform.yml
```

Commit and push:

```bash
git add main.tf variables.tf outputs.tf versions.tf .github/workflows/terraform.yml
git commit -m "Add Terraform GCP infrastructure"
git push origin main
```

Then run **Terraform → Run workflow** in GitHub Actions.

**Stop after `terraform plan` succeeds.** At that point, we can inspect the plan before allowing Terraform to create the 3 VMs.
