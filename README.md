# BPNet Mac M1 Setup and Workflow

This project provides a reproducible setup and workflow for running BPNet on a Mac M1, including environment setup, dependency checks, and data preparation scripts.

## Environment Setup

### Prerequisites

- First [install homebrew](https://brew.sh/).
- Then [install miniforge3](https://formulae.brew.sh/cask/miniforge) with homebrew.

### Conda Environment

Build the conda environment by either creating the environment manually or through the supplied yml file. The yml was created by first running the manual build commands then running `conda env export > bpnet-m1.yml`

#### Manual build

Note: This manual download doesn't specify versioning - see `.yml` file for details.

```
conda create -n bpnet-m1 python=3.8
pip install tensorflow-macos tensorflow-metal tensorflow-probability
conda install -y hdf5 pytables
pip install pysam==0.18.0 py2bit==0.3.0 tqdm scikit-learn scipy scikit-image deepdish pandas matplotlib plotly deeptools pyfaidx hdf5plugin deeplift
pip install git+https://github.com/kundajelab/shap.git
conda install -y -c bioconda samtools bedtools ucsc-bedgraphtobigwig
```

#### Automatic build

```
conda env create -f bpnet-m1.yml
```

### Clone the BPNet Refactored repo

The BPNet Refactored repo is configured to run with NVIDIA GPUs and not Mac M1 architectures - this is why we set up the environment manually rather than installing BPNet as it requires packages that conflict with our M1 setup. Thus, we need to clone the BPNet Refactored repo in order to use the bpnet-\* commands.

Here, I use [bpnet-refactor](https://github.com/kundajelab/bpnet-refactor) at commit `33578af` (2025-05-22).

To reproduce the exact environment:

```bash
git clone https://github.com/kundajelab/bpnet-refactor.git
cd bpnet-refactor
git checkout 33578afcdb0faf06457c9a35dea4791ab53c671b
```

### Testing functionality

Before running anything else, let's make sure tensorflow can find our Mac GPUs:

```
python -c "
import tensorflow as tf
import sys
if tf.config.list_physical_devices('GPU'):
    print('✅ MPS device detected')
    try:
        with tf.device('/GPU:0'):
            a = tf.random.normal((100, 100))
            result = tf.reduce_mean(tf.matmul(a, a))
            print(f'✅ MPS computation successful: {result.numpy():.4f}')
    except Exception as e:
        print(f'❌ MPS computation failed: {e}')
        sys.exit(1)
else:
    print('❌ No MPS device found')
    sys.exit(1)
"
```

You should see something like this:

```
✅ MPS device detected
2025-07-02 11:00:26.819181: I metal_plugin/src/device/metal_device.cc:1154] Metal device set to: Apple M1 Pro
2025-07-02 11:00:26.819200: I metal_plugin/src/device/metal_device.cc:296] systemMemory: 16.00 GB
2025-07-02 11:00:26.819208: I metal_plugin/src/device/metal_device.cc:313] maxCacheSize: 5.33 GB
2025-07-02 11:00:26.819272: I tensorflow/core/common_runtime/pluggable_device/pluggable_device_factory.cc:303] Could not identify NUMA node of platform GPU ID 0, defaulting to 0. Your kernel may not have been built with NUMA support.
2025-07-02 11:00:26.819310: I tensorflow/core/common_runtime/pluggable_device/pluggable_device_factory.cc:269] Created TensorFlow device (/job:localhost/replica:0/task:0/device:GPU:0 with 0 MB memory) -> physical PluggableDevice (device: 0, name: METAL, pci bus id: <undefined>)
✅ MPS computation successful: 0.0953
```

Great! Now our environment is all setup and we can start processing data

## Running Pipeline

The pipeline is organized into two main phases: global setup (run once) and sample processing (run per sample). The workflow is designed to support multiple samples while sharing reference data efficiently.

### 1. Global Setup (Run Once)

First, set up the reference data and global configuration files:

```bash
chmod +x scripts/main.sh
./scripts/main.sh setup bpnet-m1
```

This creates:

- Reference genome, chromosome sizes, and blacklist regions in `reference/hg38/`
- GC reference files for background generation
- Global configuration files: `bpnet_params.json` and `splits.json`

### 2. Sample Configuration

This sample is from the original bpnet tutorial.

For each sample, create a configuration file that specifies the download URLs. Create a sample directory and config file:

```bash
mkdir -p samples/ENCSR000EGM
cat > samples/ENCSR000EGM/config.json << 'EOF'
{
  "sample_id": "ENCSR000EGM",
  "description": "CTCF ChIP-seq from K562 cells",
  "genome": "hg38",
  "data_urls": {
    "replicates": [
      "https://www.encodeproject.org/files/ENCFF198CVB/@@download/ENCFF198CVB.bam",
      "https://www.encodeproject.org/files/ENCFF488CXC/@@download/ENCFF488CXC.bam"
    ],
    "control": "https://www.encodeproject.org/files/ENCFF023NGN/@@download/ENCFF023NGN.bam",
    "peaks": "https://www.encodeproject.org/files/ENCFF396BZQ/@@download/ENCFF396BZQ.bed.gz"
  }
}
EOF
```

The config.json structure:

- **sample_id**: Unique identifier for the sample
- **description**: Human-readable description
- **genome**: Reference genome (currently supports hg38)
- **data_urls**: URLs for downloading sample data
  - **replicates**: Array of BAM file URLs for ChIP-seq replicates
  - **control**: URL for control/input BAM file
  - **peaks**: URL for peaks file (BED format, can be gzipped)

### 3. Sample Processing

Process individual samples using their configuration:

```bash
./scripts/main.sh process ENCSR000EGM bpnet-m1
```

This runs the complete sample processing pipeline based on the bpnet-refactor tutorial:

1. **Download**: Downloads sample data based on config.json URLs
2. **Preprocessing**: Creates merged BAM files and bigwig tracks
3. **Outlier Removal**: Identifies and removes outlier peaks
4. **Background Generation**: Creates GC-matched background regions
5. **Input Data Creation**: Generates sample-specific input_data.json
6. **Loss Weight Calculation**: Computes optimal counts loss weights

Sample data is organized as:

```
samples/ENCSR000EGM/
├── config.json          # Sample configuration
├── resources/            # Raw downloaded data
├── processed/           # Intermediate processed files
└── results/             # Final configuration files
```

### 4. Processing Additional Samples

To process additional samples, simply create new sample directories with their own config.json files and run the processing script:

```bash
mkdir -p samples/ANOTHER_SAMPLE
# Create config.json for the new sample
./scripts/main.sh process ANOTHER_SAMPLE bpnet-m1
```

## Future Enhancements

- Setup Mac M1 GPU testing and training workflows
- Add support for additional reference genomes beyond hg38
