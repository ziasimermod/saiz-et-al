#!/usr/bin/env bash

# Shared functions for the ATAC-seq Bash compendium.

set -euo pipefail

COMMON_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMPENDIUM_ROOT="$(cd "${COMMON_DIR}/../.." && pwd)"

timestamp() {
  date '+%Y-%m-%dT%H:%M:%S%z'
}

log() {
  printf '[%s] %s\n' "$(timestamp)" "$*" >&2
}

die() {
  log "ERROR: $*"
  exit 1
}

usage_die() {
  printf '%s\n' "$1" >&2
  exit 64
}

absolute_path() {
  local candidate="$1"
  if [[ "${candidate}" = /* ]]; then
    printf '%s\n' "${candidate}"
  else
    printf '%s/%s\n' "${PROJECT_ROOT}" "${candidate#./}"
  fi
}

require_file() {
  [[ -f "$1" ]] || die "Required file not found: $1"
}

require_nonempty_file() {
  [[ -s "$1" ]] || die "Required non-empty file not found: $1"
}

require_command() {
  command -v "$1" >/dev/null 2>&1 || die "Required executable not found: $1"
}

sha256_file() {
  local input_file="$1"
  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum "${input_file}" | awk '{print $1}'
  elif command -v shasum >/dev/null 2>&1; then
    shasum -a 256 "${input_file}" | awk '{print $1}'
  else
    die "Neither sha256sum nor shasum is available"
  fi
}

load_project_config() {
  local config_path="$1"
  require_file "${config_path}"
  # shellcheck disable=SC1090
  source "${config_path}"

  : "${PROJECT_ROOT:?PROJECT_ROOT is required in the project configuration}"
  : "${RESULTS_DIR:?RESULTS_DIR is required in the project configuration}"
  : "${BOWTIE2_INDEX_PREFIX:?BOWTIE2_INDEX_PREFIX is required}"
  : "${MACS3_GENOME_SIZE:=mm}"
  : "${MITO_CONTIG:=chrM}"
  : "${THREADS:=8}"
  : "${JAVA_MEMORY:=16g}"
  : "${OVERWRITE:=false}"
  : "${STRICT_VERSION_CHECK:=false}"
  : "${USE_MODULES:=false}"
  : "${MAKE_BIGWIG:=true}"

  if [[ "${USE_MODULES}" == "true" ]]; then
    : "${MODULES_FILE:?MODULES_FILE is required when USE_MODULES=true}"
    require_file "${MODULES_FILE}"
    # shellcheck disable=SC1090
    source "${MODULES_FILE}"
  fi

  mkdir -p "${RESULTS_DIR}" "${LOG_DIR:-${RESULTS_DIR}/logs}"
}

validate_sample_sheet() {
  local sample_sheet="$1"
  require_nonempty_file "${sample_sheet}"

  local header
  header="$(head -n 1 "${sample_sheet}")"
  first_three="$(printf '%s\n' "${header}" | cut -f 1-3)"
  [[ "${first_three}" == $'sample_id\tfastq_r1\tfastq_r2' ]] || \
    die "Sample sheet must begin with: sample_id<TAB>fastq_r1<TAB>fastq_r2"

  if awk -F '\t' 'NR > 1 && $1 != "" {count[$1]++} END {for (id in count) if (count[id] > 1) exit 1}' "${sample_sheet}"; then
    :
  else
    die "Duplicate sample_id values detected in ${sample_sheet}"
  fi
}

sample_ids() {
  local sample_sheet="$1"
  awk -F '\t' 'NR > 1 && $1 != "" && $1 !~ /^#/ {print $1}' "${sample_sheet}"
}

sample_row() {
  local sample_sheet="$1"
  local sample_id="$2"
  awk -F '\t' -v id="${sample_id}" 'NR > 1 && $1 == id {print; found=1; exit} END {if (!found) exit 1}' "${sample_sheet}" || \
    die "Sample ID '${sample_id}' not found in ${sample_sheet}"
}

load_sample_fastqs() {
  local sample_sheet="$1"
  local requested_id="$2"
  local row
  row="$(sample_row "${sample_sheet}" "${requested_id}")"
  IFS=$'\t' read -r SAMPLE_ID FASTQ_R1 FASTQ_R2 SAMPLE_CONDITION SAMPLE_GENOTYPE SAMPLE_SEX SAMPLE_CELL_TYPE SAMPLE_BATCH SAMPLE_MOUSE_ID SAMPLE_REPLICATE SAMPLE_COHORT SAMPLE_NOTES <<< "${row}"
  FASTQ_R1="$(absolute_path "${FASTQ_R1}")"
  FASTQ_R2="$(absolute_path "${FASTQ_R2}")"
  require_nonempty_file "${FASTQ_R1}"
  require_nonempty_file "${FASTQ_R2}"
}

count_fastq_records() {
  local fastq="$1"
  local line_count
  if [[ "${fastq}" == *.gz ]]; then
    line_count="$(gzip -cd -- "${fastq}" | wc -l)"
  else
    line_count="$(wc -l < "${fastq}")"
  fi
  (( line_count % 4 == 0 )) || die "FASTQ line count is not divisible by four: ${fastq}"
  printf '%s\n' "$((line_count / 4))"
}

should_skip() {
  local output="$1"
  if [[ -s "${output}" && "${OVERWRITE}" != "true" ]]; then
    log "Output exists; skipping (set OVERWRITE=true to replace): ${output}"
    return 0
  fi
  return 1
}

run_picard() {
  if [[ -n "${PICARD_JAR:-}" ]]; then
    require_file "${PICARD_JAR}"
    "${JAVA_BIN:-java}" "-Xmx${JAVA_MEMORY}" -jar "${PICARD_JAR}" "$@"
  else
    JAVA_OPTS="${JAVA_OPTS:-} -Xmx${JAVA_MEMORY}" "${PICARD_BIN}" "$@"
  fi
}

picard_available_name() {
  if [[ -n "${PICARD_JAR:-}" ]]; then
    printf '%s\n' "${JAVA_BIN:-java}"
  else
    printf '%s\n' "${PICARD_BIN}"
  fi
}

trimmed_r1() {
  printf '%s/trimmed_fastq/%s.ngmerge_1.fastq\n' "${RESULTS_DIR}" "$1"
}

trimmed_r2() {
  printf '%s/trimmed_fastq/%s.ngmerge_2.fastq\n' "${RESULTS_DIR}" "$1"
}

aligned_bam() {
  printf '%s/bam/aligned/%s.mm10.sorted.bam\n' "${RESULTS_DIR}" "$1"
}

clean_bam() {
  printf '%s/bam/clean/%s.noDup.rmChrM.bam\n' "${RESULTS_DIR}" "$1"
}

sample_peak_file() {
  printf '%s/peaks/%s/%s_peaks.narrowPeak\n' "${RESULTS_DIR}" "$1" "$1"
}

consensus_bed() {
  printf '%s/consensus/consensus_peaks.bed\n' "${RESULTS_DIR}"
}

assert_boolean() {
  [[ "$2" == "true" || "$2" == "false" ]] || die "$1 must be true or false; observed '$2'"
}
