#!/usr/bin/env bash

# Copy this file to config/project_config.sh and edit site-specific paths.

# The repository root is resolved relative to this configuration file.
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
RESULTS_DIR="${PROJECT_ROOT}/results"
LOG_DIR="${RESULTS_DIR}/logs"

# Reference genome (STAR Methods: mouse mm10/GRCm38).

BOWTIE2_INDEX_PREFIX="/path/to/mm10/bowtie2/genome"
GENOME_BUILD="mm10/GRCm38"
MACS3_GENOME_SIZE="mm"
MITO_CONTIG="chrM"

# Execution controls.
THREADS=8
JAVA_MEMORY="16g"
OVERWRITE=false
STRICT_VERSION_CHECK=false
USE_MODULES=false
MODULES_FILE="${PROJECT_ROOT}/config/modules.example.sh"

# Executable names or absolute paths.
FASTQC_BIN="fastqc"
NGMERGE_BIN="NGmerge"
BOWTIE2_BIN="bowtie2"
SAMTOOLS_BIN="samtools"
PICARD_BIN="picard"
PICARD_JAR=""
JAVA_BIN="java"
MACS3_BIN="macs3"
BEDTOOLS_BIN="bedtools"
BAMCOVERAGE_BIN="bamCoverage"

# MACS3 settings
MACS3_QVALUE="0.05"

# Visualization-track settings. These tracks are not used for differential
# accessibility testing. CPM is the normalization used for the paper tracks.
MAKE_BIGWIG=true
BIGWIG_NORMALIZATION="CPM"   # One of: RPKM, CPM, BPM, RPGC, None
BIGWIG_BIN_SIZE=1
BLACKLIST_BED="{/path/to/blackist.bed}"             
BIGWIG_SCALE_FACTORS_TSV=""  # Optional two-column file: sample_id	scale_factor
