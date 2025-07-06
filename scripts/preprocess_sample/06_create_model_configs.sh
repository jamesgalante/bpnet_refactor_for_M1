#!/bin/bash

# Create model configuration files (bpnet_params.json, splits.json) with calculated counts loss weight
# Usage: ./06_create_model_configs.sh <sample_directory>

set -e  # Exit on any error

if [ $# -ne 1 ]; then
    echo "Usage: $0 <sample_directory>"
    echo "Example: $0 samples/ENCSR000EGM"
    exit 1
fi

SAMPLE_DIR=$1

echo "Creating model configuration files with optimal counts loss weight"

INPUT_DATA="$SAMPLE_DIR/results/input_data.json"

# Run bpnet-counts-loss-weight command and capture the output
echo "Running bpnet-counts-loss-weight command..."
COUNTS_LOSS_WEIGHT=$(python ../../bpnet-refactor/bpnet/cli/counts_loss_weight.py --input-data "$INPUT_DATA")

echo "Calculated counts loss weight: $COUNTS_LOSS_WEIGHT"

# Save the weight value to a log file in the sample directory
echo "Counts loss weight: $COUNTS_LOSS_WEIGHT" > "$SAMPLE_DIR/counts_loss_weight.log"
echo "Generated on: $(date)" >> "$SAMPLE_DIR/counts_loss_weight.log"

# Create sample-specific bpnet_params.json with the calculated weight
echo "Creating sample-specific bpnet_params.json..."
cat > "$SAMPLE_DIR/bpnet_params.json" << EOF
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
    "loss_weights": [1, $COUNTS_LOSS_WEIGHT],
    "counts_loss": "MSE"
}
EOF

# Create sample-specific splits.json
echo "Creating sample-specific splits.json..."
cat > "$SAMPLE_DIR/splits.json" << 'EOF'
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

echo "Counts loss weight calculation completed"
echo "Sample-specific bpnet_params.json created at: $SAMPLE_DIR/bpnet_params.json"
echo "Sample-specific splits.json created at: $SAMPLE_DIR/splits.json"
echo "Weight value logged at: $SAMPLE_DIR/counts_loss_weight.log"
