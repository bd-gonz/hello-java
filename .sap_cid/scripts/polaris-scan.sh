#!/usr/bin/env bash

set -euo pipefail

BRIDGE_URL="https://repo.blackduck.com/artifactory/bds-integrations-release/com/blackduck/integration/bridge/binaries/bridge-cli-bundle/latest/bridge-cli-bundle-linux64.zip"
BRIDGE_DIR="${PWD}/.bridge-cli"

: "${BRIDGE_POLARIS_ACCESSTOKEN:?BRIDGE_POLARIS_ACCESSTOKEN is not defined}"
: "${BRIDGE_POLARIS_SERVERURL:?BRIDGE_POLARIS_SERVERURL is not defined}"
: "${BRIDGE_POLARIS_APPLICATION_NAME:?BRIDGE_POLARIS_APPLICATION_NAME is not defined}"
: "${BRIDGE_POLARIS_PROJECT_NAME:?BRIDGE_POLARIS_PROJECT_NAME is not defined}"
: "${BRIDGE_POLARIS_BRANCH_NAME:=main}"

echo "Downloading Bridge CLI..."
rm -rf "${BRIDGE_DIR}"
mkdir -p "${BRIDGE_DIR}"

curl --fail --location --silent --show-error \
  --output "${BRIDGE_DIR}/bridge.zip" \
  "${BRIDGE_URL}"

unzip -q "${BRIDGE_DIR}/bridge.zip" -d "${BRIDGE_DIR}"
rm -f "${BRIDGE_DIR}/bridge.zip"

BRIDGE_BIN="$(find "${BRIDGE_DIR}" -type f -name bridge-cli | head -n 1)"

if [[ -z "${BRIDGE_BIN}" ]]; then
  echo "Bridge CLI executable not found"
  exit 1
fi

chmod +x "${BRIDGE_BIN}"

echo "Starting Polaris SAST and SCA assessment..."

"${BRIDGE_BIN}" \
  --stage polaris \
  "polaris.serverUrl=${BRIDGE_POLARIS_SERVERURL}" \
  "polaris.application.name=${BRIDGE_POLARIS_APPLICATION_NAME}" \
  "polaris.project.name=${BRIDGE_POLARIS_PROJECT_NAME}" \
  "polaris.branch.name=${BRIDGE_POLARIS_BRANCH_NAME}" \
  "polaris.assessment.types=SAST,SCA" \
  "coverity.cleanCommand=mvn -B clean" \
  "coverity.buildCommand=mvn -B -DskipTests package"