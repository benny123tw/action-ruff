#!/bin/sh

cd "${GITHUB_WORKSPACE}/${INPUT_WORKDIR}" || exit 1

TEMP_PATH="$(mktemp -d)"
PATH="${TEMP_PATH}:$PATH"
export REVIEWDOG_GITHUB_API_TOKEN="${INPUT_GITHUB_TOKEN}"

# Check if uvx is installed
if ! command -v uvx > /dev/null 2>&1; then
  echo '::group::🚀 Installing uv ... https://docs.astral.sh/uv/'
  set -e

  # Download and install uv
  if curl -LsSf https://astral.sh/uv/install.sh | sh; then
    echo 'uv installed successfully.'
  else
    echo 'Failed to install uv.' >&2
    exit 1
  fi

  # Source the environment setup script
  if [ -f "$HOME/.local/bin/env" ]; then
    . "$HOME/.local/bin/env"
  else
    echo 'Environment setup script not found.' >&2
    exit 1
  fi

  set +e
  echo '::endgroup::'
else
  echo 'uvx is already installed.'
fi

echo '::group::🐶 Installing reviewdog ... https://github.com/reviewdog/reviewdog'
curl -sfL https://raw.githubusercontent.com/reviewdog/reviewdog/master/install.sh \
  | sh -s -- -b "${TEMP_PATH}" "${REVIEWDOG_VERSION}" 2>&1
echo '::endgroup::'

echo "ruff version: $(uvx ruff --version)"

# Assign a default value to files_to_check
files_to_check=""

# Check if IS_CHANGED_FILES_ENABLED is true and reassign files_to_check if so
if [ "${IS_CHANGED_FILES_ENABLED}" = "true" ]; then
  files_to_check=${CHANGED_FILES}
fi

# Add the new check: if IS_CHANGED_FILES_ENABLED is true and there are no changed files, skip the check
if [ "${IS_CHANGED_FILES_ENABLED}" = "true" ] && [ -z "${files_to_check}" ]; then
  echo "No changed files and IS_CHANGED_FILES_ENABLED is true. Skipping check."
  exit 0
fi

echo '::group:: Running ruff with reviewdog 🐶 ...'
uvx ruff check -q --output-format=rdjson ${INPUT_RUFF_FLAGS} ${files_to_check} \
  | reviewdog -f=rdjson \
      -name="${INPUT_TOOL_NAME}" \
      -reporter="${INPUT_REPORTER:-github-pr-review}" \
      -filter-mode="${INPUT_FILTER_MODE}" \
      -fail-level="${INPUT_FAIL_LEVEL}" \
      -fail-on-error="${INPUT_FAIL_ON_ERROR}" \
      -level="${INPUT_LEVEL}" \
      ${INPUT_REVIEWDOG_FLAGS}

reviewdog_rc=$?
echo '::endgroup::'
exit $reviewdog_rc
