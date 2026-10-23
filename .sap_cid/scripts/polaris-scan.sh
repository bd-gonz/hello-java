#!/usr/bin/env bash

set -euo pipefail
env | sort

BRIDGE_URL="https://repo.blackduck.com/artifactory/bds-integrations-release/com/blackduck/integration/bridge/binaries/bridge-cli-bundle/latest/bridge-cli-bundle-linux64.zip"
BRIDGE_DIR="${PWD}/.bridge-cli"

: "${BRIDGE_POLARIS_ACCESSTOKEN:?BRIDGE_POLARIS_ACCESSTOKEN is not defined}"
: "${BRIDGE_POLARIS_SERVERURL:?BRIDGE_POLARIS_SERVERURL is not defined}"
: "${BRIDGE_POLARIS_APPLICATION_NAME:?BRIDGE_POLARIS_APPLICATION_NAME is not defined}"
: "${BRIDGE_POLARIS_PROJECT_NAME:?BRIDGE_POLARIS_PROJECT_NAME is not defined}"
: "${BRIDGE_POLARIS_BRANCH_NAME:=?BRIDGE_POLARIS_BRANCH_NAME is not defined}"

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

echo "Downloading Java 21"

curl -L -o temurin21.tar.gz \
https://github.com/adoptium/temurin21-binaries/releases/latest/download/OpenJDK21U-jdk_x64_linux_hotspot.tar.gz

mkdir -p .jdk
tar -xzf temurin21.tar.gz -C .jdk --strip-components=1

export JAVA_HOME="${PWD}/.jdk"
export PATH="${JAVA_HOME}/bin:${PATH}"

echo "Downloading Maven 3.9.11..."

curl -L -o maven.tar.gz \
https://archive.apache.org/dist/maven/maven-3/3.9.11/binaries/apache-maven-3.9.11-bin.tar.gz

mkdir -p .maven
tar -xzf maven.tar.gz -C .maven --strip-components=1

export MAVEN_HOME="${PWD}/.maven"
export PATH="${MAVEN_HOME}/bin:${PATH}"

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