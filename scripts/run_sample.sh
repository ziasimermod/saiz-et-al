#!/usr/bin/env bash
# Artifact ID: ATAC-BASH-SCR-011
# Run all sample-level steps for one ATAC-seq library.

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "${SCRIPT_DIR}/lib/common.sh"

[[ $# -eq 3 ]] || usage_die "Usage: $0 <project_config.sh> <samples.tsv> <sample_id>"
CONFIG="$1"
SAMPLE_SHEET="$2"
SAMPLE_ID="$3"
load_project_config "${CONFIG}"
validate_sample_sheet "${SAMPLE_SHEET}"

sample_log_dir="${LOG_DIR}/pipeline/${SAMPLE_ID}"
mkdir -p "${sample_log_dir}"

run_step() {
  local script_name="$1"
  log "Starting ${script_name} for ${SAMPLE_ID}"
  bash "${SCRIPT_DIR}/${script_name}" "${CONFIG}" "${SAMPLE_SHEET}" "${SAMPLE_ID}" \
    2>&1 | tee "${sample_log_dir}/${script_name%.sh}.log"
}

run_step "01_fastqc.sh"
run_step "02_ngmerge.sh"
run_step "03_align_bowtie2.sh"
run_step "04_filter_and_deduplicate.sh"
run_step "05_call_peaks_macs3.sh"

bash "${SCRIPT_DIR}/08_collect_qc_metrics.sh" sample "${CONFIG}" "${SAMPLE_SHEET}" "${SAMPLE_ID}" \
  2>&1 | tee "${sample_log_dir}/08_collect_qc_metrics.log"

if [[ "${MAKE_BIGWIG}" == "true" ]]; then
  run_step "09_make_bigwig.sh"
fi

log "All sample-level steps complete for ${SAMPLE_ID}."

