#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${ROOT_DIR}"

TF_ENV="${TF_ENV:-dev}"
AWS_REGION="${AWS_REGION:-us-east-1}"
WORKDIR="envs/${TF_ENV}"

if ! command -v terraform >/dev/null 2>&1; then
  echo "ERROR: terraform is required." >&2
  exit 2
fi

if ! command -v aws >/dev/null 2>&1; then
  echo "ERROR: aws CLI is required." >&2
  exit 2
fi

if ! command -v jq >/dev/null 2>&1; then
  echo "ERROR: jq is required." >&2
  exit 2
fi

if [[ ! -d "${WORKDIR}" ]]; then
  echo "ERROR: environment directory not found: ${WORKDIR}" >&2
  exit 2
fi

echo "Using TF_ENV=${TF_ENV}, AWS_REGION=${AWS_REGION}"
aws sts get-caller-identity >/dev/null

terraform -chdir="${WORKDIR}" fmt -check -recursive
terraform -chdir="${WORKDIR}" init -input=false
terraform -chdir="${WORKDIR}" validate
terraform -chdir="${WORKDIR}" plan -no-color -out=tfplan

echo "SUCCESS: Local terraform workflow parity checks passed for ${TF_ENV}."
