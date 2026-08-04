#!/usr/bin/env bash

# Submit with: sbatch --array=1-N slurm/01_process_samples.sbatch config/project_config.sh config/samples.tsv
# Replace N with the number of non-header sample rows (70 for our samples).

#SBATCH --job-name=atac_samples
#SBATCH --cpus-per-task=8
#SBATCH --mem=32G
#SBATCH --time=12:00:00
#SBATCH --output=results/logs/slurm/atac_samples_%A_%a.out
#SBATCH --error=results/logs/slurm/atac_samples_%A_%a.err

set -euo pipefail
[[ $# -eq 2 ]] || { printf 'Usage: sbatch --array=1-N %s <config> <samples.tsv>\n' "$0" >&2; exit 64; }
[[ -n "${SLURM_ARRAY_TASK_ID:-}" ]] || { printf 'SLURM_ARRAY_TASK_ID is not set.\n' >&2; exit 1; }

SLURM_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "${SLURM_DIR}/.." && pwd)"
sample_id="$(awk -F '\t' -v row="$((SLURM_ARRAY_TASK_ID + 1))" 'NR == row {print $1}' "$2")"
[[ -n "${sample_id}" ]] || { printf 'No sample for array task %s.\n' "${SLURM_ARRAY_TASK_ID}" >&2; exit 1; }

mkdir -p "${ROOT}/results/logs/slurm"
bash "${ROOT}/scripts/run_sample.sh" "$1" "$2" "${sample_id}"

