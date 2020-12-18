# https://www.thapaliya.com/en/writings/well-documented-makefiles/

.DEFAULT_GOAL:=help
SHELL:=/bin/bash

# ******************************************************************
##@ Development

dev: ## Run docker-compose
	docker-compose -f ./docker-compose.yml up --build

test-api:
	cd ./containers/api/app && SECRET_KEY=pytest ENVIRONMENT=pytest DEBUG=1 poetry run pytest tests/

git-hooks: ## Set git hooks path to ./hooks
	git config core.hooksPath ./hooks

# ******************************************************************
##@ Manual Terragrunt Operations

# Variables
account := main
aws_region := eu-west-1
environment := stage
app_services := frontend,api

# Constants
tfi := ./terraform/infrastructure

init: ## Run terragrunt init
	cd ${tfi}/${account}/${aws_region}/${environment}/services/app && terragrunt init
	cd ${tfi}/${account}/${aws_region}/${environment}/services/app && for service in $(shell echo ${app_services} | sed "s/,/ /g"); do \
		terragrunt apply -target=aws_ecr_repository.$$service -auto-approve ; \
	done
apply: ## Run terragrunt apply
	cd ${tfi}/${account}/${aws_region}/${environment}/services/app && terragrunt apply
destroy: ## Run terragrunt destroy
	cd ${tfi}/${account}/${aws_region}/${environment}/services/app && terragrunt destroy
push-images: ## Build and push images to ECR
	sh ./scripts/manual_push_images_to_ecr.sh ${account} ${aws_region} ${environment} ${app_services}

# ******************************************************************
##@ Helpers

.PHONY: help

help:  ## Display this help
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m\033[0m\n"} /^[a-zA-Z_-]+:.*?##/ { printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' $(MAKEFILE_LIST)
