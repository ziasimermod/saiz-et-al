#!/usr/bin/env bash

# Site-specific module identifiers vary. Edit only the identifiers on the
# right; the requested versions are the versions reported in the STAR Methods.

MODULE_SPECS=(
  "fastqc/0.12.1"
  "ngmerge/0.5"
  "bowtie2/2.4.2"
  "samtools/1.12"
  "picard/2.9.0"
  "macs3/3.0.1"
  "bedtools/2.31.1"
  "deeptools/3.5.5"
)

if ! command -v module >/dev/null 2>&1; then
  printf 'ERROR: USE_MODULES=true but the module command is unavailable.\n' >&2
  return 1 2>/dev/null || exit 1
fi

for module_spec in "${MODULE_SPECS[@]}"; do
  module load "${module_spec}"
done