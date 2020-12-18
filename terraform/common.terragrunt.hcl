# Set common variables for the project. This is automatically pulled in in the root terragrunt.hcl configuration to
# feed forward to the child modules.

locals {
    app_name = "example-app"
    app_domain_name = "app.example.com"
    route53_hosted_zone_name = "example.com"
    use_existing_route53_hosted_zone = true
    github_sha = "will_be_automatically_set_by_github_actions_or_manual_script"
}