#!/bin/bash

# Create splits.json file for train/val/test chromosome splits
echo "Creating splits.json file"

BASE_DIR=ENCSR000EGM

cat > $BASE_DIR/splits.json << 'EOF'
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

echo "splits.json created successfully"