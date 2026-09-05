### Step 1 — Check the Git credential manager

Run:

```bash
git config --global credential.helper
```

If it returns:

```text
manager
```

or:

```text
manager-core
```

that's good.

### Step 2 — Remove the old GitHub credential

Run:

```bash
printf "protocol=https\nhost=github.com\n\n" | git credential reject
```

This tells Git to forget the saved GitHub HTTPS credential.

### Step 3 — Push again

Run:

```bash
git push origin main
```

Git should ask you to authenticate.

If a browser/login window appears, **sign in with the GitHub account `venkata-369`**, because that account owns:

```text
https://github.com/venkata-369/cockroachdb-gcp-terraform
```

Do **not** use `venkat-mr369`.

---

### If Git asks for Username and Password

Use:

```text
Username:
venkata-369
```

For the password, **do not enter your GitHub password**. GitHub requires a **Personal Access Token (PAT)** for HTTPS Git authentication.

If that happens, stop there and tell me what Git displays. I'll give you the exact GitHub steps to create/use the token.

### Important

Don't change your remote URL. This is already correct:

```bash
https://github.com/venkata-369/cockroachdb-gcp-terraform.git
```

And your commit is already created:

```text
7490e8c Add GCP authentication test
```

So we are only fixing the authentication used by `git push`.

**First run these two commands:**

```bash
git config --global credential.helper
```

then:

```bash
printf "protocol=https\nhost=github.com\n\n" | git credential reject
```

Then run:

```bash
git push origin main
```

Send me exactly what you get from `git push origin main`.


```
nano .gitignore
/docs/

/.terraform/
*.tfstate
*.tfstate.*
*.tfvars
*.tfvars.json
*.json
```
CTL + O = Save
Enter
CTL + X = Exit 

```
git add .gitignore
git commit -m "Ignore Terraform local files"
```
