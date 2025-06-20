"""
Performance Metrics Collector
Responsible for collecting GPU/NPU and system performance metrics
"""

import json
import logging
import os
import subprocess
import threading
import time
from datetime import datetime
from pathlib import Path
from typing import Dict, List, Optional

import psutil

logger = logging.getLogger(__name__)

class MetricsCollector:
    """Performance Metrics Collector"""
    
    def __init__(self, collection_interval: float = 1.0):
        self.collection_interval = collection_interval
        self.is_collecting = False
        self.collection_thread = None
        self.metrics_data = []
        self.start_time = None
        self.stop_event = threading.Event()
    
    def start_collection(self):
        """Start collecting metrics"""
        if self.is_collecting:
            logger.warning("Metrics collection already running")
            return
        
        self.is_collecting = True
        self.metrics_data = []
        self.start_time = time.time()
        self.stop_event.clear()
        
        # Start collection thread
        self.collection_thread = threading.Thread(target=self._collection_loop)
        self.collection_thread.daemon = True
        self.collection_thread.start()
        
        logger.info("Started collecting performance metrics")
    
    def stop_collection(self):
        """Stop collecting metrics"""
        if not self.is_collecting:
            logger.warning("Metrics collection not running")
            return
        
        self.is_collecting = False
        self.stop_event.set()
        
        if self.collection_thread:
            self.collection_thread.join(timeout=5)
        
        logger.info("Stopped collecting performance metrics")
    
    def _collection_loop(self):
        """Metrics collection loop"""
        while not self.stop_event.is_set():
            try:
                metrics = self.collect_current_metrics()
                self.metrics_data.append(metrics)
                time.sleep(self.collection_interval)
            except Exception as e:
                logger.error(f"Error collecting metrics: {e}")
                time.sleep(self.collection_interval)
    
    def collect_current_metrics(self) -> Dict:
        """Collect current metrics"""
        timestamp = datetime.now().isoformat()
        
        metrics = {
            'timestamp': timestamp,
            'system': self.collect_system_metrics(),
            'gpu': self.collect_gpu_metrics(),
            'npu': self.collect_npu_metrics()
        }
        
        return metrics
    
    def collect_system_metrics(self) -> Dict:
        """Collect system metrics"""
        try:
            cpu_percent = psutil.cpu_percent(interval=0.1)
            memory = psutil.virtual_memory()
            disk = psutil.disk_usage('/')
            
            # Get network IO
            net_io = psutil.net_io_counters()
            
            return {
                'cpu_percent': cpu_percent,
                'cpu_count': psutil.cpu_count(),
                'memory_total_gb': memory.total / (1024**3),
                'memory_used_gb': memory.used / (1024**3),
                'memory_percent': memory.percent,
                'disk_total_gb': disk.total / (1024**3),
                'disk_used_gb': disk.used / (1024**3),
                'disk_percent': (disk.used / disk.total) * 100,
                'network_bytes_sent': net_io.bytes_sent,
                'network_bytes_recv': net_io.bytes_recv
            }
        except Exception as e:
            logger.error(f"Failed to collect system metrics: {e}")
            return {}
    
    def collect_gpu_metrics(self) -> Dict:
        """Collect GPU metrics"""
        gpu_metrics = {}
        
        # Try to collect NVIDIA GPU metrics
        nvidia_metrics = self._collect_nvidia_metrics()
        if nvidia_metrics:
            gpu_metrics['nvidia'] = nvidia_metrics
        
        return gpu_metrics
    
    def _collect_nvidia_metrics(self) -> Optional[Dict]:
        """Collect NVIDIA GPU metrics"""
        try:
            # Try using nvidia-smi
            result = subprocess.run(
                ['nvidia-smi', '--query-gpu=index,name,utilization.gpu,memory.used,memory.total,temperature.gpu,power.draw', 
                 '--format=csv,noheader,nounits'],
                capture_output=True, text=True, timeout=10
            )
            
            if result.returncode == 0:
                gpu_data = []
                for line in result.stdout.strip().split('\n'):
                    if line.strip():
                        parts = [p.strip() for p in line.split(',')]
                        if len(parts) >= 7:
                            gpu_data.append({
                                'index': int(parts[0]),
                                'name': parts[1],
                                'utilization_percent': float(parts[2]) if parts[2] != 'N/A' else 0,
                                'memory_used_mb': float(parts[3]) if parts[3] != 'N/A' else 0,
                                'memory_total_mb': float(parts[4]) if parts[4] != 'N/A' else 0,
                                'temperature_c': float(parts[5]) if parts[5] != 'N/A' else 0,
                                'power_draw_w': float(parts[6]) if parts[6] != 'N/A' else 0
                            })
                
                return {'gpus': gpu_data}
        
        except (subprocess.TimeoutExpired, subprocess.CalledProcessError, FileNotFoundError):
            pass
        
        # Try using PyTorch
        try:
            import torch
            if torch.cuda.is_available():
                gpu_data = []
                for i in range(torch.cuda.device_count()):
                    props = torch.cuda.get_device_properties(i)
                    gpu_data.append({
                        'index': i,
                        'name': props.name,
                        'memory_used_mb': torch.cuda.memory_allocated(i) / (1024**2),
                        'memory_total_mb': props.total_memory / (1024**2)
                    })
                
                return {'gpus': gpu_data}
        
        except ImportError:
            pass
        
        return None
    
    def collect_npu_metrics(self) -> Dict:
        """Collect NPU metrics"""
        npu_metrics = {}
        
        # Try to collect Huawei Ascend NPU metrics
        ascend_metrics = self._collect_ascend_metrics()
        if ascend_metrics:
            npu_metrics['ascend'] = ascend_metrics
        
        return npu_metrics
    
    def _collect_ascend_metrics(self) -> Optional[Dict]:
        """Collect Huawei Ascend NPU metrics"""
        try:
            # Try using npu-smi
            result = subprocess.run(
                ['npu-smi', 'info'],
                capture_output=True, text=True, timeout=10
            )
            
            if result.returncode == 0:
                # Parse npu-smi output
                lines = result.stdout.strip().split('\n')
                npu_data = []
                
                for line in lines:
                    if 'NPU' in line and ':' in line:
                        parts = line.split(':')
                        if len(parts) >= 2:
                            npu_data.append({
                                'name': parts[1].strip() if len(parts) > 1 else 'Unknown',
                                'utilization_percent': 0,
                                'memory_used_mb': 0,
                                'memory_total_mb': 0,
                                'temperature_c': 0,
                                'power_draw_w': 0
                            })
                
                return {'npus': npu_data}
        
        except (subprocess.TimeoutExpired, subprocess.CalledProcessError, FileNotFoundError):
            pass
        
        return None
    
    def get_metrics_summary(self) -> Dict:
        """Get metrics summary"""
        if not self.metrics_data:
            return {}
        
        # Calculate averages
        system_metrics = []
        gpu_metrics = []
        npu_metrics = []
        
        for metrics in self.metrics_data:
            if 'system' in metrics:
                system_metrics.append(metrics['system'])
            if 'gpu' in metrics:
                gpu_metrics.append(metrics['gpu'])
            if 'npu' in metrics:
                npu_metrics.append(metrics['npu'])
        
        summary = {
            'collection_duration': time.time() - self.start_time if self.start_time else 0,
            'total_samples': len(self.metrics_data),
            'system': self._calculate_average_metrics(system_metrics),
            'gpu': self._calculate_average_metrics(gpu_metrics),
            'npu': self._calculate_average_metrics(npu_metrics)
        }
        
        return summary
    
    def _calculate_average_metrics(self, metrics_list: List[Dict]) -> Dict:
        """Calculate average metrics"""
        if not metrics_list:
            return {}
        
        # Simple average calculation
        # More complex statistical calculations can be implemented here as needed
        return {
            'avg_cpu_percent': sum(m.get('cpu_percent', 0) for m in metrics_list) / len(metrics_list),
            'avg_memory_percent': sum(m.get('memory_percent', 0) for m in metrics_list) / len(metrics_list),
            'max_cpu_percent': max(m.get('cpu_percent', 0) for m in metrics_list),
            'max_memory_percent': max(m.get('memory_percent', 0) for m in metrics_list)
        }
    
    def save_metrics(self, filepath: str):
        """Save metrics to file"""
        try:
            with open(filepath, 'w', encoding='utf-8') as f:
                json.dump({
                    'summary': self.get_metrics_summary(),
                    'raw_data': self.metrics_data
                }, f, indent=2, ensure_ascii=False)
            
            logger.info(f"Metrics saved to: {filepath}")
        
        except Exception as e:
            logger.error(f"Failed to save metrics: {e}")
    
    def clear_metrics(self):
        """Clear collected metrics"""
        self.metrics_data = []
        logger.info("Metrics data cleared")
    
    def get_latest_metrics(self) -> Optional[Dict]:
        """Get latest metrics"""
        if self.metrics_data:
            return self.metrics_data[-1]
        return None 