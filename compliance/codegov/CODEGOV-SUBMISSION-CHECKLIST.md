# Code.gov Submission Checklist

Use this checklist before publishing inventory metadata and open-source release information.

## Required Preparation

- Confirm repository has an approved open-source license.
- Confirm public repository URL and release/archive URL are valid.
- Populate and review `/Users/caseycook/Desktop/Work Source Code/databricks-lambda-restapi-terraform/compliance/codegov/code.json.template` for agency values.
- Ensure fields align with current Code.gov schema and agency OCIO guidance.
- Ensure points of contact (`contact.name`, `contact.email`) are staffed.

## Reuse and Security Quality Gates

- Architecture and compliance diagrams in README are current.
- NIST mapping reflects actual control implementations.
- SBOM exists and validates (`python3 compliance/sbom/validate_sbom.py`).
- CI checks pass (`scripts/run-ci-local.sh`).
- Sensitive values are not committed in metadata or docs.

## Publication and Maintenance

- Submit/update agency enterprise code inventory process for Code.gov publication.
- Set quarterly review cadence for:
  - metadata freshness
  - dependency/SBOM refresh
  - compliance control mapping updates
- Record last submission date in change log or release notes.
