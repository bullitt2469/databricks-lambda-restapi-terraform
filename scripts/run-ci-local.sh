#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${ROOT_DIR}"

if ! command -v python3 >/dev/null 2>&1; then
  echo "ERROR: python3 is required." >&2
  exit 2
fi

if ! command -v terraform >/dev/null 2>&1; then
  echo "ERROR: terraform is required for local CI parity checks." >&2
  exit 2
fi

echo "[1/6] SBOM validation"
python3 compliance/sbom/validate_sbom.py

echo "[2/6] Code.gov metadata validation"
python3 compliance/codegov/validate_codegov_metadata.py

echo "[3/6] Terraform fmt check"
terraform fmt -check -recursive

echo "[4/6] Terraform init/validate (backend=false)"
for d in modules envs/dev envs/prod; do
  if [[ -d "$d" ]]; then
    echo "  - $d"
    terraform -chdir="$d" init -backend=false -input=false >/dev/null
    terraform -chdir="$d" validate
  fi
done

echo "[5/6] Python test dependencies"
python3 -m pip install --quiet --disable-pip-version-check -r requirements-dev.txt

echo "[6/6] Pytest"
python3 -m pytest -q

echo "SUCCESS: Local CI checks passed."
