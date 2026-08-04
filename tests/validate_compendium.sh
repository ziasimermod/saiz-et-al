#!/usr/bin/env bash
# Artifact ID: ATAC-BASH-TEST-001
# Static validation that does not require bioinformatics software or data.

set -euo pipefail
TEST_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "${TEST_DIR}/.." && pwd)"

fail() {
  printf 'FAIL: %s\n' "$*" >&2
  exit 1
}

required_files=(
  README.md
  FILE_MANIFEST.tsv
  config/project_config.example.sh
  config/samples.example.tsv
  config/modules.example.sh
  config/software_versions.tsv
  scripts/00_check_environment.sh
  scripts/01_fastqc.sh
  scripts/02_ngmerge.sh
  scripts/03_align_bowtie2.sh
  scripts/04_filter_and_deduplicate.sh
  scripts/05_call_peaks_macs3.sh
  scripts/06_build_consensus_peaks.sh
  scripts/07_count_consensus_reads.sh
  scripts/08_collect_qc_metrics.sh
  scripts/09_make_bigwig.sh
  scripts/run_sample.sh
  scripts/run_cohort.sh
  scripts/run_atac_pipeline.sh
)
for path in "${required_files[@]}"; do
  [[ -s "${ROOT}/${path}" ]] || fail "Missing required file: ${path}"
done

while IFS= read -r script; do
  bash -n "${script}" || fail "Bash syntax error: ${script}"
done < <(find "${ROOT}/scripts" "${ROOT}/slurm" "${ROOT}/tests" -type f \( -name '*.sh' -o -name '*.sbatch' \) | sort)

grep -F -- '--very-sensitive' "${ROOT}/scripts/03_align_bowtie2.sh" >/dev/null || fail "Bowtie2 --very-sensitive is missing"
grep -F -- '-f BAMPE' "${ROOT}/scripts/05_call_peaks_macs3.sh" >/dev/null || fail "MACS3 BAMPE mode is missing"
grep -F 'MACS3_QVALUE="0.05"' "${ROOT}/config/project_config.example.sh" >/dev/null || fail "MACS3 q=0.05 is missing"
grep -F 'BIGWIG_NORMALIZATION="CPM"' "${ROOT}/config/project_config.example.sh" >/dev/null || fail "CPM bigWig normalization is missing"
grep -F 'bedtools' "${ROOT}/scripts/07_count_consensus_reads.sh" >/dev/null || fail "bedtools consensus counting is missing"

if grep -R -E -- '(-k[[:space:]]+10|hmmratac|callBroadPeak|featureCounts|/scratch/dsaiz)' "${ROOT}/scripts" "${ROOT}/slurm" >/dev/null; then
  fail "A deprecated or user-specific command remains in executable workflow files"
fi

printf 'PASS: static structure, syntax, and Methods-alignment checks succeeded.\n'
