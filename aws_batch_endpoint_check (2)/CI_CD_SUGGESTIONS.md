# Deployment & CI/CD Suggestions

## 🔐 GitHub OIDC Role Setup

To securely deploy from GitHub Actions to AWS using OpenID Connect:

1. In AWS IAM, create an IAM role with a trust policy for GitHub:
   - Trusted entity: `sts.amazonaws.com`
   - Add the following condition to limit access:
     ```json
     "Condition": {
       "StringLike": {
         "token.actions.githubusercontent.com:sub": "repo:<your-org>/<your-repo>:ref:refs/heads/main"
       }
     }
     ```

2. Attach necessary policies (ECR push, Terraform infra apply):
   - `AmazonEC2ContainerRegistryFullAccess`
   - `AmazonS3FullAccess`
   - `SecretsManagerReadWrite`
   - `AmazonSNSFullAccess`
   - `AWSBatchFullAccess`

3. Add the Role ARN to your GitHub repo secrets:
   - `AWS_ROLE_TO_ASSUME`

## 🧪 Multi-Env Setup (staging/prod)

- Use Terraform workspaces or directory structure for `staging` vs `prod`
- Add a condition in GitHub Actions:
  ```yaml
  if: github.ref == 'refs/heads/prod'
  ```

## ✅ Manual Approvals

Add a manual approval step before `terraform apply`:

```yaml
- name: Wait for approval
  uses: hmarr/auto-approve-action@v3
  with:
    github-token: \${{ secrets.GITHUB_TOKEN }}
```

Or for manual review:

```yaml
- name: Request manual approval
  uses: trstringer/manual-approval@v1
  with:
    secret: \${{ secrets.GITHUB_TOKEN }}
```

## 📁 Sample terraform.tfvars

You can define a `terraform.tfvars` file with overrides if you modularize later.

```hcl
s3_bucket     = "my-batch-bucket"
userid        = "my_user"
password      = "super_secret"
endpoint_urls = "https://example.com/api"
```

Let me know if you want to modularize this codebase too!
