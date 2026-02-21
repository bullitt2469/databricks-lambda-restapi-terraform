#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${ROOT_DIR}"

git config core.hooksPath .githooks
chmod +x .githooks/pre-commit scripts/run-ci-local.sh scripts/run-terraform-workflow-local.sh

echo "Configured git hooks path to .githooks"
echo "Pre-commit hook installed. Commits will run local CI checks."
