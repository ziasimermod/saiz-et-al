# GitHub release checklist

**Artifact ID:** ATAC-BASH-DOC-005

Complete this checklist before treating the compendium as the definitive paper code release.

## Paper-specific configuration

- [ ] Replace example sample rows with every deposited ATAC-seq library and verify one row per mouse.
- [ ] Confirm sample IDs match GEO filenames and the downstream R metadata exactly.
- [ ] Set the definitive mm10/GRCm38 Bowtie2 index prefix and record the reference/index checksum or source.
- [ ] Confirm the mitochondrial contig is `chrM` in that index.
- [ ] Replace module identifiers with the exact identifiers available on the execution cluster, or confirm the pinned Conda environment solves.

## Confirmed analysis choices

- [x] MACS3 summit and broad-peak outputs were generated; broadPeak and standalone summit files were not used for the definitive consensus/count matrix after batch-associated shifts.
- [x] Browser tracks use CPM normalization.
- [x] FRiP uses bedtools overlap.
- [ ] Confirm whether an mm10 blacklist was applied to the displayed CPM browser tracks.

## Validation against deposited/figure data

- [ ] Run `bash tests/validate_compendium.sh`.
- [ ] Run `scripts/00_check_environment.sh` with strict version checking enabled in a validation configuration.
- [ ] Compare raw depth, alignment rate, mitochondrial fraction, duplicate rate, insert-size summaries, FRiP, and peak counts with Table S3.
- [ ] Compare per-sample narrowPeak row counts and checksums with deposited processed files where available.
- [ ] Compare consensus peak count and coordinates with the 104,706-region analysis object described in the manuscript workflow.
- [ ] Compare consensus count-matrix dimensions, sample order, and several randomly selected peak/sample counts with the R input object.
- [ ] Open representative bigWig tracks in IGV and compare displayed loci with the manuscript figures.

## Repository hygiene

- [ ] Do not commit raw FASTQ, BAM, bigWig, generated results, cluster logs, private paths, or access tokens.
- [ ] Obtain Write access to `ManaStemLab/ManaStemLab` from the organization owner before the initial push.
- [ ] Decide and add a repository license.
- [ ] Add the paper citation, DOI/preprint link, GEO accession GSE317375, and contact information to the repository-level README.
- [ ] Tag the exact release used for manuscript submission and record the tag/commit in the Data and Code Availability statement.
- [ ] Preserve the original dated archive only in a clearly marked non-executable provenance location, if it is published at all.
