#!/usr/bin/env bash
# Artifact ID: ATAC-BASH-SCR-005
# Remove mitochondrial alignments, then mark/remove duplicates with Picard.

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "${SCRIPT_DIR}/lib/common.sh"

[[ $# -eq 3 ]] || usage_die "Usage: $0 <project_config.sh> <samples.tsv> <sample_id>"
load_project_config "$1"
validate_sample_sheet "$2"
load_sample_fastqs "$2" "$3"
require_command "${SAMTOOLS_BIN}"
require_command "$(picard_available_name)"

in_bam="$(aligned_bam "${SAMPLE_ID}")"
out_bam="$(clean_bam "${SAMPLE_ID}")"
require_nonempty_file "${in_bam}"

out_dir="${RESULTS_DIR}/bam/clean"
idxstats_dir="${RESULTS_DIR}/qc/idxstats"
dup_dir="${RESULTS_DIR}/qc/duplicates"
flagstat_dir="${RESULTS_DIR}/qc/alignment"
mkdir -p "${out_dir}" "${idxstats_dir}" "${dup_dir}" "${flagstat_dir}"

if should_skip "${out_bam}"; then
  exit 0
fi

idxstats_file="${idxstats_dir}/${SAMPLE_ID}.pre_filter.idxstats.tsv"
"${SAMTOOLS_BIN}" idxstats "${in_bam}" > "${idxstats_file}"
mapfile -t keep_contigs < <(awk -v mt="${MITO_CONTIG}" '$1 != "*" && $1 != mt {print $1}' "${idxstats_file}")
(( ${#keep_contigs[@]} > 0 )) || die "No non-mitochondrial contigs found in ${in_bam}"

mt_removed_bam="${out_dir}/${SAMPLE_ID}.rmChrM.bam"
duplicate_metrics="${dup_dir}/${SAMPLE_ID}.picard_markduplicates_metrics.txt"
if [[ "${OVERWRITE}" == "true" ]]; then
  rm -f "${mt_removed_bam}" "${mt_removed_bam}.bai" "${out_bam}" "${out_bam}.bai" "${duplicate_metrics}"
fi
log "Removing ${MITO_CONTIG} alignments from ${SAMPLE_ID}"
"${SAMTOOLS_BIN}" view -@ "${THREADS}" -b -o "${mt_removed_bam}" "${in_bam}" "${keep_contigs[@]}"
"${SAMTOOLS_BIN}" index -@ "${THREADS}" "${mt_removed_bam}"

log "Marking and removing duplicates from ${SAMPLE_ID}"
run_picard MarkDuplicates \
  "I=${mt_removed_bam}" \
  "O=${out_bam}" \
  "M=${duplicate_metrics}" \
  REMOVE_DUPLICATES=true \
  ASSUME_SORT_ORDER=coordinate \
  VALIDATION_STRINGENCY=SILENT

"${SAMTOOLS_BIN}" index -@ "${THREADS}" "${out_bam}"
"${SAMTOOLS_BIN}" flagstat -@ "${THREADS}" "${out_bam}" > "${flagstat_dir}/${SAMPLE_ID}.clean.flagstat.txt"
require_nonempty_file "${out_bam}"
require_nonempty_file "${duplicate_metrics}"
log "Mitochondrial filtering and duplicate removal complete for ${SAMPLE_ID}."
