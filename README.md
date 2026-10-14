# AWS spoke network - phases 5, 6, and 7

This repository contains a single Terraform root that deploys the phases together, with a reusable Terraform module for each phase:

| Phase | Module | Resources |
| --- | --- | --- |
| 5 | `modules/phase5-vpc` | Spoke VPC and public/private subnets |
| 6 | `modules/phase6-routing` | Internet gateway, one NAT gateway, and public/private routing |
| 7 | `modules/phase7-hub-peering` | Optional VPC peering and routes to an existing hub VPC |

Phase 7 is disabled by default. The default configuration creates a new spoke VPC in `us-east-1` with two public and two private subnets. The single NAT gateway is a cost-saving development setup; it is not a highly available production design.

## Run locally

Requirements: Terraform 1.2 or newer and AWS credentials with permission to manage the resources in these phases.

Create an S3 bucket for state and a DynamoDB lock table first. The table must have a string partition key named `LockID`. Then initialize the backend with their names:

```powershell
Copy-Item terraform.tfvars.example terraform.tfvars
terraform init `
  -backend-config="bucket=<state-bucket-name>" `
  -backend-config="key=spoke-phase5-phase6-phase7/terraform.tfstate" `
  -backend-config="region=us-east-1" `
  -backend-config="dynamodb_table=<lock-table-name>" `
  -backend-config="encrypt=true"
terraform fmt -check -recursive
terraform validate
terraform plan
terraform apply
```

Review the plan before applying. To enable phase 7, set these values in `terraform.tfvars`:

```hcl
hub_peering = {
  enabled         = true
  vpc_id          = "vpc-0123456789abcdef0"
  cidr_block      = "10.0.0.0/16"
  route_table_ids = ["rtb-0123456789abcdef0"]
}
```

Peering is configured for VPCs in the same AWS account and region. Supply the hub route table IDs so the hub has return routes to the spoke. CIDR ranges must not overlap. For cross-account or cross-region peering, add an accepter workflow/provider and acceptance step before using this configuration.

## GitHub Actions

`.github/workflows/terraform.yml` runs formatting checks, initialization, and validation on pushes and pull requests without AWS credentials. AWS deployment is a separate manual workflow, `.github/workflows/apply-phases.yml`, so validation runs do not show a skipped deployment job. To deploy, open **Actions → Apply phases 5, 6, and 7 → Run workflow**, select branch `main`, then choose `apply`. Choose `plan` for a read-only plan. Deployment requires the AWS role and remote state secrets below. An apply runs in order: phase 5 VPC/subnets, phase 6 internet/NAT routing, then phase 7 hub peering when enabled, followed by a full Terraform plan. Review the final plan; Terraform warns that staged targeted operations can leave other changes unapplied.

Configure `AWS_ROLE_ARN` in **Settings → Secrets and variables → Actions** as a secret or variable. The workflow automatically creates an encrypted, versioned S3 state bucket and a DynamoDB lock table in the spoke account if you do not provide existing backend names. You may optionally set `TF_STATE_BUCKET` and `TF_STATE_LOCK_TABLE` as repository/environment secrets or variables to use existing backend resources:

- `AWS_ROLE_ARN`: IAM role for GitHub Actions to assume using GitHub OIDC. Restrict its trust policy to this repository and grant Terraform permissions plus permissions to create/inspect/configure the S3 state bucket and DynamoDB lock table if the workflow creates them.
- `TF_STATE_BUCKET` (optional): name of an existing S3 bucket for state.
- `TF_STATE_LOCK_TABLE` (optional): name of an existing DynamoDB table with a string partition key named `LockID`.

For OIDC authentication, create the GitHub OIDC identity provider in AWS IAM with provider URL `https://token.actions.githubusercontent.com` and audience `sts.amazonaws.com`. The IAM role referenced by `AWS_ROLE_ARN` must trust that provider. Because the deploy job uses the GitHub Environment named `terraform`, its OIDC subject is the environment subject below; a trust policy restricted only to `ref:refs/heads/main` will not match:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::<AWS_ACCOUNT_ID>:oidc-provider/token.actions.githubusercontent.com"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "token.actions.githubusercontent.com:aud": "sts.amazonaws.com",
          "token.actions.githubusercontent.com:sub": "repo:Rajesh-Terraform/spoke-phase5-phase6-phase7:environment:terraform"
        }
      }
    }
  ]
}
```

Replace `<AWS_ACCOUNT_ID>` with your AWS account ID. Set `AWS_ROLE_ARN` to the full ARN of this role, and ensure the role also has permissions for the S3 state bucket, DynamoDB lock table, and Terraform-managed VPC resources. If using environment-scoped values, create them in the `terraform` environment because the deploy job targets that environment.

Configure the repository variable `AWS_REGION` (for example, `us-east-1`). For a non-default GitHub Actions configuration, set optional repository variables `TF_VAR_PROJECT_NAME`, `TF_VAR_VPC_CIDR_BLOCK`, `TF_VAR_AVAILABILITY_ZONES`, `TF_VAR_PUBLIC_SUBNET_CIDRS`, and `TF_VAR_PRIVATE_SUBNET_CIDRS`. List values must be JSON arrays, such as `["us-east-1a","us-east-1b"]`. To enable phase 7 in Actions, set `TF_VAR_HUB_PEERING` to a JSON object, for example `{"enabled":true,"vpc_id":"vpc-0123456789abcdef0","cidr_block":"10.0.0.0/16","route_table_ids":["rtb-0123456789abcdef0"]}`. Configure the workflow's `terraform` GitHub Environment with required reviewers if applies need approval. Applies are allowed only from the `main` branch. The workflow uses one remote state file for this root.

The IAM role must trust GitHub's OIDC provider and allow access to the state bucket and lock table, in addition to the permissions required by the AWS resources. Creating the backend requires S3 bucket create/configuration and DynamoDB table create/describe permissions. By default, the workflow names the bucket `spoke-phase567-tfstate-<account-id>-<region>` and the table `spoke-phase567-tf-lock`. These AWS resources may incur charges. Do not store AWS access keys in GitHub.

## Outputs

Terraform outputs include the spoke VPC ID, public/private subnet IDs, route table IDs, NAT gateway ID, and (when enabled) the VPC peering connection ID.
