#!/usr/bin/env bash
# Artifact ID: ATAC-BASH-SCR-013
# Sequential convenience runner for the complete ATAC-seq Bash workflow.

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "${SCRIPT_DIR}/lib/common.sh"

[[ $# -ge 2 && $# -le 3 ]] || \
  usage_die "Usage: $0 <project_config.sh> <samples.tsv> [all|sample_id]"
CONFIG="$1"
SAMPLE_SHEET="$2"
TARGET="${3:-all}"

bash "${SCRIPT_DIR}/00_check_environment.sh" "${CONFIG}" "${SAMPLE_SHEET}"

if [[ "${TARGET}" == "all" ]]; then
  while IFS= read -r sample_id; do
    bash "${SCRIPT_DIR}/run_sample.sh" "${CONFIG}" "${SAMPLE_SHEET}" "${sample_id}"
  done < <(sample_ids "${SAMPLE_SHEET}")
  bash "${SCRIPT_DIR}/run_cohort.sh" "${CONFIG}" "${SAMPLE_SHEET}"
else
  sample_row "${SAMPLE_SHEET}" "${TARGET}" >/dev/null
  bash "${SCRIPT_DIR}/run_sample.sh" "${CONFIG}" "${SAMPLE_SHEET}" "${TARGET}"
  log "Single-sample run complete. Run run_cohort.sh after all libraries finish."
fi

