#!/bin/bash
#
# Description:
#   This script measures Go's C1 coverage and outputs it in SonarQube report format.
#
# Usage:
#   ./branch-test.sh all|pr [output directory]
#
# Options:
#   all  Run coverage for all packages and output the result.
#   pr   Run coverage only for changed packages in the current pull request.
#
# Requirements:
#   - git, go
#
# Exit Codes:
#   0 Success
#   1 Runtime error occurred
#   2 Environment variables are not set correctly
#   3 Input parameters are missing or invalid
#
# Reference:
#   https://moneyforward.kibe.la/notes/265468#collect-the-packages-changed-in-pr

readonly ROOT_PATH="github.com/moneyforward/golang-backend-boilerplate"
readonly BASE_BRANCH="main"
readonly EXCLUDE_PATTERNS=(
  "cmd/.*"
  "tests/.*"
  "internal/pkg/testsupport/.*"
  "internal/pkg/proto/.*"
  "internal/pkg/repository/models/.*"
  "tools/.*"
  ".*/fake"
)

# Validate environment variables
if [[ -z "${GITHUB_ACCESS_TOKEN}" ]]; then
  echo "Error: GITHUB_ACCESS_TOKEN is not set." >&2
  exit 2
fi

#######################################
# Sets up the required dependencies for the project,
# including configuring Git access for private repositories
# and installing the Go branch coverage tool.
#
# Globals:
#   GITHUB_ACCESS_TOKEN: OAuth token for accessing private Git repositories.
#
# Arguments:
#   None
#
# Returns:
#   None
#######################################
function setup_dependencies() {
  # Setup go private repository
  local PRIVATE_REPO="github.com/moneyforwardvietnam/*,github.com/moneyforward/*"
  export GOPRIVATE="${PRIVATE_REPO}"

  # Configure Git to use OAuth token for private repository access
  local GIT_URL_WITH_BASIC="https://x-oauth-basic:${GITHUB_ACCESS_TOKEN}@github.com/moneyforward"
  local GIT_URL="https://github.com/moneyforward"
  git config --global url."${GIT_URL_WITH_BASIC}".insteadOf "${GIT_URL}"

  # Install the Go branch coverage tool
  go install github.com/moneyforward/go-branch-coverage@latest
}

#######################################
# Generates a list of test packages based on the provided option.
# The options can be 'all' to list all packages or 'pr' to list packages changed in a pull request.
#
# Globals:
#   ROOT_PATH       : The base path to remove from the package names.
#   BASE_BRANCH     : The branch to compare against when listing changed packages.
#   EXCLUDE_PATTERNS: An array of patterns to exclude certain packages from the list.
#
# Arguments:
#   option: The operation mode, either 'all' or 'pr'.
#
# Returns:
#   A space-separated list of filtered package names.
#######################################
function make_package_list() {
  local option="${1}"
  local packages=()
  local filtered_list=()

  if [[ "${option}" == "all" ]]; then
    # List all packages, removing the ROOT_PATH prefix.
    packages=($(go list ./... | sed "s|${ROOT_PATH}/||g"))
  elif [[ "${option}" == "pr" ]]; then
    # List changed packages in the current pull request by comparing with BASE_BRANCH.
    packages=($(git diff --name-only ${BASE_BRANCH} -- | xargs -n1 dirname | awk -F "/[^/]/*$" '{ print ($1 == "." ? "": $1); }' | sort -u))
  else
    echo "Error: Invalid option. Use 'all' or 'pr'." >&2
    exit 3
  fi

  # Filter the package list to exclude unwanted packages.
  for package in "${packages[@]}"; do
    # Skip packages that start with a dot (e.g., hidden directories).
    if [[ ${package:0:1} == '.' ]]; then
      continue
    fi

    # Check each package against the exclude patterns.
    for pattern in "${EXCLUDE_PATTERNS[@]}"; do
      if [[ ${package} =~ ${pattern} ]]; then
        continue 2
      fi
    done

    # Add the filtered package to the filtered_list.
    filtered_list+="${package} "
  done

  echo "${filtered_list}"
}

#######################################
# Analyzes the coverage results of the specified packages,
# generates test data in a generic format, and copies results
# to the aggregated test results directory.
#
# Globals:
#   TEST_RESULTS_DIR: Directory to copy the final results
#
# Arguments:
#   packages: List of packages to analyze
#
# Returns:
#   None
#######################################
function analyze() {
  local TMP_DIR="./test-results"
  mkdir -p "${TMP_DIR}"

  > ${TMP_DIR}/gobco_out.log
  > ${TMP_DIR}/branch-cover.json

  local packages=("${@}")
  for package in "${packages[@]}"; do
    echo "--- Analysing: ${package}"
    gobco -branch -list-all -test -v -stats "${package}/branch-cover.json" "${package}" >>"${TMP_DIR}/gobco_out.log"

    if [ -f "${package}/branch-cover.json" ]; then
      go-branch-coverage -srcPackageName "${package}" -targetPackageName test-results -isUpdateJson=true
      rm "${package}/branch-cover.json"
    fi
    echo "--- Finish analysing: ${package}"
  done

  echo "--- Generating generic test data format as xml file..."
  go-branch-coverage -srcPackageName "${TMP_DIR}" -isUpdateJson=false
  echo "--- Finished generating generic test data format as xml file"

  echo "--- Copy results to aggregated test results directory"
  mkdir -p "${TEST_RESULTS_DIR}"
  cp -r "${TMP_DIR}"/* "${TEST_RESULTS_DIR}"
  if [ "${TMP_DIR}" != "${TEST_RESULTS_DIR}" ]; then
    rm -rf "${TMP_DIR}"
  fi
  echo "--- Finished copying results to aggregated test results directory"
}

#######################################
# Main script execution
#######################################
OPTION=${1}
TEST_RESULTS_DIR=${2:-"/tmp/test_results"}

if [[ "${OPTION}" != "all" && "${OPTION}" != "pr" ]]; then
  echo "Usage: ./branch-test.sh all|pr"
  echo "Error: Invalid option '${OPTION}'. Use 'all' or 'pr'." >&2
  exit 3
fi

echo "--- Installing dependencies..."
setup_dependencies
echo "--- Finished installing dependencies..."

echo "--- Listing ${OPTION} packages..."
test_packages=($(make_package_list "${OPTION}"))
echo "--- Finished listing ${OPTION} packages..."

echo "--- Starting branch test..."
analyze "${test_packages[@]}"
echo "--- Finished branch test..."
