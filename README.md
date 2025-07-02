# BPNet Mac M1 Setup and Workflow

This project provides a reproducible setup and workflow for running BPNet on a Mac M1, including environment setup, dependency checks, and data preparation scripts.

## Environment Setup

### Prerequisites

- First [install homebrew](https://brew.sh/).
- Then [install miniforge3](https://formulae.brew.sh/cask/miniforge) with homebrew.

### Conda Environment

Build the conda environment by either creating the environment manually or through the supplied yml file. The yml was created by first running the manual build commands then running `conda env export > bpnet-m1.yml`

#### Manual build

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

## Data Pre-processing

All data pre-processing, including downloading example data from ENCODE, and converting that data into a format usable with the BPNet models, is done in `data_preprocessing.sh`

To setup the data, first enable execution permissions `chmod u+x scripts/data_preprocessing.sh` then run `./scripts/data_preprocessing.sh`.

This will create a `data/` directory, which will include any raw or processed data used in our experiment.
