#!/bin/bash

# BPNet Performance Grid Search
# Tests different thread/batch size combinations to optimize training performance
# Usage: ./grid_search.sh <environment_name> [timeout_seconds]

set -e

if [ $# -lt 1 ] || [ $# -gt 2 ]; then
    echo "Usage: $0 <environment_name> [timeout_seconds]"
    echo "Example: $0 bpnet-m1 90"
    echo "Default timeout: 90 seconds"
    exit 1
fi

ENV_NAME=$1
TIMEOUT_SECONDS=${2:-90}
SAMPLE_NAME="ENCSR000EGM"

# Create performance testing output directory early
PERFORMANCE_DIR="performance_testing"
mkdir -p "$PERFORMANCE_DIR"
RESULTS_FILE="$PERFORMANCE_DIR/grid_search_results.csv"

# Determine the correct path based on where script is run from
if [ -d "samples/$SAMPLE_NAME" ]; then
    SAMPLE_DIR="samples/$SAMPLE_NAME"
    REFERENCE_DIR="reference/hg38"
    BPNET_DIR="bpnet-refactor"
elif [ -d "../../samples/$SAMPLE_NAME" ]; then
    SAMPLE_DIR="../../samples/$SAMPLE_NAME"
    REFERENCE_DIR="../../reference/hg38"
    BPNET_DIR="../../bpnet-refactor"
else
    echo "Error: Cannot find sample directory. Please run from project root or scripts/performance/"
    exit 1
fi

# Grid search parameters - minimal for quick testing
THREADS_LIST=(2)
BATCH_SIZES=(32 48)

echo "=========================================="
echo "BPNet Performance Grid Search"
echo "=========================================="
echo "Sample: $SAMPLE_NAME"
echo "Environment: $ENV_NAME"
echo "Timeout: $TIMEOUT_SECONDS seconds"
echo "Grid: threads=[${THREADS_LIST[*]}] × batch_size=[${BATCH_SIZES[*]}]"
echo "Results file: $RESULTS_FILE"
echo ""

# Check if sample directory exists and has required files
if [ ! -d "$SAMPLE_DIR" ]; then
    echo "Error: Sample directory $SAMPLE_DIR does not exist"
    echo "Please ensure ENCSR000EGM sample is processed first"
    exit 1
fi

REQUIRED_FILES=("results/input_data.json" "bpnet_params.json" "splits.json")
for file in "${REQUIRED_FILES[@]}"; do
    if [ ! -f "$SAMPLE_DIR/$file" ]; then
        echo "Error: Required file $SAMPLE_DIR/$file not found"
        echo "Please ensure ENCSR000EGM sample is fully processed"
        exit 1
    fi
done

# Initialize conda and activate environment
echo "Activating conda environment: $ENV_NAME"
eval "$(conda shell.bash hook)"
conda activate "$ENV_NAME"

# Set PYTHONPATH for bpnet-refactor
export PYTHONPATH="$(pwd)/$BPNET_DIR:$PYTHONPATH"

# PERFORMANCE_DIR already created above

# Set up paths
BASE_DIR="$SAMPLE_DIR"
CHROM_SIZES="$REFERENCE_DIR/hg38.chrom.sizes"
REFERENCE_GENOME="$REFERENCE_DIR/hg38.genome.fa"
CV_SPLITS="$BASE_DIR/splits.json"
INPUT_DATA="$BASE_DIR/results/input_data.json"
MODEL_PARAMS="$BASE_DIR/bpnet_params.json"

# Create temporary input_data.json with absolute paths for this script
TEMP_INPUT_DATA="grid_search_input_data.json"
echo "Creating temporary input_data.json with absolute paths..."
python3 -c "
import json
import os

# Read the original input_data.json
with open('$INPUT_DATA', 'r') as f:
    data = json.load(f)

# Convert relative paths to absolute paths
def convert_paths(obj):
    if isinstance(obj, list):
        return [convert_paths(item) for item in obj]
    elif isinstance(obj, str) and obj.startswith('../../samples/'):
        # Convert ../../samples/... to samples/... (relative to current dir)
        return obj.replace('../../samples/', 'samples/')
    elif isinstance(obj, dict):
        return {k: convert_paths(v) for k, v in obj.items()}
    else:
        return obj

# Convert all paths
converted_data = convert_paths(data)

# Write temporary file
with open('$TEMP_INPUT_DATA', 'w') as f:
    json.dump(converted_data, f, indent=4)

print('Temporary input_data.json created with absolute paths')
"

# Use the temporary file for training
INPUT_DATA="$TEMP_INPUT_DATA"

# Create results file with header
echo "threads,batch_size,steps_completed,total_steps,time_elapsed,steps_per_minute,status" > "$RESULTS_FILE"

echo "Starting grid search..."
echo ""

# Grid search loop
total_runs=$((${#THREADS_LIST[@]} * ${#BATCH_SIZES[@]}))
current_run=0

for threads in "${THREADS_LIST[@]}"; do
    for batch_size in "${BATCH_SIZES[@]}"; do
        current_run=$((current_run + 1))
        
        echo "=========================================="
        echo "Run $current_run/$total_runs: threads=$threads, batch_size=$batch_size"
        echo "=========================================="
        
        # Create unique model directory for this run
        MODEL_DIR="$BASE_DIR/models/grid_search_${threads}t_${batch_size}b"
        mkdir -p "$MODEL_DIR"
        
        # Log file for this run  
        LOG_FILE="$PERFORMANCE_DIR/training_${threads}t_${batch_size}b.log"
        
        # Ensure performance directory exists before this run
        mkdir -p "$PERFORMANCE_DIR"
        
        echo "Starting training run..."
        echo "Log file: $LOG_FILE"
        
        # Record start time
        start_time=$(date +%s)
        
        # Run training with timeout
        timeout $TIMEOUT_SECONDS python $BPNET_DIR/bpnet/cli/bpnettrainer.py \
                --input-data "$INPUT_DATA" \
                --output-dir "$MODEL_DIR" \
                --reference-genome "$REFERENCE_GENOME" \
                --chroms $(paste -s -d ' ' "$REFERENCE_DIR/chroms.txt") \
                --chrom-sizes "$CHROM_SIZES" \
                --splits "$CV_SPLITS" \
                --model-arch-name BPNet \
                --model-arch-params-json "$MODEL_PARAMS" \
                --sequence-generator-name BPNet \
                --model-output-filename model \
                --input-seq-len 2114 \
                --output-len 1000 \
                --shuffle \
                --threads $threads \
                --epochs 100 \
                --batch-size $batch_size \
                --reverse-complement-augmentation \
                --early-stopping-patience 10 \
                --reduce-lr-on-plateau-patience 5 \
                --learning-rate 0.001 \
                2>&1 | tee "$LOG_FILE"
        
        # Capture exact end time for true training duration calculation
        END_TIME=$(date '+%Y-%m-%d %H:%M:%S')
        echo "$END_TIME - root - INFO - Training ended at: $END_TIME" >> "$LOG_FILE"
        
        # Record end time and calculate elapsed time
        end_time=$(date +%s)
        time_elapsed=$((end_time - start_time))
        
        # Check exit status
        exit_code=$?
        if [ $exit_code -eq 124 ]; then
            status="timeout"
            echo "Training timed out after $TIMEOUT_SECONDS seconds"
        elif [ $exit_code -eq 0 ]; then
            status="completed"
            echo "Training completed successfully"
        else
            status="error"
            echo "Training failed with exit code $exit_code"
        fi
        
        # Parse progress and calculate true training duration from timestamps
        steps_completed=0
        total_steps=0
        steps_per_minute=0
        true_duration=0
        
        # Extract the last progress line (most recent progress)
        last_progress_line=$(grep -E "[0-9]+/[0-9]+ \[.*\] - ETA:" "$LOG_FILE" | tail -1 || echo "")
        
        if [ -n "$last_progress_line" ]; then
            echo "Last progress line: $last_progress_line"
            
            # Extract steps completed and total steps using regex
            if [[ $last_progress_line =~ ([0-9]+)/([0-9]+) ]]; then
                steps_completed=${BASH_REMATCH[1]}
                total_steps=${BASH_REMATCH[2]}
                
                # Calculate true training duration from timestamps
                training_start=$(grep "Training Epoch 1" "$LOG_FILE" | head -1 | grep -o "2025-[0-9-]* [0-9:]*")
                training_end=$(grep "Training ended at:" "$LOG_FILE" | tail -1 | grep -o "2025-[0-9-]* [0-9:]*")
                
                if [ -n "$training_start" ] && [ -n "$training_end" ]; then
                    # Convert to epoch seconds and calculate difference
                    start_epoch=$(date -d "$training_start" +%s 2>/dev/null || echo "0")
                    end_epoch=$(date -d "$training_end" +%s 2>/dev/null || echo "0")
                    
                    if [ $start_epoch -gt 0 ] && [ $end_epoch -gt 0 ]; then
                        true_duration=$((end_epoch - start_epoch))
                        echo "Training duration: ${true_duration}s (from $training_start to $training_end)"
                        
                        # Calculate steps per minute using true duration
                        if [ $true_duration -gt 0 ]; then
                            steps_per_minute=$((steps_completed * 60 / true_duration))
                        fi
                    else
                        echo "Warning: Could not parse timestamps, using timeout duration"
                        true_duration=$time_elapsed
                        if [ $time_elapsed -gt 0 ]; then
                            steps_per_minute=$((steps_completed * 60 / time_elapsed))
                        fi
                    fi
                else
                    echo "Warning: Could not find training timestamps, using timeout duration"
                    true_duration=$time_elapsed
                    if [ $time_elapsed -gt 0 ]; then
                        steps_per_minute=$((steps_completed * 60 / time_elapsed))
                    fi
                fi
                
                echo "Progress: $steps_completed/$total_steps steps ($((steps_completed * 100 / total_steps))%)"
                echo "Performance: $steps_per_minute steps/minute"
            fi
        else
            echo "No progress information found in log"
            true_duration=$time_elapsed
        fi
        
        # Write results to CSV (using true training duration)
        echo "$threads,$batch_size,$steps_completed,$total_steps,$true_duration,$steps_per_minute,$status" >> "$RESULTS_FILE"
        
        # Clean up model directory to save space
        rm -rf "$MODEL_DIR"
        echo "Cleaned up model directory"
        
        echo "Run completed: $status"
        echo ""
        
        # Small pause between runs
        sleep 2
    done
done

echo "=========================================="
echo "Grid Search Complete!"
echo "=========================================="
echo "Results saved to: $RESULTS_FILE"
echo ""

# Display results summary
echo "Summary of results:"
echo ""
column -t -s',' "$RESULTS_FILE"
echo ""

# Find best performing configuration
echo "Performance analysis:"
echo ""

# Sort by steps_per_minute (descending) and show top 3
echo "Top 3 performing configurations (steps/minute):"
(head -1 "$RESULTS_FILE" && tail -n +2 "$RESULTS_FILE" | sort -t',' -k6 -nr | head -3) | column -t -s','
echo ""

# Show configurations that completed successfully
completed_runs=$(tail -n +2 "$RESULTS_FILE" | grep -c "completed" || echo "0")
timeout_runs=$(tail -n +2 "$RESULTS_FILE" | grep -c "timeout" || echo "0")
error_runs=$(tail -n +2 "$RESULTS_FILE" | grep -c "error" || echo "0")

echo "Run summary:"
echo "  Completed: $completed_runs"
echo "  Timed out: $timeout_runs"
echo "  Errors: $error_runs"
echo "  Total: $total_runs"
echo ""

if [ $completed_runs -gt 0 ]; then
    echo "Configurations that completed within timeout:"
    (head -1 "$RESULTS_FILE" && tail -n +2 "$RESULTS_FILE" | grep "completed") | column -t -s','
    echo ""
fi

echo "All log files saved with pattern: performance_testing/training_*t_*b.log"

# Clean up temporary files
rm -f "$TEMP_INPUT_DATA"
echo "Cleaned up temporary files"

echo "Grid search completed successfully!"