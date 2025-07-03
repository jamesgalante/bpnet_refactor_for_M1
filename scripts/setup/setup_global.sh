#!/bin/bash

# Global setup for BPNet pipeline - reference files and global configurations
# Usage: ./setup_global.sh <environment_name>

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
echo "Global BPNet Setup"
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
    python bpnet-refactor/bpnet/cli/bpnet_gc_reference.py \
        --ref_fasta reference/hg38/hg38.genome.fa \
        --chrom_sizes reference/hg38/hg38.chrom.sizes \
        --output_prefix reference/hg38/genomewide_gc_stride_1000_flank_size_1057.gc \
        --inputlen 2114 \
        --stride 1000
else
    echo "GC reference already exists, skipping creation"
fi

# Create global BPNet parameters JSON
echo "Creating global BPNet parameters..."
cat > bpnet_params.json << 'EOF'
{
    "input_len": 2114,
    "output_profile_len": 1000,
    "motif_module_params": {
        "filters": [64],
        "kernel_sizes": [21],
        "padding": "valid"
    },
    "syntax_module_params": {
        "num_dilation_layers": 8,
        "filters": 64,
        "kernel_size": 3,
        "padding": "valid",
        "pre_activation_residual_unit": true
    },
    "profile_head_params": {
        "filters": 1,
        "kernel_size":  75,
        "padding": "valid"
    },
    "counts_head_params": {
        "units": [1],
        "dropouts": [0.0],
        "activations": ["linear"]
    },
    "profile_bias_module_params": {
        "kernel_sizes": [1]
    },
    "counts_bias_module_params": {
    },
    "use_attribution_prior": false,
    "attribution_prior_params": {
        "frequency_limit": 150,
        "limit_softness": 0.2,
        "grad_smooth_sigma": 3,
        "profile_grad_loss_weight": 200,
        "counts_grad_loss_weight": 100        
    },
    "loss_weights": [1, 42],
    "counts_loss": "MSE"
}
EOF

# Create global splits JSON
echo "Creating global chromosome splits..."
cat > splits.json << 'EOF'
{
    "0": {
        "test":
            ["chr7", "chr13", "chr17", "chr19", "chr21", "chrX"],
        "val":
            ["chr10", "chr18"],
        "train":
            ["chr1", "chr2", "chr3", "chr4", "chr5", "chr6", "chr8", "chr9", "chr11", "chr12", "chr14", "chr15", "chr16", "chr20", "chr22", "chrY"]
    }
}
EOF

echo ""
echo "=========================================="
echo "Global setup completed successfully!"
echo "Reference files created in: reference/hg38/"
echo "Global configs created: bpnet_params.json, splits.json"
echo "=========================================="
echo ""