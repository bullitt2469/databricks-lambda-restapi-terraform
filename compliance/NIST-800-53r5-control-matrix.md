# NIST SP 800-53 Rev. 5 Control Matrix (Terraform Implementation)

This matrix maps implemented controls in this repository to NIST SP 800-53 Rev. 5.

Scope:
- Workload: AWS API Gateway + AWS Lambda + AWS Secrets Manager + CloudWatch Logs + KMS + AWS Config + Security Hub + SBOM artifacts
- Baseline target: Moderate-impact federal systems (tailor to agency overlays)
- Responsibility model: shared between IaC implementation and agency governance/operations

## Implementation and Validation Mapping

| Control | Terraform / Config Implementation | Validation Evidence (Post-Deploy) | Responsibility |
|---|---|---|---|
| AC-3 Access Enforcement | Least-privilege Lambda IAM policy scoped to one secret; optional IAM permissions boundaries | `aws iam get-role`, `aws iam list-attached-role-policies`, script checks | Shared |
| AC-6 Least Privilege | Lambda only granted `secretsmanager:GetSecretValue` and key decrypt permissions when needed | Script captures IAM role/policy docs and evaluates scope | Shared |
| AU-2 Event Logging | API Gateway access logs enabled with structured JSON fields; Lambda logs in CloudWatch | `aws apigateway get-stage`, `aws logs describe-log-groups` | Implemented in code |
| AU-3 Content of Audit Records | Access log format includes principal request attributes and errors | Stage `accessLogSettings.format` evidence | Implemented in code |
| AU-12 Audit Record Generation | Method settings enforce metrics and execution logging (when enabled) | Stage method settings evidence | Shared |
| AU-11 Audit Record Retention | Configurable retention for Lambda and API access logs | Log-group retention evidence | Implemented in code |
| CA-7 Continuous Monitoring | AWS Config recorder and delivery channel are deployed and enabled | `aws configservice describe-configuration-recorder-status` + validation script checks | Shared |
| CM-2 Baseline Configuration | Versioned Terraform module/env roots define baseline controls and parameters | Git history + Terraform plan/apply artifacts | Shared |
| CM-6 Configuration Settings | Default federal-focused settings: customer KMS, tracing, log retention, required tags | Terraform variable values + script checks | Shared |
| CM-8 System Component Inventory | CycloneDX SBOM inventories application and IaC dependencies | `compliance/sbom/sbom.cyclonedx.json` + SBOM validation script | Shared |
| IA-5 Authenticator Management | Databricks PAT stored in Secrets Manager and not hard-coded in Lambda | `aws secretsmanager describe-secret` + source review | Shared |
| RA-5 Vulnerability Monitoring | Security Hub findings and SBOM-supported dependency visibility for vulnerability intake | `aws securityhub get-enabled-standards`, SBOM evidence | Shared |
| SA-22 Unsupported System Components | SBOM process identifies third-party components and enables supportability review in release workflow | SBOM review in CI and change control records | Shared |
| SC-12 Cryptographic Key Establishment | Optional customer-managed KMS key with rotation enabled | `aws kms get-key-rotation-status` | Implemented in code |
| SC-13 Cryptographic Protection | KMS encryption at rest for secret, Lambda env vars, and log groups | Lambda/log/secret KMS checks in script | Implemented in code |
| SC-28 Protection of Information at Rest | Secret and logs encrypted at rest via KMS; Lambda env vars KMS-encrypted | Resource configuration evidence | Implemented in code |
| SI-4 System Monitoring | API and Lambda telemetry sent to CloudWatch; X-Ray tracing enabled by default | Stage/Lambda tracing evidence | Shared |
| SI-7 Software, Firmware, and Information Integrity | SBOM validation gate ensures integrity of required dependency metadata before merge | CI logs from SBOM validation step | Shared |
| PM-5 System Inventory | Required tags enforce consistent asset metadata | Resource tags evidence | Shared |

## Tailoring Notes for Federal Adoption

- Define and enforce an agency-specific tag taxonomy via `required_tag_keys`.
- Restrict `cors_allow_origins` to approved federal domains. Wildcard origins are blocked when `federal_compliance_mode = true`.
- Integrate this module with organizational services for:
  - AWS Config conformance packs
  - Security Hub controls
  - centralized SIEM/SOAR
  - incident response workflows
- Include SBOM review in ATO package evidence and POA&M workflows.
- Consider adding network boundary controls (VPC integration, private endpoints, WAF) based on AO requirements.

## Evidence Collection

Use the validation script:

```bash
cd envs/dev
../../compliance/validation/validate_federal_baseline.sh
```

The script writes an evidence bundle to `compliance/validation/evidence/<timestamp>/` and returns non-zero on failed checks.

SBOM evidence and policy mapping:

- `/Users/caseycook/Desktop/Work Source Code/databricks-lambda-restapi-terraform/compliance/sbom/sbom.cyclonedx.json`
- `/Users/caseycook/Desktop/Work Source Code/databricks-lambda-restapi-terraform/compliance/sbom/SBOM-MINIMUM-ELEMENTS-MAPPING.md`
