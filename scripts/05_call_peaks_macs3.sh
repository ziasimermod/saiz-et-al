#!/usr/bin/env bash
# Artifact ID: ATAC-BASH-SCR-006
# Call peaks independently for each paired-end library with MACS3.

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "${SCRIPT_DIR}/lib/common.sh"

[[ $# -eq 3 ]] || usage_die "Usage: $0 <project_config.sh> <samples.tsv> <sample_id>"
load_project_config "$1"
validate_sample_sheet "$2"
load_sample_fastqs "$2" "$3"
require_command "${MACS3_BIN}"

in_bam="$(clean_bam "${SAMPLE_ID}")"
out_dir="${RESULTS_DIR}/peaks/${SAMPLE_ID}"
out_peak="$(sample_peak_file "${SAMPLE_ID}")"
require_nonempty_file "${in_bam}"
mkdir -p "${out_dir}"

if should_skip "${out_peak}"; then
  exit 0
fi
if [[ "${OVERWRITE}" == "true" ]]; then
  rm -f \
    "${out_dir}/${SAMPLE_ID}_peaks.narrowPeak" \
    "${out_dir}/${SAMPLE_ID}_peaks.xls" \
    "${out_dir}/${SAMPLE_ID}_summits.bed" \
    "${out_dir}/${SAMPLE_ID}_treat_pileup.bdg" \
    "${out_dir}/${SAMPLE_ID}_control_lambda.bdg" \
    "${out_dir}/${SAMPLE_ID}.macs3.log" \
    "${out_dir}/${SAMPLE_ID}.peak_count.tsv"
fi

log "Calling paired-end MACS3 peaks for ${SAMPLE_ID} at q=${MACS3_QVALUE}"
"${MACS3_BIN}" callpeak \
  -t "${in_bam}" \
  -f BAMPE \
  -g "${MACS3_GENOME_SIZE}" \
  -n "${SAMPLE_ID}" \
  --outdir "${out_dir}" \
  -q "${MACS3_QVALUE}" \
  --call-summits \
  -B \
  > "${out_dir}/${SAMPLE_ID}.macs3.log" 2>&1

require_nonempty_file "${out_peak}"
printf 'sample_id\tpeak_count\n%s\t%s\n' \
  "${SAMPLE_ID}" "$(wc -l < "${out_peak}")" \
  > "${out_dir}/${SAMPLE_ID}.peak_count.tsv"
log "MACS3 peak calling complete for ${SAMPLE_ID}."
