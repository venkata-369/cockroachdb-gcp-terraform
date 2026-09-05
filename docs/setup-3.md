Once you have **pushed `gcp-auth-test.yml` successfully**, do the following in this exact order.

### After pushing `gcp-auth-test.yml`

## 1. Open GitHub Actions

Go to:

[https://github.com/venkata-369/cockroachdb-gcp-terraform/actions](https://github.com/venkata-369/cockroachdb-gcp-terraform/actions)

You should see:

**GCP Authentication Test**

Click it.

---

## 2. Run the workflow manually

On the right side, click:

**Run workflow**

Select:

```text
Branch: main
```

Then click:

**Run workflow**

---

## 3. Check the result

You should see one job:

```text
Test GCP Authentication
```

Open it.

You should get:

```text
✓ Checkout
✓ Authenticate to Google Cloud
✓ Setup Google Cloud CLI
✓ Test GCP Access
```

The final step should show the service account:

```text
terraform-github@crdb-learning.iam.gserviceaccount.com
```

and information for:

```text
crdb-learning
```

### If everything is green

🎉 **GitHub → GCP authentication is confirmed.**

At that point, **do not modify the authentication setup anymore**.

---

# 4. Then create the Terraform project

After authentication succeeds, your repository should become:

```text
cockroachdb-gcp-terraform/
│
├── .github/
│   └── workflows/
│       ├── gcp-auth-test.yml
│       └── terraform.yml
│
├── docs/
│
├── main.tf
├── variables.tf
├── outputs.tf
├── versions.tf
├── .gitignore
└── README.md
```

We will create these Terraform files next.

---

# 5. Terraform architecture we will build

Your requested environment:

```text
                     GCP
                 crdb-learning
                       |
                       v
                 Cockroach VPC
                       |
          +------------+------------+
          |            |            |
          v            v            v
       subnet-1     subnet-2     subnet-3
       10.10.1.0    10.10.2.0    10.10.3.0
          |            |            |
          v            v            v
       CRDB-1       CRDB-2       CRDB-3
```

Three VM nodes:

```text
Node 1
Node 2
Node 3
```

Firewall rules will include your requested:

```text
22       SSH
8080     Application/HTTP
25267    Your requested port
ICMP     Ping
```

And for CockroachDB operation we will separately handle:

```text
26257    CockroachDB SQL / inter-node traffic
```

We'll keep the firewall design sensible rather than unnecessarily exposing everything to the internet.

---

# 6. Terraform will be executed by GitHub Actions

The final workflow will be:

```text
You
 |
 | git push
 v
GitHub
 |
 v
GitHub Actions
 |
 v
WIF Authentication
 |
 v
GCP Service Account
 |
 v
Terraform
 |
 +--> VPC
 |
 +--> 3 Subnets
 |
 +--> Firewall
 |
 +--> CRDB Node 1
 |
 +--> CRDB Node 2
 |
 +--> CRDB Node 3
```

---

# 7. We will NOT use the JSON key

Your file:

```text
crdb-learning-28b4564feaeb.json
```

should **not** be copied into the repository.

It should never be committed:

```text
❌ crdb-learning-28b4564feaeb.json
```

Your `.gitignore` already protects against JSON files if you use:

```gitignore
*.json
```

The GitHub Actions authentication will continue using:

```text
GCP_WORKLOAD_IDENTITY_PROVIDER
GCP_SERVICE_ACCOUNT
```

---

# 8. First Terraform step

Once the authentication test is green, we'll create:

### `versions.tf`

Terraform and Google provider configuration.

### `main.tf`

VPC, subnets, firewall and VM resources.

### `variables.tf`

Project, region, zone, machine type, CIDRs, etc.

### `outputs.tf`

VM IP addresses and useful outputs.

### `.github/workflows/terraform.yml`

GitHub Actions:

```text
terraform fmt
terraform init
terraform validate
terraform plan
terraform apply
```

---

## So your immediate next step

**Run the `GCP Authentication Test` from GitHub Actions.**

If it is **green**, send me the result/screenshot.

Then I'll give you the **complete Terraform setup from Step 1**, including the exact commands to create `versions.tf`, `variables.tf`, `main.tf`, `outputs.tf`, `.gitignore`, and the GitHub Actions Terraform workflow—without mixing it with the WIF setup you've already completed.
