"""
Benchmark Runner
Responsible for scheduling and executing various benchmarks
"""

import argparse
import json
import logging
import os
import sys
import time
from datetime import datetime
from pathlib import Path
from typing import Dict, List, Optional

import yaml

from .metrics import MetricsCollector

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

class BenchmarkRunner:
    """Benchmark Runner"""
    
    def __init__(self, config_path: str, output_dir: str):
        self.config_path = Path(config_path)
        self.output_dir = Path(output_dir)
        self.config = self.load_config()
        self.metrics_collector = MetricsCollector()
        
        # Create output directory
        self.output_dir.mkdir(parents=True, exist_ok=True)
        
        # Setup logging file
        self.setup_logging()
        
    def load_config(self) -> Dict:
        """Load configuration file"""
        try:
            with open(self.config_path, 'r', encoding='utf-8') as f:
                config = yaml.safe_load(f)
            logger.info(f"Successfully loaded configuration file: {self.config_path}")
            return config
        except Exception as e:
            logger.error(f"Failed to load configuration file: {e}")
            raise
    
    def setup_logging(self):
        """Setup logging"""
        log_file = self.output_dir / f"benchmark_{datetime.now().strftime('%Y%m%d_%H%M%S')}.log"
        file_handler = logging.FileHandler(log_file)
        file_handler.setLevel(logging.INFO)
        
        formatter = logging.Formatter('%(asctime)s - %(name)s - %(levelname)s - %(message)s')
        file_handler.setFormatter(formatter)
        
        logger.addHandler(file_handler)
        logger.info(f"Log file: {log_file}")
    
    def detect_hardware(self) -> str:
        """Detect hardware type"""
        hardware_type = self.config.get('hardware', {}).get('type', 'auto')
        
        if hardware_type == 'auto':
            # Auto-detect hardware type
            if self._detect_nvidia_gpu():
                return 'nvidia'
            elif self._detect_ascend_npu():
                return 'ascend'
            else:
                return 'unknown'
        
        return hardware_type
    
    def _detect_nvidia_gpu(self) -> bool:
        """Detect NVIDIA GPU"""
        try:
            import torch
            return torch.cuda.is_available()
        except ImportError:
            return False
    
    def _detect_ascend_npu(self) -> bool:
        """Detect Huawei Ascend NPU"""
        try:
            import subprocess
            result = subprocess.run(['lspci'], capture_output=True, text=True)
            return 'ascend' in result.stdout.lower()
        except:
            return False
    
    def run_training_benchmarks(self) -> List[Dict]:
        """Run training benchmarks"""
        logger.info("Starting training benchmarks")
        
        training_config = self.config.get('benchmarks', {}).get('training', {})
        results = []
        
        for benchmark_name, benchmark_config in training_config.items():
            if not benchmark_config.get('enabled', True):
                logger.info(f"Skipping disabled training test: {benchmark_name}")
                continue
            
            logger.info(f"Running training test: {benchmark_name}")
            
            try:
                result = self._run_single_training_benchmark(benchmark_name, benchmark_config)
                results.append(result)
                logger.info(f"Training test completed: {benchmark_name}")
            except Exception as e:
                logger.error(f"Training test failed: {benchmark_name}, error: {e}")
                results.append({
                    'benchmark_name': benchmark_name,
                    'status': 'failed',
                    'error': str(e),
                    'timestamp': datetime.now().isoformat()
                })
        
        return results
    
    def run_inference_benchmarks(self) -> List[Dict]:
        """Run inference benchmarks"""
        logger.info("Starting inference benchmarks")
        
        inference_config = self.config.get('benchmarks', {}).get('inference', {})
        results = []
        
        for benchmark_name, benchmark_config in inference_config.items():
            if not benchmark_config.get('enabled', True):
                logger.info(f"Skipping disabled inference test: {benchmark_name}")
                continue
            
            logger.info(f"Running inference test: {benchmark_name}")
            
            try:
                result = self._run_single_inference_benchmark(benchmark_name, benchmark_config)
                results.append(result)
                logger.info(f"Inference test completed: {benchmark_name}")
            except Exception as e:
                logger.error(f"Inference test failed: {benchmark_name}, error: {e}")
                results.append({
                    'benchmark_name': benchmark_name,
                    'status': 'failed',
                    'error': str(e),
                    'timestamp': datetime.now().isoformat()
                })
        
        return results
    
    def run_stress_benchmarks(self) -> List[Dict]:
        """Run stress benchmarks"""
        logger.info("Starting stress benchmarks")
        
        stress_config = self.config.get('benchmarks', {}).get('stress', {})
        results = []
        
        for benchmark_name, benchmark_config in stress_config.items():
            if not benchmark_config.get('enabled', True):
                logger.info(f"Skipping disabled stress test: {benchmark_name}")
                continue
            
            logger.info(f"Running stress test: {benchmark_name}")
            
            try:
                result = self._run_single_stress_benchmark(benchmark_name, benchmark_config)
                results.append(result)
                logger.info(f"Stress test completed: {benchmark_name}")
            except Exception as e:
                logger.error(f"Stress test failed: {benchmark_name}, error: {e}")
                results.append({
                    'benchmark_name': benchmark_name,
                    'status': 'failed',
                    'error': str(e),
                    'timestamp': datetime.now().isoformat()
                })
        
        return results
    
    def _run_single_training_benchmark(self, benchmark_name: str, config: Dict) -> Dict:
        """Run single training benchmark"""
        # This should call the corresponding training test based on benchmark_name
        # Currently returns mock results
        time.sleep(2)  # Simulate test time
        
        return {
            'benchmark_name': benchmark_name,
            'type': 'training',
            'status': 'success',
            'metrics': {
                'throughput': 100.0,
                'accuracy': 95.5,
                'time': 120.0
            },
            'timestamp': datetime.now().isoformat()
        }
    
    def _run_single_inference_benchmark(self, benchmark_name: str, config: Dict) -> Dict:
        """Run single inference benchmark"""
        # This should call the corresponding inference test based on benchmark_name
        # Currently returns mock results
        time.sleep(1)  # Simulate test time
        
        return {
            'benchmark_name': benchmark_name,
            'type': 'inference',
            'status': 'success',
            'metrics': {
                'throughput': 1000.0,
                'latency': 5.0,
                'time': 60.0
            },
            'timestamp': datetime.now().isoformat()
        }
    
    def _run_single_stress_benchmark(self, benchmark_name: str, config: Dict) -> Dict:
        """Run single stress benchmark"""
        # This should call the corresponding stress test based on benchmark_name
        # Currently returns mock results
        time.sleep(3)  # Simulate test time
        
        return {
            'benchmark_name': benchmark_name,
            'type': 'stress',
            'status': 'success',
            'metrics': {
                'bandwidth': 500.0,
                'utilization': 85.0,
                'time': 300.0
            },
            'timestamp': datetime.now().isoformat()
        }
    
    def generate_report(self, results: List[Dict]) -> str:
        """Generate test report"""
        logger.info("Generating test report")
        
        report_data = {
            'summary': {
                'total_tests': len(results),
                'successful_tests': len([r for r in results if r.get('status') == 'success']),
                'failed_tests': len([r for r in results if r.get('status') == 'failed']),
                'hardware_type': self.detect_hardware(),
                'timestamp': datetime.now().isoformat()
            },
            'results': results
        }
        
        # Save JSON report
        json_report = self.output_dir / f"benchmark_report_{datetime.now().strftime('%Y%m%d_%H%M%S')}.json"
        with open(json_report, 'w', encoding='utf-8') as f:
            json.dump(report_data, f, indent=2, ensure_ascii=False)
        
        # Generate HTML report
        html_report = self._generate_html_report(report_data)
        html_file = self.output_dir / f"benchmark_report_{datetime.now().strftime('%Y%m%d_%H%M%S')}.html"
        with open(html_file, 'w', encoding='utf-8') as f:
            f.write(html_report)
        
        logger.info(f"Report generated: {json_report}, {html_file}")
        return str(html_file)
    
    def _generate_html_report(self, report_data: Dict) -> str:
        """Generate HTML report"""
        html_template = """
<!DOCTYPE html>
<html>
<head>
    <title>XPU Benchmark Report</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        .header { background-color: #f0f0f0; padding: 20px; border-radius: 5px; margin-bottom: 20px; }
        .summary { background-color: #e8f5e8; padding: 15px; border-radius: 5px; margin-bottom: 20px; }
        .result { margin: 10px 0; padding: 15px; border: 1px solid #ddd; border-radius: 5px; }
        .success { background-color: #d4edda; border-color: #c3e6cb; }
        .failed { background-color: #f8d7da; border-color: #f5c6cb; }
        .metrics { background-color: #f8f9fa; padding: 10px; border-radius: 3px; margin-top: 10px; }
        table { width: 100%; border-collapse: collapse; margin-top: 10px; }
        th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }
        th { background-color: #f2f2f2; }
    </style>
</head>
<body>
    <div class="header">
        <h1>XPU Benchmark Report</h1>
        <p>Generated at: {timestamp}</p>
        <p>Hardware Type: {hardware_type}</p>
    </div>
    
    <div class="summary">
        <h2>Test Summary</h2>
        <p>Total Tests: {total_tests}</p>
        <p>Successful Tests: {successful_tests}</p>
        <p>Failed Tests: {failed_tests}</p>
        <p>Success Rate: {success_rate:.1f}%</p>
    </div>
    
    <h2>Detailed Results</h2>
    {results_html}
</body>
</html>
        """
        
        # Generate results HTML
        results_html = ""
        for result in report_data['results']:
            status_class = 'success' if result.get('status') == 'success' else 'failed'
            metrics_html = ""
            
            if 'metrics' in result:
                metrics_html = f"""
                <div class="metrics">
                    <h4>Metrics:</h4>
                    <table>
                        <tr><th>Metric</th><th>Value</th></tr>
                        {''.join([f'<tr><td>{k}</td><td>{v}</td></tr>' for k, v in result['metrics'].items()])}
                    </table>
                </div>
                """
            
            results_html += f"""
            <div class="result {status_class}">
                <h3>{result.get('benchmark_name', 'Unknown')}</h3>
                <p><strong>Type:</strong> {result.get('type', 'Unknown')}</p>
                <p><strong>Status:</strong> {result.get('status', 'Unknown')}</p>
                <p><strong>Time:</strong> {result.get('timestamp', 'Unknown')}</p>
                {metrics_html}
            </div>
            """
        
        # Calculate success rate
        summary = report_data['summary']
        success_rate = (summary['successful_tests'] / summary['total_tests'] * 100) if summary['total_tests'] > 0 else 0
        
        return html_template.format(
            timestamp=summary['timestamp'],
            hardware_type=summary['hardware_type'],
            total_tests=summary['total_tests'],
            successful_tests=summary['successful_tests'],
            failed_tests=summary['failed_tests'],
            success_rate=success_rate,
            results_html=results_html
        )
    
    def run_all_benchmarks(self) -> Dict:
        """Run all benchmarks"""
        logger.info("Starting all benchmarks")
        
        start_time = time.time()
        
        # Detect hardware
        hardware_type = self.detect_hardware()
        logger.info(f"Detected hardware type: {hardware_type}")
        
        # Start metrics collection
        self.metrics_collector.start_collection()
        
        # Run various tests
        training_results = self.run_training_benchmarks()
        inference_results = self.run_inference_benchmarks()
        stress_results = self.run_stress_benchmarks()
        
        # Stop metrics collection
        self.metrics_collector.stop_collection()
        
        # Merge results
        all_results = training_results + inference_results + stress_results
        
        # Generate report
        report_path = self.generate_report(all_results)
        
        total_time = time.time() - start_time
        
        logger.info(f"All benchmarks completed, total time: {total_time:.2f} seconds")
        
        return {
            'hardware_type': hardware_type,
            'total_time': total_time,
            'total_tests': len(all_results),
            'successful_tests': len([r for r in all_results if r.get('status') == 'success']),
            'report_path': report_path,
            'results': all_results
        }

def main():
    """Main function"""
    parser = argparse.ArgumentParser(description='XPU Benchmark Runner')
    parser.add_argument('--config', required=True, help='Configuration file path')
    parser.add_argument('--benchmark', choices=['training', 'inference', 'stress', 'all'], 
                       default='all', help='Test type to run')
    parser.add_argument('--output', default='reports', help='Output directory')
    
    args = parser.parse_args()
    
    # Create runner
    runner = BenchmarkRunner(args.config, args.output)
    
    # Run tests
    if args.benchmark == 'all':
        results = runner.run_all_benchmarks()
    elif args.benchmark == 'training':
        results = runner.run_training_benchmarks()
    elif args.benchmark == 'inference':
        results = runner.run_inference_benchmarks()
    elif args.benchmark == 'stress':
        results = runner.run_stress_benchmarks()
    
    print(f"Test completed! Results saved in: {args.output}")

if __name__ == '__main__':
    main() 