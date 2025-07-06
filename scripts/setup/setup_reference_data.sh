#!/bin/bash

# Setup reference data for BPNet pipeline - genome files, blacklist, GC reference
# Usage: ./setup_reference_data.sh <environment_name>

set -e  # Exit on any error

if [ $# -ne 1 ]; then
    echo "Usage: $0 <environment_name>"
    echo "Example: $0 bpnet-m1"
    exit 1
fi

ENV_NAME=$1

# Initialize conda for this shell session
echo "Initializing conda and activating environment: $ENV_NAME"
eval "$(conda shell.bash hook)"
conda activate "$ENV_NAME"

echo "=========================================="
echo "BPNet Reference Data Setup"
echo "=========================================="

# Create reference directory structure
echo "Creating reference directory structure..."
mkdir -p reference/hg38

# Download genome reference
echo "Downloading genome reference..."
if [ ! -f reference/hg38/hg38.genome.fa ]; then
    wget https://www.encodeproject.org/files/GRCh38_no_alt_analysis_set_GCA_000001405.15/@@download/GRCh38_no_alt_analysis_set_GCA_000001405.15.fasta.gz -O reference/hg38/hg38.genome.fa.gz
    gunzip reference/hg38/hg38.genome.fa.gz
    echo "Indexing genome reference..."
    samtools faidx reference/hg38/hg38.genome.fa
else
    echo "Genome reference already exists, skipping download"
fi

# Download and process chromosome sizes
echo "Getting and processing chromosome sizes..."
if [ ! -f reference/hg38/hg38.chrom.sizes ]; then
    wget https://www.encodeproject.org/files/GRCh38_EBV.chrom.sizes/@@download/GRCh38_EBV.chrom.sizes.tsv -O reference/hg38/GRCh38_EBV.chrom.sizes.tsv
    # exclude alt contigs and chrEBV
    grep -v -e '_' -e 'chrEBV' reference/hg38/GRCh38_EBV.chrom.sizes.tsv > reference/hg38/hg38.chrom.sizes
    rm reference/hg38/GRCh38_EBV.chrom.sizes.tsv
    # make file with chromosomes only
    awk '{print $1}' reference/hg38/hg38.chrom.sizes > reference/hg38/chroms.txt
else
    echo "Chromosome sizes already exist, skipping download"
fi

# Download blacklist
echo "Downloading blacklist..."
if [ ! -f reference/hg38/blacklist.bed ]; then
    wget https://www.encodeproject.org/files/ENCFF356LFX/@@download/ENCFF356LFX.bed.gz -O reference/hg38/blacklist.bed.gz
    gunzip reference/hg38/blacklist.bed.gz
else
    echo "Blacklist already exists, skipping download"
fi

# Create GC reference
echo "Creating GC reference..."
if [ ! -f reference/hg38/genomewide_gc_stride_1000_flank_size_1057.gc.bed ]; then
    python ./bpnet-refactor/bpnet/cli/gc/get_genomewide_gc_bins.py \
        --ref_fasta reference/hg38/hg38.genome.fa \
        --chrom_sizes reference/hg38/hg38.chrom.sizes \
        --output_prefix reference/hg38/genomewide_gc_stride_1000_flank_size_1057.gc \
        --inputlen 2114 \
        --stride 1000
else
    echo "GC reference already exists, skipping creation"
fi

# Note: bpnet_params.json is now created per-sample in step 6 with calculated counts loss weight

# Note: splits.json is now created per-sample in step 6 alongside bpnet_params.json

echo ""
echo "=========================================="
echo "Reference data setup completed successfully!"
echo "Reference files created in: reference/hg38/"
echo "Sample-specific configs (bpnet_params.json, splits.json) created during sample processing"
echo "=========================================="
echo ""