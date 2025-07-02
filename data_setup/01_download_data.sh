#!/bin/bash

# Make directories if they don't exist
echo "Making directories"
mkdir -p ENCSR000EGM/data/
mkdir -p ENCSR000EGM/reference/


# Download the ChIP-Seq data
echo "Downloading replicate 1"
wget https://www.encodeproject.org/files/ENCFF198CVB/@@download/ENCFF198CVB.bam -O ENCSR000EGM/data/rep1.bam
echo "Downloading replicate 2"
wget https://www.encodeproject.org/files/ENCFF488CXC/@@download/ENCFF488CXC.bam -O ENCSR000EGM/data/rep2.bam
echo "Downloading control"
wget https://www.encodeproject.org/files/ENCFF023NGN/@@download/ENCFF023NGN.bam -O ENCSR000EGM/data/control.bam


# Download genome refrence
echo "Downloading genome fassta files"
wget https://www.encodeproject.org/files/GRCh38_no_alt_analysis_set_GCA_000001405.15/@@download/GRCh38_no_alt_analysis_set_GCA_000001405.15.fasta.gz -O ENCSR000EGM/reference/hg38.genome.fa.gz
gunzip ENCSR000EGM/reference/hg38.genome.fa.gz
# index genome reference
echo "Indexing genome reference"
samtools faidx ENCSR000EGM/reference/hg38.genome.fa

# Download chrom sizes
echo "Getting and processing chromosome sizes"
wget https://www.encodeproject.org/files/GRCh38_EBV.chrom.sizes/@@download/GRCh38_EBV.chrom.sizes.tsv -O ENCSR000EGM/reference/GRCh38_EBV.chrom.sizes.tsv
# exclude alt contigs and chrEBV
grep -v -e '_' -e 'chrEBV' ENCSR000EGM/reference/GRCh38_EBV.chrom.sizes.tsv > ENCSR000EGM/reference/hg38.chrom.sizes
rm ENCSR000EGM/reference/GRCh38_EBV.chrom.sizes.tsv
# make file with chromosomes only
awk '{print $1}' ENCSR000EGM/reference/hg38.chrom.sizes > ENCSR000EGM/reference/chroms.txt

# Download blacklist
echo "Download the blacklist"
wget https://www.encodeproject.org/files/ENCFF356LFX/@@download/ENCFF356LFX.bed.gz -O ENCSR000EGM/reference/blacklist.bed.gz
gunzip ENCSR000EGM/reference/blacklist.bed.gz
