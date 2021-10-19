# Demo of a toy pipeline built with nf-core
Given GEO ID, retrieve sample_sheet.csv, download fastq files, perform FastQC, and cutadapt. Finally, generate a MultiQC report.

## Setup Nextflow, nf-core, initiate template:
Check out setup.md.

## Functionalities
## Mode 1: --geo
Given a text file containing GEO ids, retrieve a sample sheet tsv file containing ftp links.
```bash
nextflow run main.nf --geo assets/test_geo.txt -profile docker
```

## Mode 2: --input
Given sample sheet tsv file containing ftp links, download fastq files and perform FastQC and Cutadapt.
```bash
nextflow run main.nf --input results/merge/combined.tsv -profile docker
```
