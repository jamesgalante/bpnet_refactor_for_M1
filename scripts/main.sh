#!/bin/bash

# Main entry point for BPNet pipeline
# Usage: ./main.sh <mode> [arguments...]
# 
# Modes:
#   setup <environment_name>              - Run one-time global setup
#   process <sample_name> <environment>   - Process a specific sample
#   help                                  - Show this help message

set -e  # Exit on any error

if [ $# -lt 1 ]; then
    echo "Usage: $0 <mode> [arguments...]"
    echo ""
    echo "Modes:"
    echo "  setup <environment_name>              - Run one-time global setup"
    echo "  process <sample_name> <environment>   - Process a specific sample"
    echo "  help                                  - Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 setup bpnet-m1"
    echo "  $0 process ENCSR000EGM bpnet-m1"
    exit 1
fi

MODE=$1
shift  # Remove mode from arguments

case $MODE in
    setup)
        if [ $# -ne 1 ]; then
            echo "Usage: $0 setup <environment_name>"
            echo "Example: $0 setup bpnet-m1"
            exit 1
        fi
        ENV_NAME=$1
        echo "Running global setup with environment: $ENV_NAME"
        ./setup/setup_global.sh "$ENV_NAME"
        ;;
    
    process)
        if [ $# -ne 2 ]; then
            echo "Usage: $0 process <sample_name> <environment_name>"
            echo "Example: $0 process ENCSR000EGM bpnet-m1"
            exit 1
        fi
        SAMPLE_NAME=$1
        ENV_NAME=$2
        echo "Processing sample: $SAMPLE_NAME with environment: $ENV_NAME"
        cd preprocess_sample
        ./preprocess_sample.sh "$SAMPLE_NAME" "$ENV_NAME"
        ;;
    
    help)
        echo "BPNet Pipeline Main Script"
        echo ""
        echo "Usage: $0 <mode> [arguments...]"
        echo ""
        echo "Modes:"
        echo "  setup <environment_name>              - Run one-time global setup"
        echo "  process <sample_name> <environment>   - Process a specific sample"
        echo "  help                                  - Show this help message"
        echo ""
        echo "Examples:"
        echo "  $0 setup bpnet-m1"
        echo "  $0 process ENCSR000EGM bpnet-m1"
        echo ""
        echo "Workflow:"
        echo "  1. Run 'setup' once to download reference data"
        echo "  2. Create sample directory and config.json"
        echo "  3. Run 'process' for each sample"
        ;;
    
    *)
        echo "Error: Unknown mode '$MODE'"
        echo "Run '$0 help' for usage information"
        exit 1
        ;;
esac