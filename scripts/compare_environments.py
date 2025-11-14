#!/usr/bin/env python3
"""
Script for comparing performance results between different virtualization environments.

This script loads test results, compares them across environments, and generates
both console output and an HTML report with performance metrics.
"""

import json
import logging
import os
import sys
from datetime import datetime
from pathlib import Path
from typing import Dict, Optional, Tuple, Any


# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(levelname)s: %(message)s'
)
logger = logging.getLogger(__name__)


def load_test_results(directory: str) -> Dict[str, Dict[str, Any]]:
    """
    Load all test result files from the specified directory.
    
    Args:
        directory: Path to directory containing test result JSON files
        
    Returns:
        Dictionary mapping test keys (environment_testtype) to result data
        
    Raises:
        ValueError: If directory does not exist
    """
    dir_path = Path(directory)
    
    if not dir_path.exists():
        raise ValueError(f"Directory not found: {directory}")
    
    if not dir_path.is_dir():
        raise ValueError(f"Path is not a directory: {directory}")
    
    results = {}
    files_processed = 0
    files_failed = 0
    
    for file_path in dir_path.glob("test_*.json"):
        try:
            with open(file_path, 'r', encoding='utf-8') as f:
                data = json.load(f)
                
            env = data.get('environment', 'unknown')
            test_type = data.get('test', 'unknown')
            key = f"{env}_{test_type}"
            
            results[key] = data
            files_processed += 1
            
        except json.JSONDecodeError as e:
            logger.warning(f"Invalid JSON in {file_path}: {e}")
            files_failed += 1
        except IOError as e:
            logger.warning(f"Error reading {file_path}: {e}")
            files_failed += 1
        except Exception as e:
            logger.error(f"Unexpected error processing {file_path}: {e}")
            files_failed += 1
    
    logger.info(f"Processed {files_processed} files successfully, {files_failed} failed")
    return results


def compare_results(results: Dict[str, Dict[str, Any]]) -> None:
    """
    Print comparison of test results to console.
    
    Args:
        results: Dictionary of test results indexed by environment_testtype
    """
    print("\n" + "=" * 80)
    print("Performance Comparison Report")
    print("=" * 80 + "\n")
    
    # Group results by test type
    tests: Dict[str, Dict[str, Dict[str, Any]]] = {}
    for key, data in results.items():
        test_type = data.get('test', 'unknown')
        if test_type not in tests:
            tests[test_type] = {}
        env = data.get('environment', 'unknown')
        tests[test_type][env] = data
    
    # Compare each test type
    for test_type, envs in tests.items():
        print(f"\nTest: {test_type.upper()}")
        print("-" * 80)
        
        for env, data in envs.items():
            status = data.get('status', 'unknown')
            status_icon = "PASS" if status == 'completed' else "FAIL"
            duration = data.get('duration_seconds', 0.0)
            timestamp = data.get('timestamp', 'N/A')
            
            print(f"[{status_icon}] {env:15s} | Duration: {duration:6.2f}s | {timestamp}")
        
        # Calculate winner
        if len(envs) > 1:
            try:
                fastest = min(
                    envs.items(), 
                    key=lambda x: x[1].get('duration_seconds', float('inf'))
                )
                print(f"   Winner: {fastest[0]} (fastest)")
            except (ValueError, KeyError) as e:
                logger.warning(f"Could not determine fastest for {test_type}: {e}")
    
    print("\n" + "=" * 80)


def generate_html_report(
    results: Dict[str, Dict[str, Any]], 
    output_file: str
) -> None:
    """
    Generate an HTML report with performance comparison.
    
    Args:
        results: Dictionary of test results
        output_file: Path to output HTML file
        
    Raises:
        IOError: If unable to write output file
    """
    timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    
    html = f"""<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>OptiVolt - Performance Comparison</title>
    <style>
        body {{ font-family: Arial, sans-serif; margin: 40px; background: #f5f5f5; }}
        .header {{ background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); 
                  color: white; padding: 30px; border-radius: 10px; margin-bottom: 30px; }}
        .header h1 {{ margin: 0; }}
        .card {{ background: white; padding: 20px; border-radius: 8px; 
                margin-bottom: 20px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }}
        table {{ width: 100%; border-collapse: collapse; }}
        th, td {{ padding: 12px; text-align: left; border-bottom: 1px solid #ddd; }}
        th {{ background: #667eea; color: white; }}
        .status-ok {{ color: #27ae60; font-weight: bold; }}
        .status-fail {{ color: #e74c3c; font-weight: bold; }}
        .winner {{ background: #f0f8ff; font-weight: bold; }}
    </style>
</head>
<body>
    <div class="header">
        <h1>OptiVolt - Performance Comparison</h1>
        <p>Report generated: {timestamp}</p>
    </div>
"""
    
    # Group by test type
    tests: Dict[str, Dict[str, Dict[str, Any]]] = {}
    for key, data in results.items():
        test_type = data.get('test', 'unknown')
        if test_type not in tests:
            tests[test_type] = {}
        env = data.get('environment', 'unknown')
        tests[test_type][env] = data
    
    for test_type, envs in tests.items():
        html += f"""
    <div class="card">
        <h2>Test: {test_type.upper()}</h2>
        <table>
            <tr>
                <th>Environment</th>
                <th>Status</th>
                <th>Duration (s)</th>
                <th>Timestamp</th>
            </tr>
"""
        
        # Find fastest environment
        fastest_env = None
        if envs:
            try:
                fastest_env = min(
                    envs.items(), 
                    key=lambda x: x[1].get('duration_seconds', float('inf'))
                )[0]
            except (ValueError, KeyError):
                logger.warning(f"Could not determine fastest for {test_type}")
        
        for env, data in sorted(envs.items()):
            status = data.get('status', 'unknown')
            status_class = 'status-ok' if status == 'completed' else 'status-fail'
            duration = data.get('duration_seconds', 0.0)
            timestamp = data.get('timestamp', 'N/A')[:19]
            row_class = 'winner' if env == fastest_env else ''
            winner_icon = 'Winner' if env == fastest_env else ''
            
            html += f"""
            <tr class="{row_class}">
                <td><strong>{env}</strong> {winner_icon}</td>
                <td class="{status_class}">{status}</td>
                <td>{duration:.2f}</td>
                <td>{timestamp}</td>
            </tr>
"""
        
        html += """
        </table>
    </div>
"""
    
    # Summary section
    unique_envs = len(set(r.get('environment', 'unknown') for r in results.values()))
    html += f"""
    <div class="card">
        <h3>Summary</h3>
        <ul>
            <li>Total tests: {len(results)}</li>
            <li>Environments tested: {unique_envs}</li>
            <li>Test types: {len(tests)}</li>
        </ul>
    </div>
</body>
</html>
"""
    
    try:
        with open(output_file, 'w', encoding='utf-8') as f:
            f.write(html)
        logger.info(f"HTML report generated: {output_file}")
    except IOError as e:
        raise IOError(f"Failed to write HTML report to {output_file}: {e}")


def main() -> int:
    """
    Main entry point for the comparison script.
    
    Returns:
        Exit code (0 for success, non-zero for failure)
    """
    # Parse command line arguments
    results_dir = sys.argv[1] if len(sys.argv) > 1 else "."
    output_file = sys.argv[2] if len(sys.argv) > 2 else "comparison_report.html"
    
    try:
        logger.info(f"Loading results from: {results_dir}")
        results = load_test_results(results_dir)
        
        if not results:
            logger.error("No test results found")
            return 1
        
        logger.info(f"Loaded {len(results)} test results")
        
        # Display console comparison
        compare_results(results)
        
        # Generate HTML report
        generate_html_report(results, output_file)
        
        return 0
        
    except ValueError as e:
        logger.error(f"Configuration error: {e}")
        return 1
    except IOError as e:
        logger.error(f"I/O error: {e}")
        return 1
    except Exception as e:
        logger.error(f"Unexpected error: {e}", exc_info=True)
        return 1


if __name__ == "__main__":
    sys.exit(main())
