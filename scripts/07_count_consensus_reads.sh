#!/usr/bin/env bash
# Artifact ID: ATAC-BASH-SCR-008
# Count cleaned alignments in the consensus regions with bedtools multicov.

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "${SCRIPT_DIR}/lib/common.sh"

[[ $# -eq 2 ]] || usage_die "Usage: $0 <project_config.sh> <samples.tsv>"
load_project_config "$1"
validate_sample_sheet "$2"
require_command "${BEDTOOLS_BIN}"

in_bed="$(consensus_bed)"
require_nonempty_file "${in_bed}"
out_dir="${RESULTS_DIR}/counts"
out_file="${out_dir}/consensus_peak_counts.tsv"
mkdir -p "${out_dir}"

if should_skip "${out_file}"; then
  exit 0
fi

mapfile -t ids < <(sample_ids "$2")
(( ${#ids[@]} > 0 )) || die "No samples found in $2"
bams=()
for sample_id in "${ids[@]}"; do
  bam="$(clean_bam "${sample_id}")"
  require_nonempty_file "${bam}"
  [[ -s "${bam}.bai" ]] || die "BAM index not found: ${bam}.bai"
  bams+=("${bam}")
done

tmp_counts="$(mktemp "${out_dir}/multicov.XXXXXX.tsv")"
tmp_output="$(mktemp "${out_dir}/consensus_peak_counts.XXXXXX.tsv")"
trap 'rm -f "${tmp_counts}" "${tmp_output}"' EXIT

log "Counting ${#ids[@]} libraries across $(wc -l < "${in_bed}") consensus peaks"
"${BEDTOOLS_BIN}" multicov -bed "${in_bed}" -bams "${bams[@]}" > "${tmp_counts}"

{
  printf 'chrom\tstart\tend\tpeak_id'
  for sample_id in "${ids[@]}"; do
    printf '\t%s' "${sample_id}"
  done
  printf '\n'
  cat "${tmp_counts}"
} > "${tmp_output}"

require_nonempty_file "${tmp_output}"
mv "${tmp_output}" "${out_file}"
trap - EXIT
rm -f "${tmp_counts}"
log "Consensus peak-count matrix written to ${out_file}."

