#!/usr/bin/env bash
# Artifact ID: ATAC-BASH-SCR-007
# Build the union consensus peak set from all per-library MACS3 narrowPeak files.

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "${SCRIPT_DIR}/lib/common.sh"

[[ $# -eq 2 ]] || usage_die "Usage: $0 <project_config.sh> <samples.tsv>"
load_project_config "$1"
validate_sample_sheet "$2"
require_command "${BEDTOOLS_BIN}"

out_dir="${RESULTS_DIR}/consensus"
out_bed="$(consensus_bed)"
input_manifest="${out_dir}/consensus_peak_inputs.tsv"
mkdir -p "${out_dir}"

if should_skip "${out_bed}"; then
  exit 0
fi

all_peaks="$(mktemp "${out_dir}/all_peaks.XXXXXX.bed")"
sorted_peaks="$(mktemp "${out_dir}/sorted_peaks.XXXXXX.bed")"
tmp_output="$(mktemp "${out_dir}/consensus_peaks.XXXXXX.bed")"
trap 'rm -f "${all_peaks}" "${sorted_peaks}" "${tmp_output}"' EXIT

printf 'sample_id\tpeak_file\tsha256\n' > "${input_manifest}"
while IFS= read -r sample_id; do
  peak_file="$(sample_peak_file "${sample_id}")"
  require_nonempty_file "${peak_file}"
  awk 'BEGIN {OFS="\t"} NF >= 3 {print $1,$2,$3}' "${peak_file}" >> "${all_peaks}"
  printf '%s\t%s\t%s\n' \
    "${sample_id}" \
    "${peak_file}" \
    "$(sha256_file "${peak_file}")" \
    >> "${input_manifest}"
done < <(sample_ids "$2")

LC_ALL=C sort -k1,1 -k2,2n -k3,3n "${all_peaks}" > "${sorted_peaks}"
"${BEDTOOLS_BIN}" merge -i "${sorted_peaks}" \
  | awk 'BEGIN {OFS="\t"} {printf "%s\t%s\t%s\tconsensus_peak_%06d\n", $1, $2, $3, NR}' \
  > "${tmp_output}"

require_nonempty_file "${tmp_output}"
mv "${tmp_output}" "${out_bed}"
trap - EXIT
rm -f "${all_peaks}" "${sorted_peaks}"

printf 'consensus_peak_count\t%s\n' "$(wc -l < "${out_bed}")" > "${out_dir}/consensus_peak_count.tsv"
log "Consensus peak union written to ${out_bed}."
