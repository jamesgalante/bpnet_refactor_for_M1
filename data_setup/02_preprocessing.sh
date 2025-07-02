#!/bin/bash

# Initialize conda for this shell session
echo "Initializing conda"
eval "$(conda shell.bash hook)"
# Now activate the environment
conda activate bpnet-refactored




# Merge and index the bam files
echo "Merge and index bam files"
samtools merge -f ENCSR000EGM/data/merged.bam ENCSR000EGM/data/rep1.bam ENCSR000EGM/data/rep2.bam
samtools index ENCSR000EGM/data/merged.bam

# Merge and index the control
echo "Merge and index control"
samtools index ENCSR000EGM/data/control.bam


# In addition to creating the bigwig files, at this step we will filter the bam files to keep only the chromosomes that we want to use in the model. In the example shown below, we do this using samtools view and the hg38.chrom.sizes reference file.
# get coverage of 5’ positions of the plus strand
echo "Get plus strand bedGraph of bam"
samtools view -b ENCSR000EGM/data/merged.bam $(cut -f 1 ENCSR000EGM/reference/hg38.chrom.sizes) | \
	bedtools genomecov -5 -bg -strand + -ibam stdin | \
	sort -k1,1 -k2,2n > ENCSR000EGM/data/plus.bedGraph

# get coverage of 5’ positions of the minus strand
echo "Get minus strand bedGraph of bam"
samtools view -b ENCSR000EGM/data/merged.bam $(cut -f 1 ENCSR000EGM/reference/hg38.chrom.sizes) | \
        bedtools genomecov -5 -bg -strand - -ibam stdin | \
        sort -k1,1 -k2,2n > ENCSR000EGM/data/minus.bedGraph

# Convert bedGraph files to bigWig files
echo "Convert bedgraph to bigwig"
bedGraphToBigWig ENCSR000EGM/data/plus.bedGraph ENCSR000EGM/reference/hg38.chrom.sizes ENCSR000EGM/data/plus.bw
bedGraphToBigWig ENCSR000EGM/data/minus.bedGraph ENCSR000EGM/reference/hg38.chrom.sizes ENCSR000EGM/data/minus.bw


# Now for control
# get coverage of 5’ positions of the control plus strand
echo "Get plus strand bedGraph of control"
samtools view -b ENCSR000EGM/data/control.bam $(cut -f 1 ENCSR000EGM/reference/hg38.chrom.sizes) | \
        bedtools genomecov -5 -bg -strand + -ibam stdin | \
        sort -k1,1 -k2,2n > ENCSR000EGM/data/control_plus.bedGraph

# get coverage of 5' positions of the control minus strand
echo "Get minus strand bedGraph of control"
samtools view -b ENCSR000EGM/data/control.bam $(cut -f 1 ENCSR000EGM/reference/hg38.chrom.sizes) | \
        bedtools genomecov -5 -bg -strand - -ibam stdin | \
        sort -k1,1 -k2,2n > ENCSR000EGM/data/control_minus.bedGraph

# Convert bedGraph files to bigWig files
echo "Convert bedGraph to bigwig"
bedGraphToBigWig ENCSR000EGM/data/control_plus.bedGraph ENCSR000EGM/reference/hg38.chrom.sizes ENCSR000EGM/data/control_plus.bw
bedGraphToBigWig ENCSR000EGM/data/control_minus.bedGraph ENCSR000EGM/reference/hg38.chrom.sizes ENCSR000EGM/data/control_minus.bw



# Identify peaks
# For the purposes of this tutorial we will use the optimal IDR thresholded peaks that are already available in the ENCODE data portal. We will use the the narrowPeak files that are in BED6+4 format. Explanation of what each of the 10 fields means can be found here. Currently, only this format is supported but in the future support for more formats will be added.
echo "Download the peaks bed file"
wget https://www.encodeproject.org/files/ENCFF396BZQ/@@download/ENCFF396BZQ.bed.gz -O ENCSR000EGM/data/peaks.bed.gz
gunzip ENCSR000EGM/data/peaks.bed.gz





