# Historical Bash script audit

**Artifact ID:** ATAC-BASH-DOC-003  
**Source audited:** `AllScripts.zip` supplied on 2026-08-04.

The archive contains 152 `.sh` files plus one Python utility. It mixes paper ATAC-seq preprocessing, alternative/experimental peak-calling paths, RNA/scRNA processing, visualization, motif analysis, scheduler templates, copied package tests/configuration files, and one-off file-management commands. It should not be uploaded to GitHub as a flat “analysis scripts” directory.

## Historical files consolidated into the canonical workflow

| Function | Principal historical evidence | Canonical replacement |
| --- | --- | --- |
| Raw read QC | `fastqc.sh` | `scripts/01_fastqc.sh` |
| Adapter-overlap trimming | `NGmerge.sh` | `scripts/02_ngmerge.sh` |
| Bowtie2 alignment | `align.sh`, `faster_align.sh`, `bam_to_fastq_to_align*.sh` | `scripts/03_align_bowtie2.sh` |
| Mitochondrial filtering | `rmChrM.sh`, `rmChrM1.sh`, `idxstats.sh` | `scripts/04_filter_and_deduplicate.sh` plus QC metrics |
| Duplicate removal | `rmDup.sh` | `scripts/04_filter_and_deduplicate.sh` |
| Individual-library narrow peaks | `callpeak_macs3.sh`, `callremainingpeak_macs3.sh` | `scripts/05_call_peaks_macs3.sh` |
| Union peak merging | `generateUnionPeakSetsStandard.sh`, `run_bedtoolsmerge.sh`, portions of `generateConsensusRegions.sh` | `scripts/06_build_consensus_peaks.sh` |
| Consensus-region counts | `ReadCountsPerRegion_standard.sh`, `readcounts_as_array.sh` | `scripts/07_count_consensus_reads.sh` |
| QC summaries | `depth.sh`, `idxstats.sh`, `FRiP_calc.sh`, Picard metrics | `scripts/08_collect_qc_metrics.sh` |
| Browser tracks | `BigWigGen.sh`, `run_bigwigGen.sh` | `scripts/09_make_bigwig.sh` |

## Conflicts resolved using the STAR Methods

| Historical behavior | STAR Methods ground truth | Resolution |
| --- | --- | --- |
| FastQC v0.11.9 | v0.12.1 | Updated version record/module/environment. |
| Bowtie2 v2.4.1 with `-k 10` | v2.4.2 with `--very-sensitive`; no multi-alignment flag reported | Updated version and removed `-k 10`. |
| samtools v1.12, v1.15, and v1.16 mixed across files | v1.12 | Canonical version pinned to v1.12. |
| Picard v2.9.2 in `rmDup.sh` | v2.9.0 | Canonical version pinned to v2.9.0. |
| bedtools v2.24/v2.30/v2.31.1 mixed | v2.31.1 | Canonical version pinned to v2.31.1. |
| Pooled condition-level MACS3 calls in `run_macs3_*` | peaks called on individual samples | Pooled scripts excluded. |
| HMMRATAC and broad-peak alternatives | Definitive matrix uses individual-library MACS3 narrowPeak intervals | Alternative broadPeak/HMM representations were generated but excluded after batch-associated shifts. |
| `generateConsensusRegions.sh` filters narrowPeak score column 9 > 10 (q < 1e-10) | only MACS3 q = 0.05 is reported | Extra filtering excluded. |
| `stringentConsensus.sh` requires six samples | no support threshold reported | Minimum-support branch excluded. |
| featureCounts used for FRiP/count experiments | consensus counts and confirmed FRiP implementation use bedtools2 | Consensus counts use bedtools multicov and FRiP uses bedtools overlap; the featureCounts experiments are excluded. |

## Branches excluded from the Bash preprocessing compendium

- **RNA-seq/STAR/Subread:** `RNAalign.sh`, `QCandAlign.sh`, `run_STARalignment.sh`, `run_STARgenomeindex.sh`, `run_featureCounts.sh`, `run_featurCounts_old.sh`, and Subread test files. The paper integration begins from public counts, so these are not the reported pipeline.
- **Single-cell/UMI/Cell Ranger:** `run_cellranger.sh`, `run_UMI*.sh`, BBMap scripts, and related utilities. These are unrelated to the primary bulk ATAC-seq workflow.
- **Alternative peak models:** `hmmratac_*`, `hmmusingmacs3.sh`, `callBroadpeak_macs3.sh`, and HMM union/count scripts document exploratory outputs. These outputs were not used for the definitive consensus/count matrix because of batch-associated shifts.
- **Condition-pooled peak calls:** the `run_macs3_<condition>.sh` family. These hard-code sample names and contradict individual-library peak calling.
- **Downstream visualization/annotation/motifs:** computeMatrix/heatmap families, HOMER motif scripts, modality heatmaps, peak annotations, and bespoke region intersections. These should be represented in the later downstream/R compendium only when they map to a reported figure or result.
- **Repository noise:** Tcl/Tk configuration scripts, featureCounts test fixtures, QR generation, debug helpers, and one-off movement/archiving scripts.

## Recurrent technical problems removed

- Absolute `/scratch/dsaiz/...` paths and personal email addresses.
- Fixed array bounds and hard-coded sample lists that silently drift from metadata.
- Inconsistent input/output suffixes and misspelled “concensus” paths.
- Commands using undefined variables, including `sample` in `faster_align.sh`.
- Invalid shebang text (`x#!/bin/bash`) in `run_bigwigGen.sh`.
- A variable-name error in `TSS_calc.sh` that calculates `tss_score` but writes `frip_score`.
- A misspelled `mambe/latest` module in the FRiP featureCounts script.
- Reliance on `ls` expansion for array indexing and nondeterministic file order.
- Group-specific scripts that duplicate the same command with only sample names changed.
- Peak de-duplication and extra significance filters applied after MACS3 without corresponding Methods support.

## Archival recommendation

Keep the original zip outside the executable GitHub workflow as private provenance if desired. Do not mix it into the public `scripts/` directory. If it is retained publicly, place it under a clearly labeled `archive/not_executed/` location and state that it is superseded by this compendium.
