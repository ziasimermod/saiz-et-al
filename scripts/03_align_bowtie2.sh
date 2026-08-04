#!/usr/bin/env bash
# Artifact ID: ATAC-BASH-SCR-004
# Align paired reads to mm10/GRCm38 with Bowtie2 --very-sensitive.

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "${SCRIPT_DIR}/lib/common.sh"

[[ $# -eq 3 ]] || usage_die "Usage: $0 <project_config.sh> <samples.tsv> <sample_id>"
load_project_config "$1"
validate_sample_sheet "$2"
load_sample_fastqs "$2" "$3"
require_command "${BOWTIE2_BIN}"
require_command "${SAMTOOLS_BIN}"

in_r1="$(trimmed_r1 "${SAMPLE_ID}")"
in_r2="$(trimmed_r2 "${SAMPLE_ID}")"
require_nonempty_file "${in_r1}"
require_nonempty_file "${in_r2}"

out_dir="${RESULTS_DIR}/bam/aligned"
qc_dir="${RESULTS_DIR}/qc/alignment"
out_bam="$(aligned_bam "${SAMPLE_ID}")"
bowtie_log="${qc_dir}/${SAMPLE_ID}.bowtie2.log"
mkdir -p "${out_dir}" "${qc_dir}"

if should_skip "${out_bam}"; then
  exit 0
fi

tmp_bam="$(mktemp "${out_dir}/${SAMPLE_ID}.tmp.XXXXXX.bam")"
trap 'rm -f "${tmp_bam}"' EXIT

log "Aligning ${SAMPLE_ID} to ${GENOME_BUILD:-mm10/GRCm38}"
"${BOWTIE2_BIN}" \
  --very-sensitive \
  --threads "${THREADS}" \
  -x "${BOWTIE2_INDEX_PREFIX}" \
  -1 "${in_r1}" \
  -2 "${in_r2}" \
  2> "${bowtie_log}" \
  | "${SAMTOOLS_BIN}" view -@ "${THREADS}" -b - \
  | "${SAMTOOLS_BIN}" sort -@ "${THREADS}" -o "${tmp_bam}" -

mv "${tmp_bam}" "${out_bam}"
trap - EXIT
"${SAMTOOLS_BIN}" index -@ "${THREADS}" "${out_bam}"
"${SAMTOOLS_BIN}" flagstat -@ "${THREADS}" "${out_bam}" > "${qc_dir}/${SAMPLE_ID}.aligned.flagstat.txt"

require_nonempty_file "${out_bam}"
require_nonempty_file "${bowtie_log}"
log "Bowtie2 alignment complete for ${SAMPLE_ID}."

