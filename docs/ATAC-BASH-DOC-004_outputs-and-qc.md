# Output and QC data dictionary

**Article ID:** ATAC-BASH-DOC-004

## Primary directory structure (Important for full workflow)

```text
results/
├── fastqc/raw/<sample>/
├── trimmed_fastq/
├── bam/
│   ├── aligned/
│   └── clean/
├── peaks/<sample>/
├── consensus/
├── counts/
├── bigwig/
├── qc/
│   ├── alignment/
│   ├── duplicates/
│   ├── fragment_size/<sample>/
│   ├── idxstats/
│   ├── metrics/
│   └── ATACseq_QC_summary.tsv
├── versions/
└── logs/
```

## Downstream handoff files

| File | Meaning | Expected consumer |
| --- | --- | --- |
| `consensus/consensus_peaks.bed` | Four-column mm10 union peak set with stable `consensus_peak_######` identifiers | R differential-accessibility compendium; annotation workflows |
| `counts/consensus_peak_counts.tsv` | BED coordinates, peak ID, then one raw-count column per sample in sample-sheet order | ComBat_seq/DESeq2 R workflow |
| `qc/ATACseq_QC_summary.tsv` | One row per library containing all Methods-listed QC categories | Table S3 and pre-analysis sample review |
| `config/samples.tsv` | Unique library identity and biological metadata | All downstream design matrices and contrasts |
| `bigwig/*.CPM.bw` | CPM-normalized display tracks | IGV/deepTools locus visualization only |

## Combined QC fields

| Column | Definition | Unit / denominator |
| --- | --- | --- |
| `sample_id` | Unique sample-sheet identifier | text |
| `raw_read_pairs` | FASTQ records in either mate after verifying R1 = R2 | pairs |
| `raw_reads` | R1 records + R2 records | reads |
| `bowtie2_alignment_rate_percent` | Bowtie2 “overall alignment rate” | percent of reads |
| `mitochondrial_read_fraction` | chrM mapped records before mitochondrial removal / all mapped reference records | fraction 0-1 |
| `mitochondrial_read_percent` | Same quantity multiplied by 100 | percent |
| `picard_duplicate_fraction` | Picard `PERCENT_DUPLICATION` | fraction 0-1 |
| `picard_duplicate_percent` | Same quantity multiplied by 100 | percent |
| `clean_alignment_records` | samtools record count after mitochondrial and duplicate removal | alignment records |
| `clean_read_pairs` | first-in-pair records in the cleaned BAM | pairs |
| `median_insert_size` | Picard insert-size metric | base pairs |
| `mean_insert_size` | Picard insert-size metric | base pairs |
| `insert_size_sd` | Picard insert-size standard deviation | base pairs |
| `frip_fraction` | cleaned alignment records overlapping that sample's MACS3 peaks / all cleaned alignment records | fraction 0-1 |
| `frip_percent` | Same quantity multiplied by 100 | percent |
| `peak_count` | Number of rows in the sample narrowPeak file | peaks |

The complete fragment-size distribution is retained in the per-sample Picard metrics table and histogram PDF; the combined table contains only compact summary statistics.

## Count-matrix interpretation

`bedtools multicov` reports the number of cleaned BAM alignment records overlapping each consensus interval. These are integer counts for count-based modeling and should not be normalized in Bash. Normalization, batch correction, variance stabilization, and differential accessibility belong in the R compendium.

The sample column order is deterministic: it is the order of non-comment data rows in `config/samples.tsv`.

## Sample metadata fields

Only `sample_id`, `fastq_r1`, and `fastq_r2` are required by the Bash scripts. The remaining columns provide a single authoritative metadata handoff to the R compendium.

| Column | Expected content |
| --- | --- |
| `sample_id` | Unique library identifier; preferably the stable GEO/library basename |
| `fastq_r1`, `fastq_r2` | Absolute paths or paths relative to the repository root |
| `condition` | Controlled analysis group such as `CD`, `HFD`, `HFD_1wk`, `HFD_4wk`, `DRC`, or `fasted` |
| `genotype` | Controlled genotype label used in the R design |
| `sex` | `F` or `M`, using one convention throughout |
| `cell_type` | `ISC` or `TAC` |
| `sequencing_batch` | Stable batch label such as `batch1`, `batch2`, or `batch3` |
| `mouse_id` | Biological animal identifier; one library per mouse |
| `biological_replicate` | Replicate number within the biological group |
| `experimental_cohort` | Higher-level cohort label used to distinguish chronic diet, withdrawal, genetic, or other experiments |
| `notes` | Optional short note; avoid tabs inside this field |
