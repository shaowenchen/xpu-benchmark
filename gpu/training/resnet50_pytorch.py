#!/usr/bin/env python3
"""
ResNet50 PyTorch Training Benchmark
Supports NVIDIA GPUs
"""

import argparse
import json
import os
import sys
import time
from datetime import datetime
from pathlib import Path

import numpy as np
import psutil
import torch
import torch.nn as nn
import torch.optim as optim
from torch.utils.data import DataLoader, TensorDataset
from torchvision import models, transforms

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

class ResNet50Benchmark:
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
    
    def create_dummy_dataset(self, num_samples=1000, image_size=224):
        """Create dummy dataset"""
        print(f"Creating dummy dataset: {num_samples} samples, {image_size}x{image_size}")
        
        # Create dummy image data
        images = torch.randn(num_samples, 3, image_size, image_size)
        labels = torch.randint(0, 1000, (num_samples,))
        
        dataset = TensorDataset(images, labels)
        return dataset
    
    def create_model(self):
        """Create ResNet50 model"""
        print("Creating ResNet50 model...")
        
        model = models.resnet50(pretrained=False)
        model = model.to(self.device)
        
        return model
    
    def train_model(self, model, dataloader, num_epochs):
        """Train model"""
        print(f"Starting training: {num_epochs} epochs")
        
        criterion = nn.CrossEntropyLoss()
        optimizer = optim.Adam(model.parameters(), lr=self.config['benchmarks']['training']['resnet50_pytorch']['learning_rate'])
        
        # Enable mixed precision training
        if self.config['benchmarks']['training']['resnet50_pytorch'].get('mixed_precision', False):
            scaler = torch.cuda.amp.GradScaler()
            print("Enabled mixed precision training")
        
        training_metrics = []
        
        for epoch in range(num_epochs):
            epoch_start_time = time.time()
            model.train()
            running_loss = 0.0
            correct = 0
            total = 0
            
            for batch_idx, (data, target) in enumerate(dataloader):
                data, target = data.to(self.device), target.to(self.device)
                
                optimizer.zero_grad()
                
                if self.config['benchmarks']['training']['resnet50_pytorch'].get('mixed_precision', False):
                    with torch.cuda.amp.autocast():
                        output = model(data)
                        loss = criterion(output, target)
                    
                    scaler.scale(loss).backward()
                    scaler.step(optimizer)
                    scaler.update()
                else:
                    output = model(data)
                    loss = criterion(output, target)
                    loss.backward()
                    optimizer.step()
                
                running_loss += loss.item()
                _, predicted = output.max(1)
                total += target.size(0)
                correct += predicted.eq(target).sum().item()
                
                # Collect metrics
                if batch_idx % 10 == 0:
                    gpu_metrics = self.metrics_collector.collect_gpu_metrics()
                    system_metrics = self.metrics_collector.collect_system_metrics()
                    
                    training_metrics.append({
                        'epoch': epoch,
                        'batch': batch_idx,
                        'loss': loss.item(),
                        'accuracy': 100. * correct / total,
                        'gpu_metrics': gpu_metrics,
                        'system_metrics': system_metrics,
                        'timestamp': datetime.now().isoformat()
                    })
            
            epoch_time = time.time() - epoch_start_time
            epoch_loss = running_loss / len(dataloader)
            epoch_accuracy = 100. * correct / total
            
            print(f"Epoch {epoch+1}/{num_epochs}: "
                  f"Loss: {epoch_loss:.4f}, "
                  f"Accuracy: {epoch_accuracy:.2f}%, "
                  f"Time: {epoch_time:.2f}s")
        
        return training_metrics
    
    def run_benchmark(self):
        """Run benchmark"""
        print("=== ResNet50 PyTorch Training Benchmark ===")
        
        # Get configuration
        config = self.config['benchmarks']['training']['resnet50_pytorch']
        batch_size = config['batch_size']
        num_epochs = config['epochs']
        
        # Create dataset and data loader
        dataset = self.create_dummy_dataset()
        dataloader = DataLoader(dataset, batch_size=batch_size, shuffle=True, num_workers=4)
        
        # Create model
        model = self.create_model()
        
        # Start metrics collection
        self.metrics_collector.start_collection()
        
        # Train model
        start_time = time.time()
        training_metrics = self.train_model(model, dataloader, num_epochs)
        total_time = time.time() - start_time
        
        # Stop metrics collection
        self.metrics_collector.stop_collection()
        
        # Calculate final metrics
        final_metrics = {
            'test_name': 'resnet50_pytorch_training',
            'hardware_type': self.config['hardware']['type'],
            'total_time': total_time,
            'epochs': num_epochs,
            'batch_size': batch_size,
            'device': str(self.device),
            'training_metrics': training_metrics,
            'status': 'success',
            'timestamp': datetime.now().isoformat()
        }
        
        # Save results
        self.save_results(final_metrics)
        
        print(f"Benchmark completed! Total time: {total_time:.2f}s")
        return final_metrics
    
    def save_results(self, results):
        """Save test results"""
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        result_file = self.output_dir / f"resnet50_pytorch_training_{timestamp}.json"
        
        with open(result_file, 'w') as f:
            json.dump(results, f, indent=2)
        
        print(f"Results saved to: {result_file}")

def main():
    parser = argparse.ArgumentParser(description='ResNet50 PyTorch Training Benchmark')
    parser.add_argument('--config', required=True, help='Configuration file path')
    parser.add_argument('--output', required=True, help='Output directory')
    
    args = parser.parse_args()
    
    # Run benchmark
    benchmark = ResNet50Benchmark(args.config, args.output)
    results = benchmark.run_benchmark()
    
    print("Test completed!")

if __name__ == '__main__':
    main() 