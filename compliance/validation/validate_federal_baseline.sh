#!/usr/bin/env bash
set -euo pipefail

if ! command -v aws >/dev/null 2>&1; then
  echo "ERROR: aws CLI is required." >&2
  exit 2
fi

if ! command -v terraform >/dev/null 2>&1; then
  echo "ERROR: terraform CLI is required." >&2
  exit 2
fi

if ! command -v jq >/dev/null 2>&1; then
  echo "ERROR: jq is required." >&2
  exit 2
fi

ENV_DIR="${1:-.}"
OUTPUT_ROOT="${2:-../../compliance/validation/evidence}"
TIMESTAMP="$(date -u +%Y%m%dT%H%M%SZ)"
OUTPUT_DIR="${OUTPUT_ROOT}/${TIMESTAMP}"

mkdir -p "${OUTPUT_DIR}"

pushd "${ENV_DIR}" >/dev/null

terraform output -json > "${OUTPUT_DIR}/terraform-outputs.json"

API_ID="$(jq -r '.api_gateway_rest_api_id.value' "${OUTPUT_DIR}/terraform-outputs.json")"
STAGE_NAME="$(jq -r '.api_gateway_stage_name.value' "${OUTPUT_DIR}/terraform-outputs.json")"
LAMBDA_NAME="$(jq -r '.lambda_name.value' "${OUTPUT_DIR}/terraform-outputs.json")"
LAMBDA_LOG_GROUP="$(jq -r '.lambda_log_group_name.value' "${OUTPUT_DIR}/terraform-outputs.json")"
API_ACCESS_LOG_GROUP="$(jq -r '.api_access_log_group_name.value' "${OUTPUT_DIR}/terraform-outputs.json")"
SECRET_ARN="$(jq -r '.databricks_pat_secret_arn.value' "${OUTPUT_DIR}/terraform-outputs.json")"
KMS_KEY_ARN="$(jq -r '.kms_key_arn.value // empty' "${OUTPUT_DIR}/terraform-outputs.json")"
CONFIG_RECORDER_NAME="$(jq -r '.config_configuration_recorder_name.value // empty' "${OUTPUT_DIR}/terraform-outputs.json")"
SECURITY_HUB_ENABLED_EXPECTED="$(jq -r '.security_hub_enabled.value // false' "${OUTPUT_DIR}/terraform-outputs.json")"
SECURITY_HUB_STANDARD_ARN="$(jq -r '.security_hub_foundational_standard_subscription_arn.value // empty' "${OUTPUT_DIR}/terraform-outputs.json")"

REGION="$(aws configure get region || true)"
if [[ -z "${REGION}" || "${REGION}" == "None" ]]; then
  REGION="us-east-1"
fi

aws lambda get-function-configuration --function-name "${LAMBDA_NAME}" > "${OUTPUT_DIR}/lambda-function-configuration.json"
aws apigateway get-stage --rest-api-id "${API_ID}" --stage-name "${STAGE_NAME}" > "${OUTPUT_DIR}/api-gateway-stage.json"
aws logs describe-log-groups --log-group-name-prefix "${LAMBDA_LOG_GROUP}" > "${OUTPUT_DIR}/lambda-log-group.json"
aws logs describe-log-groups --log-group-name-prefix "${API_ACCESS_LOG_GROUP}" > "${OUTPUT_DIR}/api-access-log-group.json"
aws secretsmanager describe-secret --secret-id "${SECRET_ARN}" > "${OUTPUT_DIR}/secret-description.json"

if [[ -n "${KMS_KEY_ARN}" && "${KMS_KEY_ARN}" != "null" ]]; then
  KEY_ID="${KMS_KEY_ARN##*/}"
  aws kms get-key-rotation-status --key-id "${KEY_ID}" > "${OUTPUT_DIR}/kms-key-rotation-status.json"
fi

if [[ -n "${CONFIG_RECORDER_NAME}" && "${CONFIG_RECORDER_NAME}" != "null" ]]; then
  aws configservice describe-configuration-recorders --configuration-recorder-names "${CONFIG_RECORDER_NAME}" > "${OUTPUT_DIR}/config-recorder.json"
  aws configservice describe-configuration-recorder-status --configuration-recorder-names "${CONFIG_RECORDER_NAME}" > "${OUTPUT_DIR}/config-recorder-status.json"
fi

if [[ "${SECURITY_HUB_ENABLED_EXPECTED}" == "true" ]]; then
  aws securityhub describe-hub > "${OUTPUT_DIR}/security-hub-hub.json"
  aws securityhub get-enabled-standards > "${OUTPUT_DIR}/security-hub-standards.json"
fi

LAMBDA_KMS_OK="$(jq -r '.KMSKeyArn // empty' "${OUTPUT_DIR}/lambda-function-configuration.json")"
LAMBDA_TRACING="$(jq -r '.TracingConfig.Mode // empty' "${OUTPUT_DIR}/lambda-function-configuration.json")"
SECRET_KMS_OK="$(jq -r '.KmsKeyId // empty' "${OUTPUT_DIR}/secret-description.json")"
STAGE_XRAY="$(jq -r '.tracingEnabled' "${OUTPUT_DIR}/api-gateway-stage.json")"
STAGE_ACCESS_LOG_DEST="$(jq -r '.accessLogSettings.destinationArn // empty' "${OUTPUT_DIR}/api-gateway-stage.json")"
STAGE_LOGGING_LEVEL="$(jq -r '.methodSettings."*/*".loggingLevel // empty' "${OUTPUT_DIR}/api-gateway-stage.json")"
STAGE_METRICS="$(jq -r '.methodSettings."*/*".metricsEnabled // false' "${OUTPUT_DIR}/api-gateway-stage.json")"

LAMBDA_LOG_RETENTION="$(jq -r '.logGroups[0].retentionInDays // 0' "${OUTPUT_DIR}/lambda-log-group.json")"
LAMBDA_LOG_KMS="$(jq -r '.logGroups[0].kmsKeyId // empty' "${OUTPUT_DIR}/lambda-log-group.json")"
API_LOG_RETENTION="$(jq -r '.logGroups[0].retentionInDays // 0' "${OUTPUT_DIR}/api-access-log-group.json")"
API_LOG_KMS="$(jq -r '.logGroups[0].kmsKeyId // empty' "${OUTPUT_DIR}/api-access-log-group.json")"
CONFIG_RECORDER_PRESENT="$(jq -r '.ConfigurationRecorders | length' "${OUTPUT_DIR}/config-recorder.json" 2>/dev/null || echo 0)"
CONFIG_RECORDER_RECORDING="$(jq -r '.ConfigurationRecordersStatus[0].recording // false' "${OUTPUT_DIR}/config-recorder-status.json" 2>/dev/null || echo false)"
SECURITY_HUB_HUB_ARN="$(jq -r '.HubArn // empty' "${OUTPUT_DIR}/security-hub-hub.json" 2>/dev/null || echo "")"
SECURITY_HUB_STANDARD_ENABLED="false"
if [[ -n "${SECURITY_HUB_STANDARD_ARN}" && "${SECURITY_HUB_STANDARD_ARN}" != "null" ]]; then
  SECURITY_HUB_STANDARD_ENABLED="$(jq -r --arg target "${SECURITY_HUB_STANDARD_ARN}" '[.StandardsSubscriptions[] | select(.StandardsSubscriptionArn == $target)] | length > 0' "${OUTPUT_DIR}/security-hub-standards.json" 2>/dev/null || echo false)"
fi

PASS=true
REPORT_FILE="${OUTPUT_DIR}/validation-report.txt"

check() {
  local name="$1"
  local expr="$2"
  if eval "${expr}"; then
    echo "PASS: ${name}" | tee -a "${REPORT_FILE}"
  else
    echo "FAIL: ${name}" | tee -a "${REPORT_FILE}"
    PASS=false
  fi
}

: > "${REPORT_FILE}"

echo "Federal baseline validation report (${TIMESTAMP})" | tee -a "${REPORT_FILE}"
echo "Region: ${REGION}" | tee -a "${REPORT_FILE}"
echo "" | tee -a "${REPORT_FILE}"

check "SC-13/SC-28 Lambda uses KMS key" "[[ -n '${LAMBDA_KMS_OK}' ]]"
check "SC-13/SC-28 Secret uses KMS key" "[[ -n '${SECRET_KMS_OK}' ]]"
check "AU-11 Lambda log retention >= 365" "[[ ${LAMBDA_LOG_RETENTION} -ge 365 ]]"
check "AU-11 API access log retention >= 365" "[[ ${API_LOG_RETENTION} -ge 365 ]]"
check "SC-13 Lambda log group encrypted" "[[ -n '${LAMBDA_LOG_KMS}' ]]"
check "SC-13 API access log group encrypted" "[[ -n '${API_LOG_KMS}' ]]"
check "AU-2/AU-3 API access logging enabled" "[[ -n '${STAGE_ACCESS_LOG_DEST}' ]]"
check "AU-12 API execution logging level enabled" "[[ '${STAGE_LOGGING_LEVEL}' == 'INFO' || '${STAGE_LOGGING_LEVEL}' == 'ERROR' ]]"
check "AU-12 API metrics enabled" "[[ '${STAGE_METRICS}' == 'true' ]]"
check "SI-4 Lambda X-Ray tracing enabled" "[[ '${LAMBDA_TRACING}' == 'Active' ]]"
check "SI-4 API Gateway X-Ray tracing enabled" "[[ '${STAGE_XRAY}' == 'true' ]]"
if [[ -n "${CONFIG_RECORDER_NAME}" && "${CONFIG_RECORDER_NAME}" != "null" ]]; then
  check "CA-7 AWS Config recorder exists" "[[ ${CONFIG_RECORDER_PRESENT} -gt 0 ]]"
  check "CA-7 AWS Config recorder enabled" "[[ '${CONFIG_RECORDER_RECORDING}' == 'true' ]]"
fi
if [[ "${SECURITY_HUB_ENABLED_EXPECTED}" == "true" ]]; then
  check "CA-7 Security Hub enabled" "[[ -n '${SECURITY_HUB_HUB_ARN}' ]]"
  if [[ -n "${SECURITY_HUB_STANDARD_ARN}" && "${SECURITY_HUB_STANDARD_ARN}" != "null" ]]; then
    check "RA-5 Foundational Security Standard subscribed" "[[ '${SECURITY_HUB_STANDARD_ENABLED}' == 'true' ]]"
  fi
fi

if [[ -f "${OUTPUT_DIR}/kms-key-rotation-status.json" ]]; then
  KMS_ROTATION="$(jq -r '.KeyRotationEnabled' "${OUTPUT_DIR}/kms-key-rotation-status.json")"
  check "SC-12 KMS rotation enabled" "[[ '${KMS_ROTATION}' == 'true' ]]"
fi

popd >/dev/null

if [[ "${PASS}" == "true" ]]; then
  echo "\nValidation completed successfully. Evidence: ${OUTPUT_DIR}"
  exit 0
fi

echo "\nValidation failed. Review: ${REPORT_FILE}" >&2
exit 1
