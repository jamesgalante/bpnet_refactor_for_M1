#!/bin/bash

# Preprocess sample data - merge BAMs and create bigwig files
# Usage: ./02_preprocessing.sh <sample_directory>

set -e  # Exit on any error

if [ $# -ne 1 ]; then
    echo "Usage: $0 <sample_directory>"
    echo "Example: $0 samples/ENCSR000EGM"
    exit 1
fi

SAMPLE_DIR=$1




# Merge and index the bam files
echo "Merge and index bam files"
samtools merge -f "$SAMPLE_DIR/processed/merged.bam" "$SAMPLE_DIR/resources/rep1.bam" "$SAMPLE_DIR/resources/rep2.bam"
samtools index "$SAMPLE_DIR/processed/merged.bam"

# Index the control
echo "Index control"
samtools index "$SAMPLE_DIR/resources/control.bam"


# In addition to creating the bigwig files, at this step we will filter the bam files to keep only the chromosomes that we want to use in the model. In the example shown below, we do this using samtools view and the hg38.chrom.sizes reference file.
# get coverage of 5’ positions of the plus strand
echo "Get plus strand bedGraph of bam"
samtools view -b "$SAMPLE_DIR/processed/merged.bam" $(cut -f 1 reference/hg38/hg38.chrom.sizes) | \
	bedtools genomecov -5 -bg -strand + -ibam stdin | \
	sort -k1,1 -k2,2n > "$SAMPLE_DIR/processed/plus.bedGraph"

# get coverage of 5’ positions of the minus strand
echo "Get minus strand bedGraph of bam"
samtools view -b "$SAMPLE_DIR/processed/merged.bam" $(cut -f 1 reference/hg38/hg38.chrom.sizes) | \
        bedtools genomecov -5 -bg -strand - -ibam stdin | \
        sort -k1,1 -k2,2n > "$SAMPLE_DIR/processed/minus.bedGraph"

# Convert bedGraph files to bigWig files
echo "Convert bedgraph to bigwig"
bedGraphToBigWig "$SAMPLE_DIR/processed/plus.bedGraph" reference/hg38/hg38.chrom.sizes "$SAMPLE_DIR/processed/plus.bw"
bedGraphToBigWig "$SAMPLE_DIR/processed/minus.bedGraph" reference/hg38/hg38.chrom.sizes "$SAMPLE_DIR/processed/minus.bw"


# Now for control
# get coverage of 5’ positions of the control plus strand
echo "Get plus strand bedGraph of control"
samtools view -b "$SAMPLE_DIR/resources/control.bam" $(cut -f 1 reference/hg38/hg38.chrom.sizes) | \
        bedtools genomecov -5 -bg -strand + -ibam stdin | \
        sort -k1,1 -k2,2n > "$SAMPLE_DIR/processed/control_plus.bedGraph"

# get coverage of 5' positions of the control minus strand
echo "Get minus strand bedGraph of control"
samtools view -b "$SAMPLE_DIR/resources/control.bam" $(cut -f 1 reference/hg38/hg38.chrom.sizes) | \
        bedtools genomecov -5 -bg -strand - -ibam stdin | \
        sort -k1,1 -k2,2n > "$SAMPLE_DIR/processed/control_minus.bedGraph"

# Convert bedGraph files to bigWig files
echo "Convert bedGraph to bigwig"
bedGraphToBigWig "$SAMPLE_DIR/processed/control_plus.bedGraph" reference/hg38/hg38.chrom.sizes "$SAMPLE_DIR/processed/control_plus.bw"
bedGraphToBigWig "$SAMPLE_DIR/processed/control_minus.bedGraph" reference/hg38/hg38.chrom.sizes "$SAMPLE_DIR/processed/control_minus.bw"



# Copy peaks file to processed directory
echo "Copy peaks file to processed directory"
cp "$SAMPLE_DIR/resources/peaks.bed" "$SAMPLE_DIR/processed/peaks.bed"





