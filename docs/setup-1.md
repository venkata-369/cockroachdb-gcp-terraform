### Your actual configuration

| Item                       | Value                                                    |
| -------------------------- | -------------------------------------------------------- |
| GCP Project ID             | `crdb-learning`                                          |
| GCP Project Number         | `117351038489`                                           |
| GitHub user                | `venkata-369`                                            |
| GitHub repository          | `venkata-369/cockroachdb-gcp-terraform`                  |
| Service Account            | `terraform-github@crdb-learning.iam.gserviceaccount.com` |
| Workload Identity Pool     | `github-pool`                                            |
| Workload Identity Provider | `github-provider`                                        |

You have also already created a JSON key:

```text
crdb-learning-28b4564feaeb.json
```

**We will NOT use that JSON key for GitHub Actions.** WIF will replace it.

---

## STEP 1 — Set the GCP project

Open **Google Cloud Shell** and run:

```bash
gcloud config set project crdb-learning
```

Verify:

```bash
gcloud config get-value project
```

Expected:

```text
crdb-learning
```

---

## STEP 2 — Enable required APIs

Run:

```bash
gcloud services enable compute.googleapis.com
```

```bash
gcloud services enable iam.googleapis.com
```

```bash
gcloud services enable iamcredentials.googleapis.com
```

```bash
gcloud services enable sts.googleapis.com
```

These are needed for:

```text
Compute Engine
     ↓
IAM
     ↓
Service Account
     ↓
Workload Identity
     ↓
GitHub OIDC authentication
```

---

## STEP 3 — Verify your Service Account

You already created:

```text
terraform-github@crdb-learning.iam.gserviceaccount.com
```

Verify it:

```bash
gcloud iam service-accounts list \
  --project=crdb-learning
```

You should see:

```text
terraform-github@crdb-learning.iam.gserviceaccount.com
```

You already gave this service account **Owner** permission, so we don't need to change that right now.

> For a learning/lab environment, Owner is convenient. Later, we should reduce it to least-privilege permissions.

---

## STEP 4 — Verify the Project Number

You already obtained:

```text
117351038489
```

You can verify again:

```bash
gcloud projects describe crdb-learning \
  --format="value(projectNumber)"
```

Expected:

```text
117351038489
```

This number is important because Google identifies the Workload Identity Pool using the **project number**, not the project ID.

---

## STEP 5 — Create the Workload Identity Pool

You previously created this successfully, but here is the correct command for reference:

```bash
gcloud iam workload-identity-pools create github-pool \
  --project=crdb-learning \
  --location=global \
  --display-name="GitHub Actions Pool"
```

### If you already created it

Do **not** run the create command again.

Instead verify:

```bash
gcloud iam workload-identity-pools describe github-pool \
  --project=crdb-learning \
  --location=global
```

You should see the pool:

```text
github-pool
```

Your structure is now:

```text
GCP Project
crdb-learning
      |
      v
Workload Identity Pool
github-pool
```

---

## STEP 6 — Create the Workload Identity Provider

You have already successfully completed this step.

Your command was:

```bash
gcloud iam workload-identity-pools providers create-oidc github-provider \
  --project=crdb-learning \
  --location=global \
  --workload-identity-pool=github-pool \
  --display-name="GitHub Actions Provider" \
  --attribute-mapping="google.subject=assertion.sub,attribute.actor=assertion.actor,attribute.repository=assertion.repository" \
  --attribute-condition="assertion.repository == 'venkata-369/cockroachdb-gcp-terraform'" \
  --issuer-uri="https://token.actions.githubusercontent.com"
```

You received:

```text
Created workload identity pool provider [github-provider].
```

### What is the Workload Identity Provider?

This is the **trust bridge between GitHub and Google Cloud**.

GitHub Actions generates a temporary **OIDC identity token**.

Google receives that token through:

```text
github-provider
```

The provider knows that GitHub is the trusted OIDC issuer:

```text
https://token.actions.githubusercontent.com
```

And our provider has this condition:

```text
assertion.repository == 'venkata-369/cockroachdb-gcp-terraform'
```

Therefore:

```text
GitHub
   |
   | OIDC token
   v
github-provider
   |
   | Is repository correct?
   |
   +---- YES → Continue
   |
   +---- NO  → Reject
```

So another GitHub repository cannot simply use your GCP service account.

---

## STEP 7 — Verify the Provider

Run:

```bash
gcloud iam workload-identity-pools providers describe github-provider \
  --project=crdb-learning \
  --location=global \
  --workload-identity-pool=github-pool
```

You should see information including:

```text
name: projects/117351038489/locations/global/workloadIdentityPools/github-pool/providers/github-provider
```

and:

```text
issuerUri: https://token.actions.githubusercontent.com
```

and the repository condition:

```text
assertion.repository == 'venkata-369/cockroachdb-gcp-terraform'
```

---

## STEP 8 — Give your GitHub repository permission to use the Service Account

This is the important connection.

We have:

```text
GitHub
   ↓
github-provider
   ↓
github-pool
```

Now we need:

```text
github-pool
   ↓
Service Account
   ↓
terraform-github@crdb-learning.iam.gserviceaccount.com
```

Run this **exact command**:

```bash
gcloud iam service-accounts add-iam-policy-binding \
  terraform-github@crdb-learning.iam.gserviceaccount.com \
  --project=crdb-learning \
  --role="roles/iam.workloadIdentityUser" \
  --member="principalSet://iam.googleapis.com/projects/117351038489/locations/global/workloadIdentityPools/github-pool/attribute.repository/venkata-369/cockroachdb-gcp-terraform"
```

### What does this command mean?

The important section is:

```text
attribute.repository/venkata-369/cockroachdb-gcp-terraform
```

It says:

> The GitHub repository `venkata-369/cockroachdb-gcp-terraform` is allowed to impersonate this GCP service account.

So the complete trust chain becomes:

```text
venkata-369/cockroachdb-gcp-terraform
                    |
                    | GitHub OIDC
                    v
             github-provider
                    |
                    v
               github-pool
                    |
                    | WorkloadIdentityUser
                    v
terraform-github@crdb-learning.iam.gserviceaccount.com
                    |
                    | Owner
                    v
              crdb-learning
```

---

# STEP 9 — Verify the Service Account Permission

Run:

```bash
gcloud iam service-accounts get-iam-policy \
  terraform-github@crdb-learning.iam.gserviceaccount.com \
  --project=crdb-learning
```

Look for:

```text
roles/iam.workloadIdentityUser
```

You should also see a principal similar to:

```text
principalSet://iam.googleapis.com/projects/117351038489/locations/global/workloadIdentityPools/github-pool/attribute.repository/venkata-369/cockroachdb-gcp-terraform
```

If you see that, the connection is correct.

---

## STEP 10 — Get the Workload Identity Provider value for GitHub

Now run:

```bash
gcloud iam workload-identity-pools providers describe github-provider \
  --project=crdb-learning \
  --location=global \
  --workload-identity-pool=github-pool \
  --format="value(name)"
```

Because we know your project number, the result should be exactly:

```text
projects/117351038489/locations/global/workloadIdentityPools/github-pool/providers/github-provider
```

### This is what we will put into GitHub.

Go to:

[https://github.com/venkata-369/cockroachdb-gcp-terraform](https://github.com/venkata-369/cockroachdb-gcp-terraform)

Then:

```text
Settings
   ↓
Secrets and variables
   ↓
Actions
   ↓
New repository secret
```

Create the first secret.

### Secret 1

**Name:**

```text
GCP_WORKLOAD_IDENTITY_PROVIDER
```

**Value:**

```text
projects/117351038489/locations/global/workloadIdentityPools/github-pool/providers/github-provider
```

---

Create the second secret.

### Secret 2

**Name:**

```text
GCP_SERVICE_ACCOUNT
```

**Value:**

```text
terraform-github@crdb-learning.iam.gserviceaccount.com
```

Your GitHub repository should now have:

```text
Repository Secrets
│
├── GCP_WORKLOAD_IDENTITY_PROVIDER
│   └── projects/117351038489/locations/global/workloadIdentityPools/github-pool/providers/github-provider
│
└── GCP_SERVICE_ACCOUNT
    └── terraform-github@crdb-learning.iam.gserviceaccount.com
```

---

## Where we are now

After Step 10, the GCP side is essentially ready:

```text
                         GCP
                    crdb-learning
                          |
                          |
                 Workload Identity
                          |
                   +------+------+
                   |             |
                   v             v
              github-pool   Service Account
                   |             |
                   v             |
            github-provider      |
                   |             |
                   +------+------+
                          |
                          |
              venkata-369/cockroachdb-
                  gcp-terraform
                          |
                          v
                   GitHub Actions
```

And importantly:

```text
❌ JSON key → NOT USED
❌ JSON key → NOT uploaded to GitHub

✅ GitHub OIDC
✅ Workload Identity Pool
✅ Workload Identity Provider
✅ Service Account
```

## Next step

Once you have completed **Step 8**, verify it with Step 9. Then add the two GitHub secrets in Step 10.

**After that, the next thing we should do is NOT create the 3-node cluster immediately.** We'll first create a tiny GitHub Actions workflow that only runs:

```text
GitHub Actions
      ↓
Authenticate to GCP
      ↓
gcloud projects describe crdb-learning
```

If that succeeds, we know **GitHub → WIF → Service Account → GCP is working**. Then we'll put the Terraform 3-node VPC/VM configuration into your repository.
