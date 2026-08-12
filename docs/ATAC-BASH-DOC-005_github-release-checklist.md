# GitHub release checklist

**Article ID:** ATAC-BASH-DOC-005

## Validation against deposited/figure data

- [ ] Run `bash tests/validate_compendium.sh`.
- [ ] Run `scripts/00_check_environment.sh` with strict version checking enabled in a validation configuration.

## Repository hygiene

- [ ] Do not commit raw FASTQ, BAM, bigWig, generated results, cluster logs, private paths, or access tokens.
- [ ] Add the paper citation, DOI/preprint link, GEO accession GSE317375, and contact information to the repository-level README.
- [ ] Tag the exact release used for manuscript submission and record the tag/commit in the Data and Code Availability statement.
