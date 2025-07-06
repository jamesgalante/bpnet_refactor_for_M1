#!/usr/bin/env python3
"""
BPNet Grid Search Log Analysis and Visualization

Analyzes grid search log files and generates performance plots.
Usage: python analyze_grid_search.py [log_directory]
"""

import os
import re
import sys
import json
import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns
from pathlib import Path
import numpy as np
from datetime import datetime

def parse_log_file(log_path):
    """Parse a single training log file and extract performance metrics."""
    
    # Extract configuration from filename
    filename = os.path.basename(log_path)
    match = re.match(r'training_(\d+)t_(\d+)b\.log', filename)
    if not match:
        return None
    
    threads = int(match.group(1))
    batch_size = int(match.group(2))
    
    print(f"Parsing {filename}...")
    
    try:
        with open(log_path, 'r') as f:
            content = f.read()
    except Exception as e:
        print(f"Error reading {log_path}: {e}")
        return None
    
    # Extract key information
    result = {
        'threads': threads,
        'batch_size': batch_size,
        'filename': filename
    }
    
    # Extract total training steps
    steps_match = re.search(r'TRAINING STEPS - (\d+)', content)
    if steps_match:
        result['total_steps'] = int(steps_match.group(1))
    else:
        result['total_steps'] = None
    
    # Extract progress lines (e.g., "108/810 [===>..........................] - ETA: 10:39")
    progress_pattern = r'(\d+)/(\d+) \[.*?\] - ETA: ([\d:]+)'
    progress_matches = re.findall(progress_pattern, content)
    
    if progress_matches:
        # Get the last (most recent) progress line
        last_progress = progress_matches[-1]
        result['steps_completed'] = int(last_progress[0])
        result['total_steps_from_progress'] = int(last_progress[1])
        result['eta'] = last_progress[2]
        
        # Calculate progress percentage
        if result['total_steps_from_progress'] > 0:
            result['progress_percent'] = (result['steps_completed'] / result['total_steps_from_progress']) * 100
        else:
            result['progress_percent'] = 0
            
        # All progress steps (for plotting training curve)
        result['all_steps'] = [int(match[0]) for match in progress_matches]
        result['all_progress_times'] = list(range(len(progress_matches)))  # Approximate time progression
    else:
        result['steps_completed'] = 0
        result['total_steps_from_progress'] = result['total_steps']
        result['progress_percent'] = 0
        result['eta'] = None
        result['all_steps'] = []
        result['all_progress_times'] = []
    
    # Extract timing information using precise training start/end parsing
    lines = content.split('\n')
    timestamp_pattern = r'(\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}),\d{3}'
    training_start_pattern = r'Training Epoch 1'
    progress_pattern = r'(\d+)/(\d+) \[.*?\] - ETA: ([\d:]+)'
    
    start_time = None
    end_time = None
    last_progress_time = None
    
    for line in lines:
        # Extract timestamp
        timestamp_match = re.search(timestamp_pattern, line)
        if not timestamp_match:
            continue
            
        timestamp_str = timestamp_match.group(1)
        try:
            current_time = datetime.strptime(timestamp_str, '%Y-%m-%d %H:%M:%S')
        except:
            continue
        
        # Check for training start (first occurrence of "Training Epoch 1")
        if re.search(training_start_pattern, line) and start_time is None:
            start_time = current_time
            
        # Check for progress updates (to find last progress time)
        if re.search(progress_pattern, line):
            last_progress_time = current_time
    
    # Calculate duration from Training Epoch 1 to last progress update
    if start_time and last_progress_time:
        duration = last_progress_time - start_time
        result['duration_seconds'] = duration.total_seconds()
    else:
        result['duration_seconds'] = None
    
    # Calculate performance metrics
    if result['steps_completed'] > 0 and result['duration_seconds'] and result['duration_seconds'] > 0:
        result['steps_per_second'] = result['steps_completed'] / result['duration_seconds']
        result['steps_per_minute'] = result['steps_per_second'] * 60
    else:
        result['steps_per_second'] = 0
        result['steps_per_minute'] = 0
    
    # Extract batch size and thread info from log
    batch_match = re.search(r"batch size - (\d+)", content)
    thread_match = re.search(r"#threads - (\d+)", content)
    
    if batch_match:
        result['actual_batch_size'] = int(batch_match.group(1))
    if thread_match:
        result['actual_threads'] = int(thread_match.group(1))
    
    # Extract data size
    data_size_match = re.search(r"Data size \(after trimming \d+ samples\) - (\d+)", content)
    if data_size_match:
        result['data_size'] = int(data_size_match.group(1))
    
    print(f"  → {result['steps_completed']}/{result['total_steps_from_progress']} steps ({result['progress_percent']:.1f}%)")
    print(f"  → {result['steps_per_minute']:.1f} steps/minute")
    
    return result

def analyze_logs(log_directory='performance_testing'):
    """Analyze all grid search log files in the directory."""
    
    print("BPNet Grid Search Log Analysis")
    print("=" * 50)
    
    # Find all training log files
    log_pattern = 'training_*t_*b.log'
    log_files = list(Path(log_directory).glob(log_pattern))
    
    if not log_files:
        print(f"No log files found matching pattern '{log_pattern}' in {log_directory}")
        return None
    
    print(f"Found {len(log_files)} log files")
    print()
    
    # Parse all log files
    results = []
    for log_file in sorted(log_files):
        result = parse_log_file(log_file)
        if result:
            results.append(result)
    
    if not results:
        print("No valid results parsed from log files")
        return None
    
    # Convert to DataFrame
    df = pd.DataFrame(results)
    print()
    print("Grid Search Results Summary:")
    print(df[['threads', 'batch_size', 'steps_completed', 'total_steps_from_progress', 
              'progress_percent', 'steps_per_minute']].to_string(index=False))
    
    return df

def create_visualizations(df, output_dir='performance_testing/plots'):
    """Create comprehensive performance visualizations."""
    
    # Create output directory
    os.makedirs(output_dir, exist_ok=True)
    
    # Set style
    plt.style.use('default')
    sns.set_palette("husl")
    
    # 1. Performance Heatmap (Steps per Minute)
    plt.figure(figsize=(10, 6))
    
    # Create pivot table for heatmap
    heatmap_data = df.pivot(index='threads', columns='batch_size', values='steps_per_minute')
    
    sns.heatmap(heatmap_data, annot=True, fmt='.1f', cmap='YlOrRd', 
                cbar_kws={'label': 'Steps per Minute'})
    plt.title('BPNet Training Performance Grid Search\nSteps per Minute by Threads × Batch Size')
    plt.xlabel('Batch Size')
    plt.ylabel('Number of Threads')
    plt.tight_layout()
    plt.savefig(f'{output_dir}/performance_heatmap.png', dpi=300, bbox_inches='tight')
    plt.close()
    
    # 2. Progress Percentage Heatmap
    plt.figure(figsize=(10, 6))
    
    progress_data = df.pivot(index='threads', columns='batch_size', values='progress_percent')
    
    sns.heatmap(progress_data, annot=True, fmt='.1f', cmap='Blues',
                cbar_kws={'label': 'Progress Percentage (%)'})
    plt.title('Training Progress Achieved in 90 Seconds\nProgress Percentage by Threads × Batch Size')
    plt.xlabel('Batch Size')
    plt.ylabel('Number of Threads')
    plt.tight_layout()
    plt.savefig(f'{output_dir}/progress_heatmap.png', dpi=300, bbox_inches='tight')
    plt.close()
    
    # 3. Steps Completed Bar Chart
    plt.figure(figsize=(12, 6))
    
    # Create configuration labels
    df['config'] = df['threads'].astype(str) + 't_' + df['batch_size'].astype(str) + 'b'
    
    bars = plt.bar(df['config'], df['steps_completed'], 
                   color=plt.cm.viridis(df['steps_per_minute'] / df['steps_per_minute'].max()))
    
    plt.title('Steps Completed in 90 Seconds by Configuration')
    plt.xlabel('Configuration (Threads_BatchSize)')
    plt.ylabel('Steps Completed')
    plt.xticks(rotation=45)
    
    # Add value labels on bars
    for bar, value in zip(bars, df['steps_completed']):
        plt.text(bar.get_x() + bar.get_width()/2, bar.get_height() + 1,
                f'{int(value)}', ha='center', va='bottom')
    
    plt.tight_layout()
    plt.savefig(f'{output_dir}/steps_completed_bar.png', dpi=300, bbox_inches='tight')
    plt.close()
    
    # 4. Performance vs Configuration Scatter Plot
    fig, (ax1, ax2) = plt.subplots(1, 2, figsize=(15, 6))
    
    # Steps per minute vs threads (colored by batch size)
    for batch_size in sorted(df['batch_size'].unique()):
        subset = df[df['batch_size'] == batch_size]
        ax1.scatter(subset['threads'], subset['steps_per_minute'], 
                   label=f'Batch {batch_size}', s=100, alpha=0.7)
    
    ax1.set_xlabel('Number of Threads')
    ax1.set_ylabel('Steps per Minute')
    ax1.set_title('Performance vs Thread Count')
    ax1.legend()
    ax1.grid(True, alpha=0.3)
    
    # Steps per minute vs batch size (colored by threads)
    for threads in sorted(df['threads'].unique()):
        subset = df[df['threads'] == threads]
        ax2.scatter(subset['batch_size'], subset['steps_per_minute'],
                   label=f'{threads} Threads', s=100, alpha=0.7)
    
    ax2.set_xlabel('Batch Size')
    ax2.set_ylabel('Steps per Minute')
    ax2.set_title('Performance vs Batch Size')
    ax2.legend()
    ax2.grid(True, alpha=0.3)
    
    plt.tight_layout()
    plt.savefig(f'{output_dir}/performance_scatter.png', dpi=300, bbox_inches='tight')
    plt.close()
    
    # 5. Total Steps vs Configuration (shows computational load)
    plt.figure(figsize=(10, 6))
    
    # Group by batch size for clearer visualization
    for batch_size in sorted(df['batch_size'].unique()):
        subset = df[df['batch_size'] == batch_size]
        plt.plot(subset['threads'], subset['total_steps_from_progress'], 
                marker='o', linewidth=2, markersize=8, label=f'Batch {batch_size}')
    
    plt.xlabel('Number of Threads')
    plt.ylabel('Total Steps per Epoch')
    plt.title('Computational Load: Total Steps per Epoch by Configuration')
    plt.legend()
    plt.grid(True, alpha=0.3)
    plt.tight_layout()
    plt.savefig(f'{output_dir}/total_steps_line.png', dpi=300, bbox_inches='tight')
    plt.close()
    
    # 6. Performance Summary Table
    plt.figure(figsize=(12, 8))
    plt.axis('tight')
    plt.axis('off')
    
    # Create summary statistics
    summary_data = df.groupby(['threads', 'batch_size']).agg({
        'steps_completed': 'first',
        'total_steps_from_progress': 'first', 
        'steps_per_minute': 'first',
        'progress_percent': 'first',
        'duration_seconds': 'first'
    }).round(1)
    
    # Add efficiency metric (progress per minute) using actual training time
    summary_data['efficiency'] = (summary_data['progress_percent'] / 
                                 (summary_data['duration_seconds']/60)).round(1)  # progress percent per minute
    
    # Reset index to make threads and batch_size regular columns
    summary_data = summary_data.reset_index()
    
    # Create table
    table = plt.table(cellText=summary_data.values,
                     colLabels=['Threads', 'Batch Size', 'Steps Done', 'Total Steps',
                               'Steps/Min', 'Progress %', 'Efficiency'],
                     cellLoc='center',
                     loc='center')
    
    table.auto_set_font_size(False)
    table.set_fontsize(10)
    table.scale(1.2, 1.5)
    
    plt.title('BPNet Grid Search Performance Summary\n(90 Second Timeout)', 
              pad=20, fontsize=14, fontweight='bold')
    plt.savefig(f'{output_dir}/performance_summary_table.png', dpi=300, bbox_inches='tight')
    plt.close()
    
    print(f"\nVisualization plots saved to '{output_dir}/' directory:")
    print("  - performance_heatmap.png: Steps/minute heatmap")
    print("  - progress_heatmap.png: Progress percentage heatmap")  
    print("  - steps_completed_bar.png: Steps completed bar chart")
    print("  - performance_scatter.png: Performance vs configuration scatter plots")
    print("  - total_steps_line.png: Computational load line chart")
    print("  - performance_summary_table.png: Summary statistics table")

def find_optimal_configurations(df):
    """Identify optimal configurations based on different criteria."""
    
    print("\nOptimal Configuration Analysis:")
    print("=" * 40)
    
    # Best overall performance (steps per minute)
    best_performance = df.loc[df['steps_per_minute'].idxmax()]
    print(f"Highest Performance: {best_performance['threads']} threads, {best_performance['batch_size']} batch")
    print(f"  → {best_performance['steps_per_minute']:.1f} steps/minute")
    
    # Most progress in time limit
    best_progress = df.loc[df['progress_percent'].idxmax()]
    print(f"Most Progress: {best_progress['threads']} threads, {best_progress['batch_size']} batch")
    print(f"  → {best_progress['progress_percent']:.1f}% completion")
    
    # Most steps completed
    most_steps = df.loc[df['steps_completed'].idxmax()]
    print(f"Most Steps: {most_steps['threads']} threads, {most_steps['batch_size']} batch")
    print(f"  → {most_steps['steps_completed']} steps completed")
    
    # Efficiency by batch size
    print("\nPerformance by Batch Size:")
    batch_performance = df.groupby('batch_size')['steps_per_minute'].agg(['mean', 'max']).round(1)
    for batch_size, row in batch_performance.iterrows():
        print(f"  Batch {batch_size}: avg {row['mean']:.1f}, max {row['max']:.1f} steps/min")
    
    # Efficiency by thread count
    print("\nPerformance by Thread Count:")
    thread_performance = df.groupby('threads')['steps_per_minute'].agg(['mean', 'max']).round(1)
    for threads, row in thread_performance.iterrows():
        print(f"  {threads} threads: avg {row['mean']:.1f}, max {row['max']:.1f} steps/min")

def save_analysis_results(df, output_file='performance_testing/grid_search_analysis.json'):
    """Save detailed analysis results to JSON file."""
    
    # Ensure output directory exists
    os.makedirs(os.path.dirname(output_file), exist_ok=True)
    
    # Convert DataFrame to dict and handle numpy types
    results = {
        'summary_stats': {
            'total_configurations': len(df),
            'best_performance': {
                'config': f"{df.loc[df['steps_per_minute'].idxmax(), 'threads']}t_{df.loc[df['steps_per_minute'].idxmax(), 'batch_size']}b",
                'steps_per_minute': float(df['steps_per_minute'].max()),
                'threads': int(df.loc[df['steps_per_minute'].idxmax(), 'threads']),
                'batch_size': int(df.loc[df['steps_per_minute'].idxmax(), 'batch_size'])
            },
            'performance_range': {
                'min_steps_per_minute': float(df['steps_per_minute'].min()),
                'max_steps_per_minute': float(df['steps_per_minute'].max()),
                'mean_steps_per_minute': float(df['steps_per_minute'].mean())
            }
        },
        'detailed_results': df.to_dict('records')
    }
    
    # Convert numpy types to native Python types
    def convert_numpy(obj):
        if isinstance(obj, np.integer):
            return int(obj)
        elif isinstance(obj, np.floating):
            return float(obj)
        elif isinstance(obj, np.ndarray):
            return obj.tolist()
        return obj
    
    # Apply conversion recursively
    def deep_convert(obj):
        if isinstance(obj, dict):
            return {key: deep_convert(value) for key, value in obj.items()}
        elif isinstance(obj, list):
            return [deep_convert(item) for item in obj]
        else:
            return convert_numpy(obj)
    
    results = deep_convert(results)
    
    with open(output_file, 'w') as f:
        json.dump(results, f, indent=2)
    
    print(f"\nDetailed analysis results saved to: {output_file}")

def main():
    """Main analysis function."""
    
    # Get log directory from command line argument or use performance_testing directory
    log_directory = sys.argv[1] if len(sys.argv) > 1 else 'performance_testing'
    
    # Analyze logs
    df = analyze_logs(log_directory)
    if df is None:
        return
    
    # Create visualizations
    create_visualizations(df)
    
    # Find optimal configurations
    find_optimal_configurations(df)
    
    # Save detailed results
    save_analysis_results(df)
    
    print(f"\nAnalysis complete! Check the 'performance_testing/plots/' directory for visualizations.")

if __name__ == '__main__':
    main()