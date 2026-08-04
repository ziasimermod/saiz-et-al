#!/usr/bin/env bash
# Artifact ID: ATAC-BASH-SCR-009
# Collect the seven ATAC-seq QC categories reported in the STAR Methods.

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "${SCRIPT_DIR}/lib/common.sh"

[[ $# -ge 1 ]] || usage_die "Usage: $0 sample <config> <samples.tsv> <sample_id> | $0 aggregate <config> <samples.tsv>"
MODE="$1"

metric_value() {
  local metrics_file="$1"
  local key="$2"
  awk -F '\t' -v key="${key}" '
    /^#/ || NF == 0 {next}
    !header_seen {
      for (i=1; i<=NF; i++) if ($i == key) column=i
      if (column) {header_seen=1; next}
    }
    header_seen {print $column; exit}
  ' "${metrics_file}"
}

aggregate_metrics() {
  [[ $# -eq 3 ]] || usage_die "Usage: $0 aggregate <config> <samples.tsv>"
  load_project_config "$2"
  validate_sample_sheet "$3"
  metrics_dir="${RESULTS_DIR}/qc/metrics"
  out_file="${RESULTS_DIR}/qc/ATACseq_QC_summary.tsv"
  mkdir -p "${metrics_dir}"
  tmp_output="$(mktemp "${RESULTS_DIR}/qc/ATACseq_QC_summary.XXXXXX.tsv")"
  trap 'rm -f "${tmp_output}"' EXIT

  first=true
  while IFS= read -r sample_id; do
    sample_metrics="${metrics_dir}/${sample_id}.qc_metrics.tsv"
    require_nonempty_file "${sample_metrics}"
    if [[ "${first}" == "true" ]]; then
      head -n 1 "${sample_metrics}" > "${tmp_output}"
      first=false
    fi
    sed -n '2p' "${sample_metrics}" >> "${tmp_output}"
  done < <(sample_ids "$3")

  require_nonempty_file "${tmp_output}"
  mv "${tmp_output}" "${out_file}"
  trap - EXIT
  log "Combined QC summary written to ${out_file}."
}

if [[ "${MODE}" == "aggregate" ]]; then
  aggregate_metrics "$@"
  exit 0
fi

[[ "${MODE}" == "sample" && $# -eq 4 ]] || \
  usage_die "Usage: $0 sample <config> <samples.tsv> <sample_id> | $0 aggregate <config> <samples.tsv>"

load_project_config "$2"
validate_sample_sheet "$3"
load_sample_fastqs "$3" "$4"
require_command "${SAMTOOLS_BIN}"
require_command "${BEDTOOLS_BIN}"
require_command "$(picard_available_name)"

aligned="$(aligned_bam "${SAMPLE_ID}")"
clean="$(clean_bam "${SAMPLE_ID}")"
peaks="$(sample_peak_file "${SAMPLE_ID}")"
bowtie_log="${RESULTS_DIR}/qc/alignment/${SAMPLE_ID}.bowtie2.log"
raw_depth_file="${RESULTS_DIR}/qc/raw_read_depth/${SAMPLE_ID}.raw_depth.tsv"
idxstats_file="${RESULTS_DIR}/qc/idxstats/${SAMPLE_ID}.pre_filter.idxstats.tsv"
dup_metrics="${RESULTS_DIR}/qc/duplicates/${SAMPLE_ID}.picard_markduplicates_metrics.txt"
require_nonempty_file "${aligned}"
require_nonempty_file "${clean}"
require_nonempty_file "${peaks}"
require_nonempty_file "${bowtie_log}"
require_nonempty_file "${raw_depth_file}"
require_nonempty_file "${idxstats_file}"
require_nonempty_file "${dup_metrics}"

fragment_dir="${RESULTS_DIR}/qc/fragment_size/${SAMPLE_ID}"
metrics_dir="${RESULTS_DIR}/qc/metrics"
mkdir -p "${fragment_dir}" "${metrics_dir}"
insert_metrics="${fragment_dir}/${SAMPLE_ID}.insert_size_metrics.txt"
insert_histogram="${fragment_dir}/${SAMPLE_ID}.insert_size_histogram.pdf"

if ! should_skip "${insert_metrics}"; then
  if [[ "${OVERWRITE}" == "true" ]]; then
    rm -f "${insert_metrics}" "${insert_histogram}"
  fi
  log "Collecting fragment-size distribution for ${SAMPLE_ID}"
  run_picard CollectInsertSizeMetrics \
    "I=${clean}" \
    "O=${insert_metrics}" \
    "H=${insert_histogram}" \
    HISTOGRAM_WIDTH=1000 \
    MINIMUM_PCT=0.05 \
    VALIDATION_STRINGENCY=SILENT
fi
require_nonempty_file "${insert_metrics}"

raw_read_pairs="$(awk -F '\t' 'NR == 2 {print $2}' "${raw_depth_file}")"
raw_reads="$(awk -F '\t' 'NR == 2 {print $3}' "${raw_depth_file}")"
alignment_rate="$(awk '/overall alignment rate/ {gsub("%", "", $1); print $1; exit}' "${bowtie_log}")"
[[ -n "${alignment_rate}" ]] || die "Could not parse Bowtie2 alignment rate from ${bowtie_log}"

mito_fraction="$(awk -F '\t' -v mt="${MITO_CONTIG}" '
  $1 != "*" {total += $3}
  $1 == mt {mito += $3}
  END {if (total > 0) printf "%.8f", mito/total; else print "NA"}
' "${idxstats_file}")"
mito_percent="$(awk -v value="${mito_fraction}" 'BEGIN {if (value == "NA") print "NA"; else printf "%.4f", value*100}')"

duplicate_fraction="$(metric_value "${dup_metrics}" "PERCENT_DUPLICATION")"
[[ -n "${duplicate_fraction}" ]] || die "Could not parse PERCENT_DUPLICATION from ${dup_metrics}"
duplicate_percent="$(awk -v value="${duplicate_fraction}" 'BEGIN {printf "%.4f", value*100}')"

clean_alignment_records="$("${SAMTOOLS_BIN}" view -c "${clean}")"
clean_read_pairs="$("${SAMTOOLS_BIN}" view -c -f 66 -F 2304 "${clean}")"
peak_alignment_records="$("${BEDTOOLS_BIN}" intersect -u -a "${clean}" -b "${peaks}" | "${SAMTOOLS_BIN}" view -c -)"
frip_fraction="$(awk -v numerator="${peak_alignment_records}" -v denominator="${clean_alignment_records}" 'BEGIN {if (denominator > 0) printf "%.8f", numerator/denominator; else print "NA"}')"
frip_percent="$(awk -v value="${frip_fraction}" 'BEGIN {if (value == "NA") print "NA"; else printf "%.4f", value*100}')"

median_insert_size="$(metric_value "${insert_metrics}" "MEDIAN_INSERT_SIZE")"
mean_insert_size="$(metric_value "${insert_metrics}" "MEAN_INSERT_SIZE")"
insert_size_sd="$(metric_value "${insert_metrics}" "STANDARD_DEVIATION")"
peak_count="$(wc -l < "${peaks}")"

out_file="${metrics_dir}/${SAMPLE_ID}.qc_metrics.tsv"
{
  printf 'sample_id\traw_read_pairs\traw_reads\tbowtie2_alignment_rate_percent\tmitochondrial_read_fraction\tmitochondrial_read_percent\tpicard_duplicate_fraction\tpicard_duplicate_percent\tclean_alignment_records\tclean_read_pairs\tmedian_insert_size\tmean_insert_size\tinsert_size_sd\tfrip_fraction\tfrip_percent\tpeak_count\n'
  printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' \
    "${SAMPLE_ID}" "${raw_read_pairs}" "${raw_reads}" "${alignment_rate}" \
    "${mito_fraction}" "${mito_percent}" "${duplicate_fraction}" "${duplicate_percent}" \
    "${clean_alignment_records}" "${clean_read_pairs}" "${median_insert_size}" \
    "${mean_insert_size}" "${insert_size_sd}" "${frip_fraction}" "${frip_percent}" "${peak_count}"
} > "${out_file}"

log "QC metrics complete for ${SAMPLE_ID}."
