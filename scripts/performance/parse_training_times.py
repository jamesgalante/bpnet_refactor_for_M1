#!/usr/bin/env python3
"""
Parse true training times from BPNet log files using timestamps.
This script calculates actual training duration by parsing log timestamps
rather than using the timeout-inclusive elapsed time.
"""

import re
import os
import sys
from datetime import datetime
import argparse
import json

def parse_log_timestamps(log_file_path):
    """
    Parse training start and end times from log file timestamps.
    
    Args:
        log_file_path (str): Path to the log file
        
    Returns:
        dict: Contains start_time, end_time, duration_seconds, and training_info
    """
    if not os.path.exists(log_file_path):
        return {"error": f"Log file not found: {log_file_path}"}
    
    try:
        with open(log_file_path, 'r') as f:
            lines = f.readlines()
    except Exception as e:
        return {"error": f"Error reading log file: {e}"}
    
    # Regex patterns for log parsing
    timestamp_pattern = r'(\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}),\d{3}'
    training_start_pattern = r'Training Epoch 1'
    progress_pattern = r'(\d+)/(\d+) \[.*?\] - ETA: ([\d:]+)'
    
    start_time = None
    end_time = None
    last_progress_time = None
    steps_completed = 0
    total_steps = 0
    
    for line in lines:
        # Extract timestamp
        timestamp_match = re.search(timestamp_pattern, line)
        if not timestamp_match:
            continue
            
        timestamp_str = timestamp_match.group(1)
        current_time = datetime.strptime(timestamp_str, '%Y-%m-%d %H:%M:%S')
        
        # Check for training start
        if re.search(training_start_pattern, line) and start_time is None:
            start_time = current_time
            
        # Check for progress updates
        progress_match = re.search(progress_pattern, line)
        if progress_match:
            last_progress_time = current_time
            steps_completed = int(progress_match.group(1))
            total_steps = int(progress_match.group(2))
    
    # Use last progress time as end time if available
    if last_progress_time:
        end_time = last_progress_time
    
    # Calculate results
    result = {
        "log_file": log_file_path,
        "start_time": start_time.isoformat() if start_time else None,
        "end_time": end_time.isoformat() if end_time else None,
        "steps_completed": steps_completed,
        "total_steps": total_steps,
        "duration_seconds": None,
        "steps_per_minute": None,
        "progress_percent": None
    }
    
    if start_time and end_time:
        duration = end_time - start_time
        result["duration_seconds"] = duration.total_seconds()
        
        if result["duration_seconds"] > 0:
            result["steps_per_minute"] = (steps_completed * 60) / result["duration_seconds"]
            
        if total_steps > 0:
            result["progress_percent"] = (steps_completed / total_steps) * 100
    
    return result

def parse_multiple_logs(log_directory):
    """
    Parse multiple log files in a directory.
    
    Args:
        log_directory (str): Directory containing log files
        
    Returns:
        list: List of parsed results for each log file
    """
    results = []
    
    if not os.path.exists(log_directory):
        print(f"Directory not found: {log_directory}")
        return results
    
    # Find all .log files in the directory
    log_files = [f for f in os.listdir(log_directory) if f.endswith('.log')]
    
    for log_file in sorted(log_files):
        log_path = os.path.join(log_directory, log_file)
        result = parse_log_timestamps(log_path)
        results.append(result)
    
    return results

def main():
    parser = argparse.ArgumentParser(description='Parse training times from BPNet log files')
    parser.add_argument('input', help='Log file or directory containing log files')
    parser.add_argument('--output', '-o', help='Output JSON file for results')
    parser.add_argument('--verbose', '-v', action='store_true', help='Verbose output')
    
    args = parser.parse_args()
    
    # Determine if input is file or directory
    if os.path.isfile(args.input):
        results = [parse_log_timestamps(args.input)]
    elif os.path.isdir(args.input):
        results = parse_multiple_logs(args.input)
    else:
        print(f"Error: Input '{args.input}' is not a valid file or directory")
        sys.exit(1)
    
    # Filter out error results for summary
    valid_results = [r for r in results if "error" not in r and r["duration_seconds"] is not None]
    
    # Print summary
    print(f"\n=== Training Time Analysis ===")
    print(f"Total log files processed: {len(results)}")
    print(f"Valid training sessions: {len(valid_results)}")
    
    if valid_results:
        print(f"\n{'Log File':<25} {'Duration':<10} {'Steps':<8} {'Steps/Min':<10} {'Progress':<10}")
        print("-" * 70)
        
        for result in valid_results:
            log_name = os.path.basename(result["log_file"])
            duration = f"{result['duration_seconds']:.1f}s"
            steps = f"{result['steps_completed']}/{result['total_steps']}"
            steps_per_min = f"{result['steps_per_minute']:.1f}" if result['steps_per_minute'] else "N/A"
            progress = f"{result['progress_percent']:.1f}%" if result['progress_percent'] else "N/A"
            
            print(f"{log_name:<25} {duration:<10} {steps:<8} {steps_per_min:<10} {progress:<10}")
    
    # Show errors if any
    error_results = [r for r in results if "error" in r]
    if error_results:
        print(f"\n=== Errors ===")
        for result in error_results:
            print(f"ERROR: {result['error']}")
    
    # Save to JSON if requested
    if args.output:
        with open(args.output, 'w') as f:
            json.dump(results, f, indent=2)
        print(f"\nResults saved to: {args.output}")
    
    # Show detailed results if verbose
    if args.verbose:
        print(f"\n=== Detailed Results ===")
        for result in valid_results:
            print(f"\nLog: {os.path.basename(result['log_file'])}")
            print(f"  Start: {result['start_time']}")
            print(f"  End: {result['end_time']}")
            print(f"  Duration: {result['duration_seconds']:.1f} seconds")
            print(f"  Steps: {result['steps_completed']}/{result['total_steps']}")
            print(f"  Steps/minute: {result['steps_per_minute']:.1f}")
            print(f"  Progress: {result['progress_percent']:.1f}%")

if __name__ == "__main__":
    main()