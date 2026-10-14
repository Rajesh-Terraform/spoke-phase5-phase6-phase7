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

`.github/workflows/terraform.yml` runs `fmt`, `init`, and `validate` for all phases on pushes and pull requests. Pushes to `main` also run an AWS-authenticated, read-only Terraform plan. Pull requests do not access AWS or create resources. To apply changes, manually dispatch **Terraform** from the GitHub Actions tab and select `apply`. An apply runs as three ordered stages: phase 5 VPC/subnets, phase 6 internet/NAT routing, then phase 7 hub peering when enabled. It finishes by planning the complete configuration. Phase-specific targeting is used for staged apply; Terraform can report that targeted operations may leave other changes unapplied, so review the final full plan.

Configure these repository secrets:

- `AWS_ROLE_ARN`: IAM role for GitHub Actions to assume using GitHub OIDC. Restrict its trust policy to this repository and grant only the Terraform permissions needed.
- `TF_STATE_BUCKET`: existing, versioned S3 bucket for Terraform state.
- `TF_STATE_LOCK_TABLE`: existing DynamoDB table with a string partition key named `LockID`.

Configure the repository variable `AWS_REGION` (for example, `us-east-1`). For a non-default GitHub Actions configuration, set optional repository variables `TF_VAR_PROJECT_NAME`, `TF_VAR_VPC_CIDR_BLOCK`, `TF_VAR_AVAILABILITY_ZONES`, `TF_VAR_PUBLIC_SUBNET_CIDRS`, and `TF_VAR_PRIVATE_SUBNET_CIDRS`. List values must be JSON arrays, such as `["us-east-1a","us-east-1b"]`. To enable phase 7 in Actions, set `TF_VAR_HUB_PEERING` to a JSON object, for example `{"enabled":true,"vpc_id":"vpc-0123456789abcdef0","cidr_block":"10.0.0.0/16","route_table_ids":["rtb-0123456789abcdef0"]}`. Configure the workflow's `terraform` GitHub Environment with required reviewers if applies need approval. Applies are allowed only from the `main` branch. The workflow uses one remote state file for this root.

The IAM role must trust GitHub's OIDC provider and allow access to the configured state bucket and lock table, in addition to the permissions required by the AWS resources. Do not store AWS access keys in GitHub.

## Outputs

Terraform outputs include the spoke VPC ID, public/private subnet IDs, route table IDs, NAT gateway ID, and (when enabled) the VPC peering connection ID.
