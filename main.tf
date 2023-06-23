# Enabling AWS Organization
resource "aws_organizations_organization" "caylien" {
  aws_service_access_principals = [
    "cloudtrail.amazonaws.com",
    "config.amazonaws.com",
  ]

  feature_set = "ALL"
  enabled_policy_types = ["SERVICE_CONTROL_POLICY"]
}

# OUs
resource "aws_organizations_organizational_unit" "caylien_dev" {
  name      = "dev"
  parent_id = aws_organizations_organization.caylien.roots[0].id
}

resource "aws_organizations_organizational_unit" "caylien_prod" {
  name      = "prod"
  parent_id = aws_organizations_organization.caylien.roots[0].id
}

# AWS Accounts
resource "aws_organizations_account" "caylient_dev" {
  name      = "ACCOUNT-DEV"
  email     = "ej.zxc1992+accountdev@gmail.com"
  role_name = "OrganizationAccountAccessRole"
  parent_id = aws_organizations_organization.caylien.roots[0].id
  close_on_deletion = true
}

resource "aws_organizations_account" "caylien_prod" {
  name      = "ACCOUNT-PROD"
  email     = "ej.zxc1992+accountprod@gmail.com"
  role_name = "OrganizationAccountAccessRole"
  parent_id = aws_organizations_organization.caylien.roots[0].id
  close_on_deletion = true
}

# SCP
data "aws_iam_policy_document" "scp_statement" {
  statement {
    sid       = "AllowCreateResourcesInUSEast1"
    effect    = "Deny"
    actions   = ["*"]
    resources = ["*"]

    condition {
      test     = "StringNotEquals"
      variable = "aws:RequestedRegion"
      values   = ["us-east-1"]
    }
  }

  statement {
    sid       = "DenyCreatePublicS3Buckets"
    effect    = "Deny"
    actions   = ["s3:PutBucketAcl"]
    resources = ["*"]

    condition {
      test     = "Null"
      variable = "s3:x-amz-acl"
      values   = ["false"]
    }
  }

  statement {
    sid       = "AllowDeleteS3Buckets"
    effect    = "Allow"
    actions   = ["s3:DeleteBucket"]
    resources = ["*"]
  }
}

resource "aws_organizations_policy" "scp" {
  name    = "DenyPolicies"
  content = data.aws_iam_policy_document.scp_statement.json
  
  depends_on = [
    aws_organizations_organization.caylien
  ]
}

resource "aws_organizations_policy_attachment" "dev_ou_policy_attach" {
  policy_id = aws_organizations_policy.scp.id
  target_id = aws_organizations_organizational_unit.caylien_dev.id
}

resource "aws_organizations_policy_attachment" "prod_ou_policy_attach" {
  policy_id = aws_organizations_policy.scp.id
  target_id = aws_organizations_organizational_unit.caylien_prod.id
}