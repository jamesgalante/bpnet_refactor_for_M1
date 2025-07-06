# Performance Grid Search Testing Guide

## Overview
This guide provides comprehensive testing instructions for the BPNet performance grid search functionality.

## Prerequisites Setup

### 1. Pull the Branch
```bash
# In your testing directory
git checkout main
git pull origin main
git checkout performance-grid-search
git pull origin performance-grid-search
```

### 2. Verify Branch Structure
```bash
# Check that new files exist
ls -la scripts/performance/
# Should show: grid_search.sh, test_training_parsing.sh, TESTING_GUIDE.md, validate_setup.sh
```

### 3. Environment Setup
```bash
# Make sure your conda environment is ready
conda env list  # Check your environment name
# Use your actual environment name in place of "your-env-name" below
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
- All 12 combinations complete without crashes
- Progress parsing success rate > 80%
- Performance metrics show reasonable variance across configurations
- CSV file contains valid data for all runs
- Script completes in expected time (90s × 12 + overhead = ~20 minutes)