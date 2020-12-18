variable "aws_region" {
  description = "The AWS region to use."
}

variable "aws_account_id" {
  description = "The AWS account ID to use."
}

variable "app_name" {
  description = "The name of the app."
}

variable "environment" {
  description = "The environment of the app deployment."
}

variable "app_domain_name" {
  description = "The domain name of the load balancer to create certificates for."
}

variable "route53_hosted_zone_name" {
  description = "The name of the Route 53 hosted zone."
}

variable "use_existing_route53_hosted_zone" {
  description = "Set to true if the hosted zone already exists in Route 53 (i.e., manually created)."
}

variable "github_sha" {
  description = "The GitHub commit SHA that triggered the workflow. Is set randomly for manual deployment via Makefile and helper script. In GitHub Actions workflows, this value is automatically set by 'github.sha'."
}

variable "service_configuration" {
  description = "An object of configuration options for all services."

  type = object({
    frontend = object({
      url_prefix = string,
      environment = list(object({
        name  = string
        value = string
      })),
      secrets = list(object({
        name      = string
        valueFrom = string
      })),
    })
    api = object({
      url_prefix = string,
      environment = list(object({
        name  = string
        value = string
      })),
      secrets = list(object({
        name      = string
        valueFrom = string
      })),
    })
  })
}
