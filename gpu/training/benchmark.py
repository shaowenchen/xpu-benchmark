#!/usr/bin/env python3
"""
Benchmark Script for ResNet-50 Training
Quick performance evaluation script
"""

import torch
import torch.nn as nn
import torch.optim as optim
import torchvision
import torchvision.transforms as transforms
from torch.utils.data import DataLoader
import time
import json
import argparse
import os

def get_args():
    parser = argparse.ArgumentParser(description='ResNet-50 Benchmark')
    parser.add_argument('--batch-size', type=int, default=128, help='Batch size')
    parser.add_argument('--iterations', type=int, default=100, help='Number of iterations')
    parser.add_argument('--warmup', type=int, default=10, help='Warmup iterations')
    parser.add_argument('--mixed-precision', action='store_true', help='Use mixed precision')
    parser.add_argument('--output', type=str, default='/data/logs/benchmark.json', help='Output file')
    return parser.parse_args()

def create_dummy_data(batch_size, num_iterations, dataset='mnist'):
    """Create dummy data for benchmark"""
    data = []
    for _ in range(num_iterations):
        if dataset == 'mnist':
            # MNIST-like data (grayscale converted to RGB, 32x32)
            inputs = torch.randn(batch_size, 3, 32, 32)
        elif dataset == 'cifar10':
            # CIFAR-10 data (RGB, 32x32)
            inputs = torch.randn(batch_size, 3, 32, 32)
        else:
            # Default to MNIST format
            inputs = torch.randn(batch_size, 3, 32, 32)
        
        targets = torch.randint(0, 10, (batch_size,))
        data.append((inputs, targets))
    return data

def benchmark_training(args):
    """Benchmark training performance"""
    # Setup
    device = torch.device('cuda' if torch.cuda.is_available() else 'cpu')
    model = torchvision.models.resnet50(pretrained=False)
    model.fc = nn.Linear(model.fc.in_features, 10)  # CIFAR-10 classes
    model = model.to(device)
    
    criterion = nn.CrossEntropyLoss()
    optimizer = optim.SGD(model.parameters(), lr=0.001, momentum=0.9)
    scaler = torch.cuda.amp.GradScaler() if args.mixed_precision else None
    
    # Create dummy data
    data = create_dummy_data(args.batch_size, args.iterations + args.warmup, 'mnist')
    
    # Warmup
    print("Warming up...")
    model.train()
    for i in range(args.warmup):
        inputs, targets = data[i]
        inputs, targets = inputs.to(device), targets.to(device)
        
        optimizer.zero_grad()
        
        if args.mixed_precision:
            with torch.cuda.amp.autocast():
                outputs = model(inputs)
                loss = criterion(outputs, targets)
            scaler.scale(loss).backward()
            scaler.step(optimizer)
            scaler.update()
        else:
            outputs = model(inputs)
            loss = criterion(outputs, targets)
            loss.backward()
            optimizer.step()
    
    # Benchmark
    print("Running benchmark...")
    torch.cuda.synchronize() if torch.cuda.is_available() else None
    start_time = time.time()
    
    total_samples = 0
    for i in range(args.warmup, args.warmup + args.iterations):
        inputs, targets = data[i]
        inputs, targets = inputs.to(device), targets.to(device)
        total_samples += inputs.size(0)
        
        optimizer.zero_grad()
        
        if args.mixed_precision:
            with torch.cuda.amp.autocast():
                outputs = model(inputs)
                loss = criterion(outputs, targets)
            scaler.scale(loss).backward()
            scaler.step(optimizer)
            scaler.update()
        else:
            outputs = model(inputs)
            loss = criterion(outputs, targets)
            loss.backward()
            optimizer.step()
    
    torch.cuda.synchronize() if torch.cuda.is_available() else None
    end_time = time.time()
    
    elapsed_time = end_time - start_time
    throughput = total_samples / elapsed_time
    
    # Results
    results = {
        'device': str(device),
        'batch_size': args.batch_size,
        'iterations': args.iterations,
        'warmup': args.warmup,
        'mixed_precision': args.mixed_precision,
        'total_samples': total_samples,
        'elapsed_time': elapsed_time,
        'throughput_samples_per_sec': throughput,
        'time_per_batch': elapsed_time / args.iterations,
        'gpu_info': {
            'name': torch.cuda.get_device_name(0) if torch.cuda.is_available() else 'N/A',
            'memory_total': torch.cuda.get_device_properties(0).total_memory if torch.cuda.is_available() else 'N/A',
            'memory_used': torch.cuda.memory_allocated(0) if torch.cuda.is_available() else 'N/A'
        }
    }
    
    print(f"\nBenchmark Results:")
    print(f"Device: {results['device']}")
    print(f"Batch size: {results['batch_size']}")
    print(f"Total samples: {results['total_samples']}")
    print(f"Elapsed time: {results['elapsed_time']:.2f} seconds")
    print(f"Throughput: {results['throughput_samples_per_sec']:.2f} samples/second")
    print(f"Time per batch: {results['time_per_batch']:.4f} seconds")
    print(f"Mixed precision: {results['mixed_precision']}")
    
    if torch.cuda.is_available():
        print(f"GPU: {results['gpu_info']['name']}")
        print(f"Memory used: {results['gpu_info']['memory_used'] / 1024**3:.2f} GB")
    
    # Save results
    os.makedirs(os.path.dirname(args.output), exist_ok=True)
    with open(args.output, 'w') as f:
        json.dump(results, f, indent=2)
    
    return results

def main():
    args = get_args()
    benchmark_training(args)

if __name__ == "__main__":
    main() 