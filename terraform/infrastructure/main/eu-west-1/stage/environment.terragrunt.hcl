# Set common variables for the environment. This is automatically pulled in in the root terragrunt.hcl configuration to
# feed forward to the child modules.
locals {
    common = read_terragrunt_config(find_in_parent_folders("common.terragrunt.hcl"))
    account = read_terragrunt_config(find_in_parent_folders("account.terragrunt.hcl"))
    region = read_terragrunt_config(find_in_parent_folders("region.terragrunt.hcl"))

    # Configure environment
    environment = "stage"
    app_domain_name = "stage.${local.common.locals.app_domain_name}"

    app_name = local.common.locals.app_name
    aws_account_id = local.account.locals.aws_account_id
    aws_region = local.region.locals.aws_region

    parameter_group = "${local.app_name}/${local.environment}"

    service_configuration = {
        for service in ["frontend", "api"]:
            service => {
                url_prefix = service == "frontend" ? "" : format("%s/",service)
                environment = concat([
                    for key, value in jsondecode(file(".${service}.environment.json")):
                        {
                            "name": key,
                            "value": value["value"]
                        }
                    ], [
                        {
                            "name": "ENVIRONMENT",
                            "value": local.environment
                        },
                        {
                            "name": "APP_DOMAIN_NAME",
                            "value": local.app_domain_name
                        },
                    ])
                secrets = concat([
                    for key, value in jsondecode(file(".${service}.secrets.json")): 
                            {
                                "name": key,
                                "valueFrom": "arn:aws:ssm:${local.aws_region}:${local.aws_account_id}:parameter/${local.parameter_group}/${service}/secrets/${key}"
                            }
                            if lookup(value, "alias", false) == false
                    ])
            }
    }
}
