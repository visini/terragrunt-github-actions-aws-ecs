#!/bin/bash

account=$1
region=$2
environment=$3
services=$4

# Note: Don't use implicit values from aws profile - always specify which account, which region etc.
# aws_account_id=$(aws sts get-caller-identity --output json | jq -r '.Account')
# aws_region=$(aws configure get region)

tf="./terraform"
tfi="$tf/infrastructure"

common_terragrunt_file="$tf/common.terragrunt.hcl"
account_terragrunt_file="$tfi/$account/account.terragrunt.hcl"
region_terragrunt_file="$tfi/$account/$region/region.terragrunt.hcl"

app_name=$(cat $common_terragrunt_file | hclq get ".locals.app_name" | tr -d '"')
#github_sha=$(cat $common_terragrunt_file | hclq get ".locals.github_sha"| tr -d '"')
github_sha=manual_$(openssl rand -hex 6)_$(date -u +%Y%m%dT%H%M%S) # Add random string and UTC date
aws_account_id=$(cat $account_terragrunt_file | hclq get ".locals.aws_account_id" | tr -d '"')
aws_region=$(cat $region_terragrunt_file | hclq get ".locals.aws_region" | tr -d '"')

aws ecr get-login-password --region $aws_region | docker login --username AWS --password-stdin $aws_account_id.dkr.ecr.$aws_region.amazonaws.com


for service in $(echo $services | sed "s/,/ /g"); do
    echo "Pushing image for $service"
    service_img=$app_name-$environment-$service:$github_sha
    cd ./containers/$service && docker build -t $service_img .
    docker tag $service_img $aws_account_id.dkr.ecr.$aws_region.amazonaws.com/$service_img
    docker push $aws_account_id.dkr.ecr.$aws_region.amazonaws.com/$service_img
    cd ../../
done