#!/usr/bin/env bash

# Run FastQC v0.12.1 on raw read pairs and record raw library depth.

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "${SCRIPT_DIR}/lib/common.sh"

[[ $# -eq 3 ]] || usage_die "Usage: $0 <project_config.sh> <samples.tsv> <sample_id>"
load_project_config "$1"
validate_sample_sheet "$2"
load_sample_fastqs "$2" "$3"
require_command "${FASTQC_BIN}"

out_dir="${RESULTS_DIR}/fastqc/raw/${SAMPLE_ID}"
depth_dir="${RESULTS_DIR}/qc/raw_read_depth"
marker="${out_dir}/${SAMPLE_ID}.fastqc.complete"
mkdir -p "${out_dir}" "${depth_dir}"

if ! should_skip "${marker}"; then
  log "Running FastQC for ${SAMPLE_ID}"
  "${FASTQC_BIN}" --threads "${THREADS}" --outdir "${out_dir}" "${FASTQ_R1}" "${FASTQ_R2}"
  printf 'FastQC completed at %s\n' "$(timestamp)" > "${marker}"
fi

depth_file="${depth_dir}/${SAMPLE_ID}.raw_depth.tsv"
if ! should_skip "${depth_file}"; then
  r1_records="$(count_fastq_records "${FASTQ_R1}")"
  r2_records="$(count_fastq_records "${FASTQ_R2}")"
  [[ "${r1_records}" -eq "${r2_records}" ]] || \
    die "Read-pair count mismatch for ${SAMPLE_ID}: R1=${r1_records}, R2=${r2_records}"
  {
    printf 'sample_id\traw_read_pairs\traw_reads\tr1_records\tr2_records\n'
    printf '%s\t%s\t%s\t%s\t%s\n' "${SAMPLE_ID}" "${r1_records}" "$((r1_records + r2_records))" "${r1_records}" "${r2_records}"
  } > "${depth_file}"
fi

log "FastQC and raw-depth assessment complete for ${SAMPLE_ID}."

