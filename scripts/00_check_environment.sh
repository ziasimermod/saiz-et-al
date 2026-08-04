#!/usr/bin/env bash

set -euo pipe fail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck source=lib/common.sh
source "${SCRIPT_DIR}/lib/common.sh"

[[ $# -eq 2 ]] || usage_die "Usage: $0 <project_config.sh> <samples.tsv>"
CONFIG="$1"
SAMPLE_SHEET="$2"

load_project_config "${CONFIG}"
validate_sample_sheet "${SAMPLE_SHEET}"
assert_boolean "OVERWRITE" "${OVERWRITE}"
assert_boolean "STRICT_VERSION_CHECK" "${STRICT_VERSION_CHECK}"
assert_boolean "MAKE_BIGWIG" "${MAKE_BIGWIG}"

required_bins=(
  "${FASTQC_BIN}"
  "${NGMERGE_BIN}"
  "${BOWTIE2_BIN}"
  "${SAMTOOLS_BIN}"
  "$(picard_available_name)"
  "${MACS3_BIN}"
  "${BEDTOOLS_BIN}"
)
if [[ "${MAKE_BIGWIG}" == "true" ]]; then
  required_bins+=("${BAMCOVERAGE_BIN}")
fi
for required_bin in "${required_bins[@]}"; do
  require_command "${required_bin}"
done

if ! compgen -G "${BOWTIE2_INDEX_PREFIX}*.bt2*" >/dev/null; then
  die "No Bowtie2 index files match ${BOWTIE2_INDEX_PREFIX}*.bt2*"
fi

sample_count=0
while IFS= read -r sample_id; do
  load_sample_fastqs "${SAMPLE_SHEET}" "${sample_id}"
  sample_count=$((sample_count + 1))
done < <(sample_ids "${SAMPLE_SHEET}")
(( sample_count > 0 )) || die "No samples found in ${SAMPLE_SHEET}"

version_dir="${RESULTS_DIR}/versions"
mkdir -p "${version_dir}"
version_file="${version_dir}/software_versions_observed.tsv"
printf 'software\texpected_version\tobserved_version\n' > "${version_file}"

record_version() {
  local software="$1"
  local expected="$2"
  local observed="$3"
  observed="${observed//$'\t'/ }"
  observed="${observed//$'\n'/ }"
  printf '%s\t%s\t%s\n' "${software}" "${expected}" "${observed}" >> "${version_file}"
  if [[ "${observed}" != *"${expected}"* ]]; then
    if [[ "${STRICT_VERSION_CHECK}" == "true" ]]; then
      die "${software}: expected version ${expected}; observed '${observed}'"
    fi
    log "WARNING: ${software}: expected version ${expected}; observed '${observed}'"
  fi
}

record_version "FastQC" "0.12.1" "$("${FASTQC_BIN}" --version 2>&1 | head -n 1)"
record_version "NGMerge" "0.5" "$("${NGMERGE_BIN}" -h 2>&1 | head -n 1 || true)"
record_version "Bowtie2" "2.4.2" "$("${BOWTIE2_BIN}" --version 2>&1 | head -n 1)"
record_version "samtools" "1.12" "$("${SAMTOOLS_BIN}" --version 2>&1 | head -n 1)"
if [[ -n "${PICARD_JAR:-}" ]]; then
  picard_version="$("${JAVA_BIN:-java}" -jar "${PICARD_JAR}" MarkDuplicates --version 2>&1 | head -n 1 || true)"
else
  picard_version="$("${PICARD_BIN}" MarkDuplicates --version 2>&1 | head -n 1 || true)"
fi
record_version "Picard" "2.9.0" "${picard_version}"
record_version "MACS3" "3.0.1" "$("${MACS3_BIN}" --version 2>&1 | head -n 1)"
record_version "bedtools2" "2.31.1" "$("${BEDTOOLS_BIN}" --version 2>&1 | head -n 1)"
if [[ "${MAKE_BIGWIG}" == "true" ]]; then
  record_version "deepTools" "3.5.5" "$("${BAMCOVERAGE_BIN}" --version 2>&1 | head -n 1)"
fi

log "Environment validation passed for ${sample_count} samples."
log "Observed versions: ${version_file}"

