#!/usr/bin/env bash
# Artifact ID: ATAC-BASH-SCR-012
# Finalize cohort-level consensus peaks, counts, and the QC table.

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "${SCRIPT_DIR}/lib/common.sh"

[[ $# -eq 2 ]] || usage_die "Usage: $0 <project_config.sh> <samples.tsv>"
CONFIG="$1"
SAMPLE_SHEET="$2"
load_project_config "${CONFIG}"
validate_sample_sheet "${SAMPLE_SHEET}"

cohort_log_dir="${LOG_DIR}/pipeline/cohort"
mkdir -p "${cohort_log_dir}"

for script_name in 06_build_consensus_peaks.sh 07_count_consensus_reads.sh; do
  bash "${SCRIPT_DIR}/${script_name}" "${CONFIG}" "${SAMPLE_SHEET}" \
    2>&1 | tee "${cohort_log_dir}/${script_name%.sh}.log"
done

bash "${SCRIPT_DIR}/08_collect_qc_metrics.sh" aggregate "${CONFIG}" "${SAMPLE_SHEET}" \
  2>&1 | tee "${cohort_log_dir}/08_aggregate_qc_metrics.log"
log "Cohort-level finalization complete."

