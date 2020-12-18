# terragrunt-github-actions-aws-ecs

This project leverages [Terragrunt](https://github.com/gruntwork-io/terragrunt), [Terraform](https://www.terraform.io/), and [GitHub Actions](https://github.com/features/actions) to deploy a basic web app (dockerized JS frontend and dockerized Python API) to [AWS ECS](https://aws.amazon.com/ecs/).

See this article for more information: [https://camillovisini.com/article/terragrunt-github-actions-aws-ecs/](https://camillovisini.com/article/terragrunt-github-actions-aws-ecs/)

## GitHub Secrets

Ensure the following secrets are provided in the repository settings:

```bash
AWS_ACCESS_KEY_ID
AWS_SECRET_ACCESS_KEY
AWS_REGION
```

## Makefile Targets

```bash
~/terragrunt-ecs$ make

Usage:
  make

Development
  dev              Run docker-compose
  git-hooks        Set git hooks path to ./hooks

Manual Terragrunt Operations
  init             Run terragrunt init
  apply            Run terragrunt apply
  destroy          Run terragrunt destroy
  push-images      Build and push images to ECR

Helpers
  help             Display this help
```

## Workflow

### Development

```bash
# make git-hooks
make dev
```

### Initialization

```bash
make init
make push-images
```

Subsequent push to branch will trigger deployment via GitHub Actions:

- Branch `dev` will deploy to `stage` environment
- Branch `main` will deploy to `prod` environment

### Manual apply / destroy

Besides GitHub Actions, deployments can be managed manually. Configure additional Makefile targets to manually manage deployments as your application scales across environments, regions, accounts, or includes additional services or data providers. For this repository, common targets are listed below.

Change infrastructure:

```bash
# after changes in ./terraform/*
make apply
```

Change codebase and deploy to infrastructure:

```bash
# after changes in ./containers/*
make push-images
make apply
```

Destroy infrastructure:

```bash
# after infrastructure is no longer required
make destroy
```
