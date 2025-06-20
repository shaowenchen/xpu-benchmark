#!/usr/bin/env python3
"""
Memory Bandwidth Stress Test
Test GPU memory read/write performance
"""

import argparse
import json
import sys
import time
from datetime import datetime
from pathlib import Path

import numpy as np
import psutil
import torch

# Add project root directory to Python path
sys.path.append(str(Path(__file__).parent.parent.parent.parent))

try:
    from xpu_bench.metrics import MetricsCollector
except ImportError:
    # If import fails, create a simple metrics collector
    class MetricsCollector:
        def __init__(self):
            self.metrics = {}
        
        def collect_gpu_metrics(self):
            if torch.cuda.is_available():
                return {
                    'gpu_utilization': torch.cuda.utilization(),
                    'gpu_memory_used': torch.cuda.memory_allocated() / 1024**3,
                    'gpu_memory_total': torch.cuda.get_device_properties(0).total_memory / 1024**3
                }
            return {}
        
        def collect_system_metrics(self):
            return {
                'cpu_percent': psutil.cpu_percent(),
                'memory_percent': psutil.virtual_memory().percent,
                'memory_used': psutil.virtual_memory().used / 1024**3,
                'memory_total': psutil.virtual_memory().total / 1024**3
            }
        
        def start_collection(self):
            pass
        
        def stop_collection(self):
            pass

class MemoryBandwidthBenchmark:
    def __init__(self, config_path, output_dir):
        self.config_path = config_path
        self.output_dir = Path(output_dir)
        self.config = self.load_config()
        self.device = self.setup_device()
        self.metrics_collector = MetricsCollector()
        
        # Create output directory
        self.output_dir.mkdir(parents=True, exist_ok=True)
        
    def load_config(self):
        """Load configuration file"""
        import yaml
        
        with open(self.config_path, 'r') as f:
            config = yaml.safe_load(f)
        
        return config
    
    def setup_device(self):
        """Setup device"""
        if torch.cuda.is_available():
            device = torch.device('cuda')
            print(f"Using GPU: {torch.cuda.get_device_name(0)}")
        else:
            device = torch.device('cpu')
            print("Using CPU")
        
        return device
    
    def test_memory_bandwidth(self, size_mb=1024, iterations=100):
        """Test memory bandwidth"""
        print(f"Testing memory bandwidth: {size_mb}MB, {iterations} iterations")
        
        # Calculate tensor size
        size_bytes = size_mb * 1024 * 1024
        size_elements = size_bytes // 4  # float32 = 4 bytes
        
        # Create test tensors
        a = torch.randn(size_elements, dtype=torch.float32, device=self.device)
        b = torch.randn(size_elements, dtype=torch.float32, device=self.device)
        c = torch.zeros(size_elements, dtype=torch.float32, device=self.device)
        
        # Warm up
        for _ in range(10):
            c = a + b
        
        torch.cuda.synchronize() if torch.cuda.is_available() else None
        
        # Test read bandwidth
        print("Testing read bandwidth...")
        start_time = time.time()
        for _ in range(iterations):
            _ = a + b
        torch.cuda.synchronize() if torch.cuda.is_available() else None
        read_time = time.time() - start_time
        
        read_bandwidth = (iterations * size_bytes * 2) / (read_time * 1024**3)  # GB/s
        
        # Test write bandwidth
        print("Testing write bandwidth...")
        start_time = time.time()
        for _ in range(iterations):
            c = a + b
        torch.cuda.synchronize() if torch.cuda.is_available() else None
        write_time = time.time() - start_time
        
        write_bandwidth = (iterations * size_bytes * 3) / (write_time * 1024**3)  # GB/s
        
        # Test copy bandwidth
        print("Testing copy bandwidth...")
        start_time = time.time()
        for _ in range(iterations):
            c.copy_(a)
        torch.cuda.synchronize() if torch.cuda.is_available() else None
        copy_time = time.time() - start_time
        
        copy_bandwidth = (iterations * size_bytes) / (copy_time * 1024**3)  # GB/s
        
        return {
            'read_bandwidth_gbps': read_bandwidth,
            'write_bandwidth_gbps': write_bandwidth,
            'copy_bandwidth_gbps': copy_bandwidth,
            'read_time': read_time,
            'write_time': write_time,
            'copy_time': copy_time,
            'size_mb': size_mb,
            'iterations': iterations
        }
    
    def test_memory_latency(self, size_mb=1, iterations=1000):
        """Test memory latency"""
        print(f"Testing memory latency: {size_mb}MB, {iterations} iterations")
        
        # Calculate tensor size
        size_bytes = size_mb * 1024 * 1024
        size_elements = size_bytes // 4  # float32 = 4 bytes
        
        # Create test tensors
        a = torch.randn(size_elements, dtype=torch.float32, device=self.device)
        b = torch.randn(size_elements, dtype=torch.float32, device=self.device)
        
        # Warm up
        for _ in range(10):
            _ = a + b
        
        torch.cuda.synchronize() if torch.cuda.is_available() else None
        
        # Test latency
        latencies = []
        for _ in range(iterations):
            start_time = time.time()
            _ = a + b
            torch.cuda.synchronize() if torch.cuda.is_available() else None
            end_time = time.time()
            latencies.append((end_time - start_time) * 1000)  # Convert to milliseconds
        
        return {
            'avg_latency_ms': np.mean(latencies),
            'min_latency_ms': np.min(latencies),
            'max_latency_ms': np.max(latencies),
            'std_latency_ms': np.std(latencies),
            'size_mb': size_mb,
            'iterations': iterations
        }
    
    def test_memory_stress(self, duration_seconds=300):
        """Memory stress test"""
        print(f"Memory stress test: {duration_seconds} seconds")
        
        start_time = time.time()
        stress_metrics = []
        
        # Create multiple tensors of different sizes to simulate memory pressure
        tensors = []
        sizes = [64, 128, 256, 512, 1024]  # MB
        
        for size_mb in sizes:
            try:
                size_elements = size_mb * 1024 * 1024 // 4
                tensor = torch.randn(size_elements, dtype=torch.float32, device=self.device)
                tensors.append(tensor)
                print(f"Allocated {size_mb}MB tensor")
            except RuntimeError as e:
                print(f"Cannot allocate {size_mb}MB tensor: {e}")
                break
        
        while time.time() - start_time < duration_seconds:
            # Perform random operations on tensors
            for tensor in tensors:
                if len(tensors) > 1:
                    other_tensor = np.random.choice([t for t in tensors if t is not tensor])
                    tensor.add_(other_tensor)
                else:
                    tensor.mul_(1.1)
            
            # Collect metrics
            gpu_metrics = self.metrics_collector.collect_gpu_metrics()
            system_metrics = self.metrics_collector.collect_system_metrics()
            
            stress_metrics.append({
                'elapsed_time': time.time() - start_time,
                'gpu_metrics': gpu_metrics,
                'system_metrics': system_metrics,
                'timestamp': datetime.now().isoformat()
            })
            
            time.sleep(1)  # Collect metrics every second
        
        return stress_metrics
    
    def run_benchmark(self):
        """Run benchmark"""
        print("=== Memory Bandwidth Stress Test ===")
        
        # Get configuration
        config = self.config['benchmarks']['stress']['memory_bandwidth']
        test_duration = config['test_duration']
        memory_size = config['memory_size']
        
        # Parse memory size
        if isinstance(memory_size, str):
            if memory_size.endswith('GB'):
                memory_size = int(memory_size[:-2]) * 1024
            elif memory_size.endswith('MB'):
                memory_size = int(memory_size[:-2])
            else:
                memory_size = int(memory_size)
        
        results = {
            'test_name': 'memory_bandwidth_stress',
            'hardware_type': self.config['hardware']['type'],
            'device': str(self.device),
            'timestamp': datetime.now().isoformat()
        }
        
        # Run bandwidth test
        if config.get('bandwidth_test', True):
            print("\n--- Bandwidth Test ---")
            bandwidth_results = self.test_memory_bandwidth(memory_size)
            results['bandwidth_test'] = bandwidth_results
            
            print(f"Read bandwidth: {bandwidth_results['read_bandwidth_gbps']:.2f} GB/s")
            print(f"Write bandwidth: {bandwidth_results['write_bandwidth_gbps']:.2f} GB/s")
            print(f"Copy bandwidth: {bandwidth_results['copy_bandwidth_gbps']:.2f} GB/s")
        
        # Run latency test
        if config.get('latency_test', True):
            print("\n--- Latency Test ---")
            latency_results = self.test_memory_latency(1, 1000)
            results['latency_test'] = latency_results
            
            print(f"Average latency: {latency_results['avg_latency_ms']:.4f} ms")
            print(f"Minimum latency: {latency_results['min_latency_ms']:.4f} ms")
            print(f"Maximum latency: {latency_results['max_latency_ms']:.4f} ms")
        
        # Run stress test
        print("\n--- Stress Test ---")
        stress_results = self.test_memory_stress(test_duration)
        results['stress_test'] = stress_results
        
        results['status'] = 'success'
        
        # Save results
        self.save_results(results)
        
        print(f"\nBenchmark completed!")
        return results
    
    def save_results(self, results):
        """Save test results"""
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        result_file = self.output_dir / f"memory_bandwidth_stress_{timestamp}.json"
        
        with open(result_file, 'w') as f:
            json.dump(results, f, indent=2)
        
        print(f"Results saved to: {result_file}")

def main():
    parser = argparse.ArgumentParser(description='Memory Bandwidth Stress Test')
    parser.add_argument('--config', required=True, help='Configuration file path')
    parser.add_argument('--output', required=True, help='Output directory')
    
    args = parser.parse_args()
    
    # Run benchmark
    benchmark = MemoryBandwidthBenchmark(args.config, args.output)
    results = benchmark.run_benchmark()
    
    print("Test completed!")

if __name__ == '__main__':
    main() 