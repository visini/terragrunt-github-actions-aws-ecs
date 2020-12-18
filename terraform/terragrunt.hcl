# ---------------------------------------------------------------------------------------------------------------------
# TERRAGRUNT CONFIGURATION
# Terragrunt is a thin wrapper for Terraform that provides extra tools for working with multiple Terraform modules,
# remote state, and locking: https://github.com/gruntwork-io/terragrunt
# ---------------------------------------------------------------------------------------------------------------------

locals {
  common = read_terragrunt_config(find_in_parent_folders("common.terragrunt.hcl"))
  account = read_terragrunt_config(find_in_parent_folders("account.terragrunt.hcl"))
  region = read_terragrunt_config(find_in_parent_folders("region.terragrunt.hcl"))
  environment = read_terragrunt_config(find_in_parent_folders("environment.terragrunt.hcl"))
}

remote_state {
  backend = "s3"
  config = {
    encrypt         = true
    region          = local.region.locals.aws_region
    bucket          = "terraform-state-${local.common.locals.app_name}-${local.account.locals.aws_account_id}"
    key             = "${path_relative_to_include()}/terraform.tfstate"
    dynamodb_table  = "terraform-locks-${local.common.locals.app_name}-${local.account.locals.aws_account_id}"
  }
}

# Generate an AWS provider block
generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
provider "aws" {
  region = "${local.region.locals.aws_region}"
  # Only these AWS Account IDs may be operated on by this template
  allowed_account_ids = ["${local.account.locals.aws_account_id}"]
}
EOF
}

# ---------------------------------------------------------------------------------------------------------------------
# GLOBAL PARAMETERS
# These variables apply to all configurations in this subfolder. These are automatically merged into the child
# `terragrunt.hcl` config via the include block.
# ---------------------------------------------------------------------------------------------------------------------

inputs = merge(
  local.common.locals,
  local.account.locals,
  local.region.locals,
  local.environment.locals
)
