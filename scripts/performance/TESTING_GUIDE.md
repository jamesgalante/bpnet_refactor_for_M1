# BPNet Performance Grid Search Guide

## Overview
This guide provides complete instructions for running BPNet performance optimization using grid search to find the best thread/batch size combinations for your M1 Mac.

## Quick Start

### 1. Get the Performance Grid Search Branch
```bash
# In your testing directory
git checkout main
git pull origin main
git checkout performance-grid-search
git pull origin performance-grid-search
```

### 2. Verify Setup
```bash
# Check that performance scripts exist
ls -la scripts/performance/
# Should show: grid_search.sh, analyze_logs.sh, analyze_grid_search.py, validate_setup.sh, test_training_parsing.sh, TESTING_GUIDE.md
```

### 3. Environment Setup
```bash
# Make sure your conda environment is ready
conda env list  # Check your environment name
# Use your actual environment name in place of "your-env-name" below
```

## Complete Workflow

### Step 1: Validate Prerequisites (Optional)
```bash
./scripts/performance/validate_setup.sh your-env-name
```

### Step 2: Run Grid Search
```bash
# Quick test (90 seconds per configuration)
./scripts/performance/grid_search.sh your-env-name 90

# Or thorough test (300 seconds per configuration)  
./scripts/performance/grid_search.sh your-env-name 300
```

### Step 3: Analyze Results
```bash
# Generate comprehensive performance plots and analysis
./scripts/performance/analyze_logs.sh your-env-name
```

### Step 4: View Results
```bash
# Check generated plots
ls plots/
open plots/  # macOS to view charts

# Review detailed analysis
cat grid_search_analysis.json
```

## Customizing Grid Search Parameters

### Changing Thread and Batch Size Combinations

To test different parameter combinations, edit the grid search script:

```bash
# Open the grid search script for editing
nano scripts/performance/grid_search.sh
# or: code scripts/performance/grid_search.sh
```

Find these lines and modify the arrays:
```bash
# Grid search parameters (around line 35-36)
THREADS_LIST=(3 5 8 10)        # Modify thread counts here
BATCH_SIZES=(64 128 256)       # Modify batch sizes here
```

### Example Customizations

**Fine-grained thread testing:**
```bash
THREADS_LIST=(1 2 4 6 8 10 12 14 16)
BATCH_SIZES=(128)  # Test only batch size 128
```

**Large batch size testing:**
```bash
THREADS_LIST=(8 10)
BATCH_SIZES=(32 64 128 256 512 1024)
```

**CPU core optimization (for different M1 variants):**
```bash
# M1 (8 cores): Test around performance cores
THREADS_LIST=(2 4 6 8)

# M1 Pro/Max (10+ cores): Test higher thread counts  
THREADS_LIST=(4 8 12 16 20)
```

### Custom Timeout Settings

Adjust timeout based on your needs:
```bash
# Quick exploration (1-2 minutes per config)
./scripts/performance/grid_search.sh your-env-name 90

# Balanced testing (5 minutes per config)
./scripts/performance/grid_search.sh your-env-name 300

# Thorough analysis (10 minutes per config)
./scripts/performance/grid_search.sh your-env-name 600
```

### Testing Different Samples

To test with a different sample, modify the script:
```bash
# In grid_search.sh, change line ~18:
SAMPLE_NAME="YOUR_SAMPLE_NAME"  # Instead of "ENCSR000EGM"
```

Make sure the sample is fully processed first:
```bash
./scripts/main.sh process YOUR_SAMPLE_NAME your-env-name
```

## Testing Plan

### Phase 1: Environment Validation (5 minutes)
```bash
# Run the validation script
./scripts/performance/validate_setup.sh your-env-name

# This will check:
# - Sample ENCSR000EGM exists and is processed
# - All required files are present
# - Conda environment works
# - PYTHONPATH is correctly set
# - Training command can start (quick test)
```

### Phase 2: Progress Parsing Test (2 minutes)
```bash
# Test the progress parsing logic
./scripts/performance/test_training_parsing.sh your-env-name

# This will:
# - Run training for 90 seconds
# - Test progress extraction from output
# - Validate the parsing logic works
# - Show sample progress lines and parsing results
```

### Phase 3: Mini Grid Search (12 minutes)
```bash
# Run a reduced grid search for validation
./scripts/performance/grid_search.sh your-env-name 90

# This will:
# - Test 4 threads × 3 batch sizes = 12 combinations
# - Each run: 90 seconds timeout
# - Total time: ~12 minutes
# - Generate grid_search_results.csv
```

### Phase 4: Full Grid Search (Optional - 30+ minutes)
```bash
# For full performance testing with longer timeout
./scripts/performance/grid_search.sh your-env-name 300

# This will:
# - Same 12 combinations
# - Each run: 300 seconds (5 minutes)
# - Total time: ~60 minutes
# - More comprehensive performance data
```

## Expected Outputs

### 1. Grid Search Results File
The script generates `grid_search_results.csv` with columns:
- `threads`: Number of threads used
- `batch_size`: Batch size used
- `steps_completed`: Training steps completed within timeout
- `total_steps`: Total training steps for full epoch
- `time_elapsed`: Actual time elapsed (seconds)
- `steps_per_minute`: Performance metric (steps/minute)
- `status`: "timeout", "completed", or "error"

### 2. Individual Log Files
Each combination generates a log file: `training_XtY_b.log`
- `X` = threads, `Y` = batch_size
- Contains full training output for debugging

### 3. Performance Summary
The script displays:
- Top 3 performing configurations
- Completion statistics
- Configurations that completed vs timed out

## Validation Criteria

### ✅ Success Indicators
1. **All 12 combinations execute** without script errors
2. **Progress parsing works** - steps_completed > 0 for most runs
3. **CSV file generated** with all expected columns
4. **Performance metrics calculated** - steps_per_minute > 0
5. **Status tracking works** - appropriate "timeout"/"completed"/"error" values
6. **Log files created** for each combination

### ❌ Failure Indicators
1. Script crashes or exits early
2. All steps_completed = 0 (parsing failed)
3. Missing CSV file or malformed data
4. All runs show "error" status
5. No log files generated

## Troubleshooting

### Common Issues

#### 1. "Sample directory does not exist"
```bash
# Check if sample exists
ls -la samples/ENCSR000EGM/
# If missing, run:
./scripts/main.sh setup your-env-name
./scripts/main.sh process ENCSR000EGM your-env-name
```

#### 2. "ModuleNotFoundError: No module named 'bpnet'"
```bash
# Check bpnet-refactor directory exists
ls -la bpnet-refactor/
# If missing, clone it:
git clone https://github.com/kundajelab/bpnet-refactor.git
cd bpnet-refactor
git checkout 33578afcdb0faf06457c9a35dea4791ab53c671b
```

#### 3. "Command not found: timeout"
```bash
# On macOS, install coreutils
brew install coreutils
# Use gtimeout instead of timeout in scripts
```

#### 4. All runs fail immediately
```bash
# Test basic training command manually
./scripts/main.sh train ENCSR000EGM your-env-name
# If this fails, check environment setup
```

## Testing Reports

### Report Template
Please provide:

1. **Environment Info:**
   - macOS version
   - Conda environment name
   - Python version: `python --version`
   - TensorFlow version: `python -c "import tensorflow; print(tensorflow.__version__)"`

2. **Test Results:**
   - Phase 1 (validation): ✅/❌ 
   - Phase 2 (parsing): ✅/❌
   - Phase 3 (mini grid): ✅/❌
   - Any error messages

3. **Performance Data:**
   - How many runs completed vs timed out
   - Best performing configuration
   - Attach `grid_search_results.csv`

4. **Issues Found:**
   - Any script errors
   - Parsing failures
   - Performance anomalies

## Key Testing Focus Areas

1. **Progress Parsing Accuracy:** Verify steps_completed extraction works correctly
2. **Performance Metrics:** Ensure steps_per_minute calculations are reasonable
3. **Error Handling:** Test behavior with missing files, bad environment names
4. **Resource Usage:** Monitor CPU/memory during grid search
5. **Output Quality:** Validate CSV format and log file completeness

## Success Metrics
- All combinations complete without crashes
- Progress parsing success rate > 80%
- Performance metrics show reasonable variance across configurations
- CSV file contains valid data for all runs
- Script completes in expected time
- Generated plots show clear performance differences

## Workflow Tips

### Re-running Analysis Only
If you want to re-analyze existing log files without re-running grid search:
```bash
# Just run the analysis on existing logs
./scripts/performance/analyze_logs.sh your-env-name
```

### Cleaning Up Between Runs
```bash
# Remove old log files and results
rm -f training_*t_*b.log grid_search_results.csv grid_search_analysis.json
rm -rf plots/

# Then run new grid search
./scripts/performance/grid_search.sh your-env-name 300
```

### Comparing Different Grid Searches
```bash
# Save results from first run
mkdir results_run1
mv training_*t_*b.log grid_search_results.csv plots/ grid_search_analysis.json results_run1/

# Modify parameters and run again
# Edit THREADS_LIST and BATCH_SIZES in grid_search.sh
./scripts/performance/grid_search.sh your-env-name 300

# Save second run
mkdir results_run2
mv training_*t_*b.log grid_search_results.csv plots/ grid_search_analysis.json results_run2/
```

### Performance Recommendations

Based on testing, here are general M1 Mac recommendations:

**For M1 (8-core):**
- Test threads: `(2 4 6 8)`
- Optimal typically: 4-6 threads

**For M1 Pro/Max (10+ core):**
- Test threads: `(4 8 12 16)`
- Optimal typically: 8-12 threads

**Batch sizes:**
- Start with: `(64 128 256)`
- If memory allows: `(128 256 512)`

## Complete Example Workflow

```bash
# 1. Get the code
git checkout performance-grid-search
git pull origin performance-grid-search

# 2. Quick validation
./scripts/performance/validate_setup.sh my-bpnet-env

# 3. Run grid search (adjust timeout as needed)
./scripts/performance/grid_search.sh my-bpnet-env 300

# 4. Analyze and visualize
./scripts/performance/analyze_logs.sh my-bpnet-env

# 5. View results
open plots/
cat grid_search_analysis.json | jq '.summary_stats.best_performance'

# 6. (Optional) Test different parameters
# Edit THREADS_LIST and BATCH_SIZES in scripts/performance/grid_search.sh
# Repeat steps 3-5
```

This workflow will give you comprehensive performance optimization data for BPNet training on your specific M1 Mac configuration!