#!/usr/bin/env bash

# Submit after the sample array succeeds, for example:
# sbatch --dependency=afterok:<array_job_id> slurm/02_finalize_cohort.sbatch config/project_config.sh config/samples.tsv

#SBATCH --job-name=atac_cohort
#SBATCH --cpus-per-task=4
#SBATCH --mem=64G
#SBATCH --time=08:00:00
#SBATCH --output=results/logs/slurm/atac_cohort_%j.out
#SBATCH --error=results/logs/slurm/atac_cohort_%j.err

set -euo pipefail
[[ $# -eq 2 ]] || { printf 'Usage: sbatch %s <config> <samples.tsv>\n' "$0" >&2; exit 64; }
SLURM_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "${SLURM_DIR}/.." && pwd)"
mkdir -p "${ROOT}/results/logs/slurm"
bash "${ROOT}/scripts/run_cohort.sh" "$1" "$2"

