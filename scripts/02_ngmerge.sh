#!/usr/bin/env bash

# Trim adapter-overlapping paired reads with NGMerge v0.5 in adapter mode.

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "${SCRIPT_DIR}/lib/common.sh"

[[ $# -eq 3 ]] || usage_die "Usage: $0 <project_config.sh> <samples.tsv> <sample_id>"
load_project_config "$1"
validate_sample_sheet "$2"
load_sample_fastqs "$2" "$3"
require_command "${NGMERGE_BIN}"

out_dir="${RESULTS_DIR}/trimmed_fastq"
log_dir="${LOG_DIR}/ngmerge"
prefix="${out_dir}/${SAMPLE_ID}.ngmerge"
out_r1="$(trimmed_r1 "${SAMPLE_ID}")"
out_r2="$(trimmed_r2 "${SAMPLE_ID}")"
mkdir -p "${out_dir}" "${log_dir}"

if should_skip "${out_r1}" && [[ -s "${out_r2}" ]]; then
  exit 0
fi
if [[ "${OVERWRITE}" == "true" ]]; then
  rm -f "${out_r1}" "${out_r2}" "${log_dir}/${SAMPLE_ID}.ngmerge.log"
fi

log "Running NGMerge adapter trimming for ${SAMPLE_ID}"
"${NGMERGE_BIN}" -a -1 "${FASTQ_R1}" -2 "${FASTQ_R2}" -o "${prefix}" \
  > "${log_dir}/${SAMPLE_ID}.ngmerge.log" 2>&1

require_nonempty_file "${out_r1}"
require_nonempty_file "${out_r2}"
log "NGMerge completed for ${SAMPLE_ID}."
