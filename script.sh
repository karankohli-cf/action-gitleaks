#!/bin/bash

# Print commands for debugging
if [[ "$RUNNER_DEBUG" = "1" ]]; then
    set -x
fi

# Fail fast on errors, unset variables, and failures in piped commands
set -Eeuo pipefail

cd "${GITHUB_WORKSPACE}/${INPUT_WORKING_DIRECTORY}" || exit

echo '::group::Preparing ...'
unameOS="$(uname -s)"
case "${unameOS}" in
    Linux*)     os=linux;;
    Darwin*)    os=darwin;;
    CYGWIN*)    os=windows;;
    MINGW*)     os=windows;;
    MSYS_NT*)   os=windows;;
    *)          echo "Unknown system: ${unameOS}" && exit 1
esac

unameArch="$(uname -m)"
case "${unameArch}" in
    x86*)      arch=arm64;;
    *)         echo "Unsupported architecture: ${unameArch}. arm64 is supported by gitleaks" && exit 1
esac

TEMP_PATH="$(mktemp -d)"
echo "Detected ${os} running on ${arch}, will install tools in ${TEMP_PATH}"
REVIEWDOG_PATH="${TEMP_PATH}/reviewdog"
GITLEAKS_PATH="${TEMP_PATH}/gitleaks"
echo '::endgroup::'

echo "::group::🐶 Installing reviewdog (${REVIEWDOG_VERSION}) ... https://github.com/reviewdog/reviewdog"
curl -sfL https://raw.githubusercontent.com/reviewdog/reviewdog/master/install.sh | sh -s -- -b "${REVIEWDOG_PATH}" "${REVIEWDOG_VERSION}" 2>&1
echo '::endgroup::'

echo "::group:: Installing gitleaks (${INPUT_GITLEAKS_VERSION}) ... https://github.com/zricethezav/gitleaks"
test ! -d "${GITLEAKS_PATH}" && install -d "${GITLEAKS_PATH}"

if [[ "${INPUT_GITLEAKS_VERSION}" = "latest" ]]; then
    gitleaks_version=$(curl --silent -H "Accept: application/vnd.github.v3+json" -H "Authorization: token ${INPUT_GITHUB_TOKEN}" https://api.github.com/repos/zricethezav/gitleaks/releases/latest | jq -r .tag_name)
    gitleaks_version="${gitleaks_version:1}" #remove v from v8.15.1
else
    gitleaks_version=${INPUT_GITLEAKS_VERSION}
fi
binary="gitleaks"
url="https://github.com/zricethezav/gitleaks/releases/download/v${gitleaks_version}/gitleaks_${gitleaks_version}_${os}_${arch}.tar.gz"

if [[ "${os}" = "windows" ]]; then
    url+=".exe"
    binary+=".exe"
fi

curl --silent --show-error --fail \
--location "${url}" \
--output gitleaks.tar.gz
tar -xvf gitleaks.tar.gz
install gitleaks "${GITLEAKS_PATH}"
echo '::endgroup::'

echo "::group:: Print gitleaks details ..."
"${GITLEAKS_PATH}/gitleaks" version
echo '::endgroup::'

echo '::group:: Running gitleaks with reviewdog 🐶 ...'
export REVIEWDOG_GITHUB_API_TOKEN="${INPUT_GITHUB_TOKEN}"

# Allow failures now, as reviewdog handles them
set +Eeuo pipefail

# shellcheck disable=SC2086
"${GITLEAKS_PATH}/gitleaks" detect --source=${INPUT_GITLEAKS_SCAN_PATH} --report-format=json --report-path=gitleaks.json ${INPUT_GITLEAKS_FLAGS:-} || ret=$?

jq -r -f "${GITHUB_ACTION_PATH}/to-rdjson.jq" gitleaks.json \
|  "${REVIEWDOG_PATH}/reviewdog" -f=rdjson \
-name="gitleaks" \
-reporter="${INPUT_REPORTER}" \
-level="${INPUT_LEVEL}" \
-fail-on-error="${INPUT_FAIL_ON_ERROR}" \
-filter-mode="${INPUT_FILTER_MODE}" \
${INPUT_FLAGS}


rd_ret=${PIPESTATUS[1]}
if [[ "${ret}" -gt 0 ]]; then
    ret=1
fi
gitleaks_return="${ret}" reviewdog_return="${rd_ret}" exit_code=${rd_ret}
echo "::set-output name=gitleaks-return-code::${gitleaks_return}"
echo "::set-output name=reviewdog-return-code::${reviewdog_return}"
echo '::endgroup::'

exit "${exit_code}"
