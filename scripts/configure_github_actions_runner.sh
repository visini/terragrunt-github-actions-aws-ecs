#!/bin/bash

# This script configures a local GitHub Actions runner via Docker

read -p "Enter GitHub repo in format user/repo: " USER_REPO
echo "get token from https://github.com/$USER_REPO > Settings > Actions > Add self-hosted runner"
USER_REPO_CLEAN=$(echo $USER_REPO | sed -e 's/\//-/g')
RUNNER_NAME="github_actions_runner_for_$USER_REPO"
read -p "Enter token: " TOKEN
docker run -d --restart always --name "github-runner-$USER_REPO_CLEAN" \
  -e REPO_URL="https://github.com/$USER_REPO" \
  -e RUNNER_NAME="$USER_REPO_CLEAN" \
  -e RUNNER_TOKEN="$TOKEN" \
  -e RUNNER_WORKDIR="/tmp/$USER_REPO_CLEAN" \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v /tmp/$USER_REPO_CLEAN:/tmp/$USER_REPO_CLEAN \
  myoung34/github-runner:latest
