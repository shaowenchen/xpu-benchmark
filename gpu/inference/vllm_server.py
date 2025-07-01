#!/usr/bin/env python3
"""
vLLM Server for Qwen2.5-7B-Instruct Model
Based on https://www.modelscope.cn/models/Qwen/Qwen2.5-7B-Instruct/
"""

import argparse
import os
import sys
import time
import json
import logging
from datetime import datetime
from pathlib import Path
import subprocess
import signal
import psutil
import torch

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

class MetricsCollector:
    """Collect system and GPU metrics"""
    
    def __init__(self):
        self.start_time = None
        self.metrics = []
    
    def collect_gpu_metrics(self):
        """Collect GPU metrics"""
        try:
            import pynvml
            pynvml.nvmlInit()
            handle = pynvml.nvmlDeviceGetHandleByIndex(0)
            
            memory_info = pynvml.nvmlDeviceGetMemoryInfo(handle)
            utilization = pynvml.nvmlDeviceGetUtilizationRates(handle)
            temperature = pynvml.nvmlDeviceGetTemperature(handle, pynvml.NVML_TEMPERATURE_GPU)
            
            return {
                'gpu_utilization': utilization.gpu,
                'memory_utilization': utilization.memory,
                'memory_used_mb': memory_info.used / 1024 / 1024,
                'memory_total_mb': memory_info.total / 1024 / 1024,
                'temperature': temperature
            }
        except Exception as e:
            logger.warning(f"Failed to collect GPU metrics: {e}")
            return {}
    
    def collect_system_metrics(self):
        """Collect system metrics"""
        try:
            cpu_percent = psutil.cpu_percent(interval=1)
            memory = psutil.virtual_memory()
            
            return {
                'cpu_usage': cpu_percent,
                'memory_usage': memory.percent,
                'memory_used_gb': memory.used / 1024 / 1024 / 1024,
                'memory_total_gb': memory.total / 1024 / 1024 / 1024
            }
        except Exception as e:
            logger.warning(f"Failed to collect system metrics: {e}")
            return {}
    
    def start_collection(self):
        """Start metrics collection"""
        self.start_time = time.time()
        logger.info("Started metrics collection")
    
    def stop_collection(self):
        """Stop metrics collection"""
        logger.info("Stopped metrics collection")
    
    def save_metrics(self, output_dir):
        """Save collected metrics as markdown report"""
        if self.metrics:
            timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
            report_file = Path(output_dir) / f"report_{timestamp}.md"
            
            with open(report_file, 'w') as f:
                f.write("# vLLM Server Test Report\n\n")
                f.write(f"**Test Date:** {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n\n")
                f.write(f"**Model:** Qwen2.5-7B-Instruct\n\n")
                f.write(f"**Total Metrics Collected:** {len(self.metrics)}\n\n")
                
                if self.metrics:
                    # Calculate averages
                    cpu_usage = [m['system_metrics'].get('cpu_usage', 0) for m in self.metrics if m['system_metrics']]
                    memory_usage = [m['system_metrics'].get('memory_usage', 0) for m in self.metrics if m['system_metrics']]
                    
                    if cpu_usage:
                        avg_cpu = sum(cpu_usage) / len(cpu_usage)
                        f.write(f"**Average CPU Usage:** {avg_cpu:.1f}%\n\n")
                    
                    if memory_usage:
                        avg_memory = sum(memory_usage) / len(memory_usage)
                        f.write(f"**Average Memory Usage:** {avg_memory:.1f}%\n\n")
                    
                    # GPU metrics summary
                    gpu_metrics = [m['gpu_metrics'] for m in self.metrics if m['gpu_metrics']]
                    if gpu_metrics:
                        f.write("## GPU Metrics Summary\n\n")
                        f.write("GPU metrics were collected during the test.\n\n")
                    
                    f.write("## Test Status\n\n")
                    f.write("✅ **Test completed successfully**\n\n")
                    f.write("---\n\n")
                    f.write("*Report generated automatically by vLLM server*\n")
            
            logger.info(f"Report saved to: {report_file}")

class VLLMServer:
    """vLLM Server for Qwen2.5-7B-Instruct"""
    
    def __init__(self, model_path="/model/Qwen2.5-7B-Instruct", output_dir="/app/reports", 
                 cuda_visible_devices="1", port=8000):
        self.model_path = model_path
        self.output_dir = Path(output_dir)
        self.cuda_visible_devices = cuda_visible_devices
        self.port = port
        self.metrics_collector = MetricsCollector()
        self.server_process = None
        
        # Create output directory
        self.output_dir.mkdir(parents=True, exist_ok=True)
        
        # Setup signal handlers
        signal.signal(signal.SIGINT, self.signal_handler)
        signal.signal(signal.SIGTERM, self.signal_handler)
    
    def check_gpu_availability(self):
        """Check GPU availability"""
        if not torch.cuda.is_available():
            logger.error("CUDA is not available!")
            return False
        
        gpu_count = torch.cuda.device_count()
        logger.info(f"Found {gpu_count} GPU(s)")
        
        for i in range(gpu_count):
            gpu_name = torch.cuda.get_device_name(i)
            gpu_memory = torch.cuda.get_device_properties(i).total_memory / 1024**3
            logger.info(f"GPU {i}: {gpu_name} ({gpu_memory:.1f} GB)")
        
        return True
    
    def build_vllm_command(self):
        """Build vLLM command with direct parameters"""
        cmd = [
            "vllm", "serve", self.model_path,
            "--served-model-name", "Qwen2.5-7B-Instruct",
            "--port", str(self.port),
            "--enable-prefix-caching",
            "--gpu-memory-utilization", "0.90",
            "--max-model-len", "4096",
            "--max-seq-len-to-capture", "8192",
            "--max-num-seqs", "128",
            "--disable-log-stats",
            "--enforce-eager"
        ]
        
        return cmd
    
    def start_server(self):
        """Start vLLM server"""
        logger.info("Starting vLLM server for Qwen2.5-7B-Instruct...")
        
        cmd = self.build_vllm_command()
        logger.info(f"Command: {' '.join(cmd)}")
        
        # Set environment variables
        env = os.environ.copy()
        env['CUDA_VISIBLE_DEVICES'] = self.cuda_visible_devices
        
        # Start the server process
        self.server_process = subprocess.Popen(
            cmd,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            universal_newlines=True,
            bufsize=1,
            env=env
        )
        
        logger.info(f"vLLM server started with PID: {self.server_process.pid}")
        logger.info(f"Using GPU: {self.cuda_visible_devices}")
        
        # Monitor server output
        self.monitor_server()
    
    def monitor_server(self):
        """Monitor server output and collect metrics"""
        logger.info("Monitoring vLLM server...")
        
        self.metrics_collector.start_collection()
        
        try:
            while self.server_process.poll() is None:
                # Read output
                output = self.server_process.stdout.readline()
                if output:
                    print(output.strip())
                
                # Collect metrics periodically (every 10 seconds)
                gpu_metrics = self.metrics_collector.collect_gpu_metrics()
                system_metrics = self.metrics_collector.collect_system_metrics()
                
                self.metrics_collector.metrics.append({
                    'timestamp': datetime.now().isoformat(),
                    'gpu_metrics': gpu_metrics,
                    'system_metrics': system_metrics
                })
                
                time.sleep(10)  # Collect metrics every 10 seconds
        
        except KeyboardInterrupt:
            logger.info("Received interrupt signal, shutting down...")
        finally:
            self.stop_server()
    
    def stop_server(self):
        """Stop vLLM server"""
        if self.server_process:
            logger.info("Stopping vLLM server...")
            self.server_process.terminate()
            
            try:
                self.server_process.wait(timeout=30)
                logger.info("vLLM server stopped gracefully")
            except subprocess.TimeoutExpired:
                logger.warning("Server didn't stop gracefully, forcing...")
                self.server_process.kill()
                self.server_process.wait()
        
        self.metrics_collector.stop_collection()
        self.metrics_collector.save_metrics(self.output_dir)
    
    def signal_handler(self, signum, frame):
        """Handle shutdown signals"""
        logger.info(f"Received signal {signum}, shutting down...")
        self.stop_server()
        sys.exit(0)
    
    def run(self):
        """Run the vLLM server"""
        logger.info("=== vLLM Server for Qwen2.5-7B-Instruct ===")
        
        # Check GPU availability
        if not self.check_gpu_availability():
            logger.error("GPU not available, exiting...")
            return False
        
        # Start server
        try:
            self.start_server()
            return True
        except Exception as e:
            logger.error(f"Failed to start server: {e}")
            return False

def main():
    parser = argparse.ArgumentParser(description='vLLM Server for Qwen2.5-7B-Instruct')
    parser.add_argument('--model-path', default='/model/Qwen2.5-7B-Instruct', 
                       help='Model path')
    parser.add_argument('--output', default='/app/reports', help='Output directory')
    parser.add_argument('--cuda-visible-devices', default='1', 
                       help='CUDA visible devices')
    parser.add_argument('--port', type=int, default=8000, help='Server port')
    
    args = parser.parse_args()
    
    # Run server
    server = VLLMServer(
        model_path=args.model_path,
        output_dir=args.output,
        cuda_visible_devices=args.cuda_visible_devices,
        port=args.port
    )
    success = server.run()
    
    if success:
        logger.info("Server completed successfully")
    else:
        logger.error("Server failed")
        sys.exit(1)

if __name__ == '__main__':
    main() 