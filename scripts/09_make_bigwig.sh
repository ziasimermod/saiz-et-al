#!/usr/bin/env bash
# Artifact ID: ATAC-BASH-SCR-010
# Generate normalized bigWig tracks for genome-browser visualization.

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "${SCRIPT_DIR}/lib/common.sh"

[[ $# -eq 3 ]] || usage_die "Usage: $0 <project_config.sh> <samples.tsv> <sample_id>"
load_project_config "$1"
validate_sample_sheet "$2"
load_sample_fastqs "$2" "$3"
require_command "${BAMCOVERAGE_BIN}"

in_bam="$(clean_bam "${SAMPLE_ID}")"
require_nonempty_file "${in_bam}"
out_dir="${RESULTS_DIR}/bigwig"
out_bw="${out_dir}/${SAMPLE_ID}.${BIGWIG_NORMALIZATION}.bw"
mkdir -p "${out_dir}"

if should_skip "${out_bw}"; then
  exit 0
fi

case "${BIGWIG_NORMALIZATION}" in
  RPKM|CPM|BPM|RPGC|None) ;;
  *) die "Unsupported BIGWIG_NORMALIZATION: ${BIGWIG_NORMALIZATION}" ;;
esac

args=(
  --bam "${in_bam}"
  --outFileName "${out_bw}"
  --normalizeUsing "${BIGWIG_NORMALIZATION}"
  --binSize "${BIGWIG_BIN_SIZE}"
  --extendReads
  --numberOfProcessors "${THREADS}"
)

if [[ -n "${BLACKLIST_BED:-}" ]]; then
  blacklist="$(absolute_path "${BLACKLIST_BED}")"
  require_nonempty_file "${blacklist}"
  args+=(--blackListFileName "${blacklist}")
fi

if [[ -n "${BIGWIG_SCALE_FACTORS_TSV:-}" ]]; then
  scale_file="$(absolute_path "${BIGWIG_SCALE_FACTORS_TSV}")"
  require_nonempty_file "${scale_file}"
  scale_factor="$(awk -F '\t' -v id="${SAMPLE_ID}" '$1 == id {print $2; found=1; exit} END {if (!found) exit 1}' "${scale_file}")" || \
    die "No scale factor for ${SAMPLE_ID} in ${scale_file}"
  args+=(--scaleFactor "${scale_factor}")
fi

log "Generating ${BIGWIG_NORMALIZATION}-normalized bigWig for ${SAMPLE_ID}"
"${BAMCOVERAGE_BIN}" "${args[@]}"
require_nonempty_file "${out_bw}"
log "bigWig generation complete for ${SAMPLE_ID}."

