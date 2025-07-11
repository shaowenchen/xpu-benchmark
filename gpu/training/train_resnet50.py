#!/usr/bin/env python3
"""
ResNet-50 Training Script for XPU Benchmark
A quick validation training script using ResNet-50 on CIFAR-10
"""

import torch
import torch.nn as nn
import torch.optim as optim
import torchvision
import torchvision.transforms as transforms
from torch.utils.data import DataLoader
from torch.utils.tensorboard import SummaryWriter
import argparse
import time
import os
import json

def get_args():
    parser = argparse.ArgumentParser(description='ResNet-50 Training')
    
    # Training parameters
    parser.add_argument('--batch-size', type=int, default=128, help='Batch size for training')
    parser.add_argument('--epochs', type=int, default=10, help='Number of training epochs')
    parser.add_argument('--lr', type=float, default=0.001, help='Learning rate')
    parser.add_argument('--momentum', type=float, default=0.9, help='SGD momentum')
    parser.add_argument('--weight-decay', type=float, default=1e-4, help='Weight decay')
    
    # Model parameters
    parser.add_argument('--model', type=str, default='resnet50', help='Model architecture')
    parser.add_argument('--num-classes', type=int, default=10, help='Number of classes')
    parser.add_argument('--pretrained', action='store_true', help='Use pretrained model')
    
    # Dataset parameters
    parser.add_argument('--dataset', type=str, default='mnist', help='Dataset to use (mnist, cifar10, fashion-mnist)')
    parser.add_argument('--data-root', type=str, default='/data/datasets', help='Dataset root directory')
    parser.add_argument('--num-workers', type=int, default=4, help='Number of data loading workers')
    
    # Device parameters
    parser.add_argument('--device', type=str, default='auto', help='Device to use (auto, cpu, cuda)')
    parser.add_argument('--mixed-precision', action='store_true', help='Use mixed precision training')
    
    # Logging parameters
    parser.add_argument('--log-dir', type=str, default='/data/logs', help='Log directory')
    parser.add_argument('--save-model', action='store_true', help='Save trained model')
    parser.add_argument('--benchmark', action='store_true', help='Run benchmark mode')
    
    return parser.parse_args()

class ResNet50Trainer:
    def __init__(self, args):
        self.args = args
        self.device = self._get_device()
        self.model = self._get_model()
        self.criterion = nn.CrossEntropyLoss()
        self.optimizer = optim.SGD(self.model.parameters(), 
                                   lr=args.lr, 
                                   momentum=args.momentum,
                                   weight_decay=args.weight_decay)
        self.scheduler = optim.lr_scheduler.StepLR(self.optimizer, step_size=30, gamma=0.1)
        self.train_loader, self.test_loader = self._get_data_loaders()
        self.writer = SummaryWriter(log_dir=args.log_dir)
        self.scaler = torch.cuda.amp.GradScaler() if args.mixed_precision else None
        
    def _get_device(self):
        if self.args.device == 'auto':
            if torch.cuda.is_available():
                device = torch.device('cuda')
                print(f"Using CUDA: {torch.cuda.get_device_name(0)}")
            else:
                device = torch.device('cpu')
                print("Using CPU")
        else:
            device = torch.device(self.args.device)
        return device
    
    def _get_model(self):
        if self.args.model == 'resnet50':
            # Use new weights API instead of deprecated pretrained parameter
            if self.args.pretrained:
                from torchvision.models import ResNet50_Weights
                weights = ResNet50_Weights.IMAGENET1K_V1
            else:
                weights = None
            model = torchvision.models.resnet50(weights=weights)
            # Modify the final layer for CIFAR-10
            model.fc = nn.Linear(model.fc.in_features, self.args.num_classes)
        else:
            raise ValueError(f"Unsupported model: {self.args.model}")
        
        model = model.to(self.device)
        return model
    
    def _get_data_loaders(self):
        if self.args.dataset == 'mnist':
            # MNIST transforms - convert to 3 channels and resize for ResNet
            transform_train = transforms.Compose([
                transforms.Resize((32, 32)),  # Resize to match ResNet input expectation
                transforms.ToTensor(),
                transforms.Lambda(lambda x: x.repeat(3, 1, 1)),  # Convert grayscale to RGB
                transforms.Normalize((0.1307, 0.1307, 0.1307), (0.3081, 0.3081, 0.3081)),  # MNIST stats repeated for 3 channels
            ])
            
            transform_test = transforms.Compose([
                transforms.Resize((32, 32)),
                transforms.ToTensor(),
                transforms.Lambda(lambda x: x.repeat(3, 1, 1)),
                transforms.Normalize((0.1307, 0.1307, 0.1307), (0.3081, 0.3081, 0.3081)),
            ])
            
            trainset = torchvision.datasets.MNIST(
                root=self.args.data_root, train=True, download=True, transform=transform_train
            )
            train_loader = DataLoader(
                trainset, batch_size=self.args.batch_size, shuffle=True, 
                num_workers=self.args.num_workers, pin_memory=True
            )
            
            testset = torchvision.datasets.MNIST(
                root=self.args.data_root, train=False, download=True, transform=transform_test
            )
            test_loader = DataLoader(
                testset, batch_size=self.args.batch_size, shuffle=False, 
                num_workers=self.args.num_workers, pin_memory=True
            )
        elif self.args.dataset == 'cifar10':
            # CIFAR-10 transforms
            transform_train = transforms.Compose([
                transforms.RandomCrop(32, padding=4),
                transforms.RandomHorizontalFlip(),
                transforms.ToTensor(),
                transforms.Normalize((0.4914, 0.4822, 0.4465), (0.2023, 0.1994, 0.2010)),
            ])
            
            transform_test = transforms.Compose([
                transforms.ToTensor(),
                transforms.Normalize((0.4914, 0.4822, 0.4465), (0.2023, 0.1994, 0.2010)),
            ])
            
            trainset = torchvision.datasets.CIFAR10(
                root=self.args.data_root, train=True, download=True, transform=transform_train
            )
            train_loader = DataLoader(
                trainset, batch_size=self.args.batch_size, shuffle=True, 
                num_workers=self.args.num_workers, pin_memory=True
            )
            
            testset = torchvision.datasets.CIFAR10(
                root=self.args.data_root, train=False, download=True, transform=transform_test
            )
            test_loader = DataLoader(
                testset, batch_size=self.args.batch_size, shuffle=False, 
                num_workers=self.args.num_workers, pin_memory=True
            )
        elif self.args.dataset == 'fashion-mnist':
            # Fashion-MNIST transforms - convert to 3 channels and resize for ResNet
            transform_train = transforms.Compose([
                transforms.Resize((32, 32)),  # Resize to match ResNet input expectation
                transforms.ToTensor(),
                transforms.Lambda(lambda x: x.repeat(3, 1, 1)),  # Convert grayscale to RGB
                transforms.Normalize((0.2860, 0.2860, 0.2860), (0.3530, 0.3530, 0.3530)),  # Fashion-MNIST stats repeated for 3 channels
            ])
            
            transform_test = transforms.Compose([
                transforms.Resize((32, 32)),
                transforms.ToTensor(),
                transforms.Lambda(lambda x: x.repeat(3, 1, 1)),
                transforms.Normalize((0.2860, 0.2860, 0.2860), (0.3530, 0.3530, 0.3530)),
            ])
            
            trainset = torchvision.datasets.FashionMNIST(
                root=self.args.data_root, train=True, download=True, transform=transform_train
            )
            train_loader = DataLoader(
                trainset, batch_size=self.args.batch_size, shuffle=True, 
                num_workers=self.args.num_workers, pin_memory=True
            )
            
            testset = torchvision.datasets.FashionMNIST(
                root=self.args.data_root, train=False, download=True, transform=transform_test
            )
            test_loader = DataLoader(
                testset, batch_size=self.args.batch_size, shuffle=False, 
                num_workers=self.args.num_workers, pin_memory=True
            )
        else:
            raise ValueError(f"Unsupported dataset: {self.args.dataset}")
        
        return train_loader, test_loader
    
    def train_epoch(self, epoch):
        self.model.train()
        running_loss = 0.0
        correct = 0
        total = 0
        
        epoch_start_time = time.time()
        
        for batch_idx, (inputs, targets) in enumerate(self.train_loader):
            inputs, targets = inputs.to(self.device), targets.to(self.device)
            
            self.optimizer.zero_grad()
            
            if self.args.mixed_precision:
                with torch.cuda.amp.autocast():
                    outputs = self.model(inputs)
                    loss = self.criterion(outputs, targets)
                
                self.scaler.scale(loss).backward()
                self.scaler.step(self.optimizer)
                self.scaler.update()
            else:
                outputs = self.model(inputs)
                loss = self.criterion(outputs, targets)
                loss.backward()
                self.optimizer.step()
            
            running_loss += loss.item()
            _, predicted = outputs.max(1)
            total += targets.size(0)
            correct += predicted.eq(targets).sum().item()
            
            if batch_idx % 100 == 0:
                elapsed = time.time() - epoch_start_time
                progress = 100. * batch_idx / len(self.train_loader)
                print(f'Epoch {epoch+1}, Batch {batch_idx}/{len(self.train_loader)} ({progress:.1f}%), '
                      f'Loss: {loss.item():.4f}, Acc: {100.*correct/total:.2f}%, '
                      f'Time: {elapsed:.1f}s')
        
        epoch_duration = time.time() - epoch_start_time
        epoch_loss = running_loss / len(self.train_loader)
        epoch_acc = 100. * correct / total
        
        # Log to TensorBoard
        self.writer.add_scalar('Train/Loss', epoch_loss, epoch)
        self.writer.add_scalar('Train/Accuracy', epoch_acc, epoch)
        self.writer.add_scalar('Time/Train_Epoch_Duration', epoch_duration, epoch)
        
        return epoch_loss, epoch_acc
    
    def test_epoch(self, epoch):
        self.model.eval()
        test_loss = 0.0
        correct = 0
        total = 0
        
        test_start_time = time.time()
        
        with torch.no_grad():
            for inputs, targets in self.test_loader:
                inputs, targets = inputs.to(self.device), targets.to(self.device)
                
                if self.args.mixed_precision:
                    with torch.cuda.amp.autocast():
                        outputs = self.model(inputs)
                        loss = self.criterion(outputs, targets)
                else:
                    outputs = self.model(inputs)
                    loss = self.criterion(outputs, targets)
                
                test_loss += loss.item()
                _, predicted = outputs.max(1)
                total += targets.size(0)
                correct += predicted.eq(targets).sum().item()
        
        test_duration = time.time() - test_start_time
        epoch_loss = test_loss / len(self.test_loader)
        epoch_acc = 100. * correct / total
        
        # Log to TensorBoard
        self.writer.add_scalar('Test/Loss', epoch_loss, epoch)
        self.writer.add_scalar('Test/Accuracy', epoch_acc, epoch)
        self.writer.add_scalar('Time/Test_Epoch_Duration', test_duration, epoch)
        
        return epoch_loss, epoch_acc
    
    def benchmark(self):
        """Run benchmark to measure training throughput"""
        self.model.train()
        torch.backends.cudnn.benchmark = True
        
        # Warm up
        print("Warming up...")
        for i, (inputs, targets) in enumerate(self.train_loader):
            if i >= 10:  # Warm up for 10 batches
                break
            inputs, targets = inputs.to(self.device), targets.to(self.device)
            
            with torch.cuda.amp.autocast() if self.args.mixed_precision else torch.no_grad():
                outputs = self.model(inputs)
                loss = self.criterion(outputs, targets)
            
            if not torch.no_grad:
                loss.backward()
                self.optimizer.step()
                self.optimizer.zero_grad()
        
        # Benchmark
        print("Running benchmark...")
        start_time = time.time()
        total_samples = 0
        
        for i, (inputs, targets) in enumerate(self.train_loader):
            if i >= 100:  # Benchmark for 100 batches
                break
            
            inputs, targets = inputs.to(self.device), targets.to(self.device)
            total_samples += inputs.size(0)
            
            with torch.cuda.amp.autocast() if self.args.mixed_precision else torch.no_grad():
                outputs = self.model(inputs)
                loss = self.criterion(outputs, targets)
            
            if not torch.no_grad:
                loss.backward()
                self.optimizer.step()
                self.optimizer.zero_grad()
        
        end_time = time.time()
        elapsed_time = end_time - start_time
        throughput = total_samples / elapsed_time
        
        print(f"Benchmark Results:")
        print(f"Total samples: {total_samples}")
        print(f"Elapsed time: {elapsed_time:.2f} seconds")
        print(f"Throughput: {throughput:.2f} samples/second")
        
        return throughput
    
    def train(self):
        print(f"Starting training on {self.device}")
        print(f"Model: {self.args.model}")
        print(f"Dataset: {self.args.dataset}")
        print(f"Batch size: {self.args.batch_size}")
        print(f"Epochs: {self.args.epochs}")
        
        if self.args.benchmark:
            throughput = self.benchmark()
            # Save benchmark results
            results = {
                'throughput': throughput,
                'batch_size': self.args.batch_size,
                'device': str(self.device),
                'model': self.args.model,
                'mixed_precision': self.args.mixed_precision
            }
            with open(os.path.join(self.args.log_dir, 'benchmark_results.json'), 'w') as f:
                json.dump(results, f, indent=2)
            return
        
        best_acc = 0.0
        
        # Record total training start time
        total_start_time = time.time()
        epoch_times = []
        
        for epoch in range(self.args.epochs):
            print(f"\nEpoch {epoch+1}/{self.args.epochs}")
            print("-" * 50)
            
            # Record epoch start time
            epoch_start_time = time.time()
            
            # Train
            train_loss, train_acc = self.train_epoch(epoch)
            train_time = time.time() - epoch_start_time
            
            # Test
            test_start_time = time.time()
            test_loss, test_acc = self.test_epoch(epoch)
            test_time = time.time() - test_start_time
            
            # Update learning rate
            self.scheduler.step()
            
            # Calculate total epoch time
            epoch_end_time = time.time()
            epoch_duration = epoch_end_time - epoch_start_time
            epoch_times.append(epoch_duration)
            
            # Log epoch time to TensorBoard
            self.writer.add_scalar('Time/Total_Epoch_Duration', epoch_duration, epoch)
            
            print(f"📊 Results:")
            print(f"   Train Loss: {train_loss:.4f}, Train Acc: {train_acc:.2f}% (Time: {train_time:.1f}s)")
            print(f"   Test Loss: {test_loss:.4f}, Test Acc: {test_acc:.2f}% (Time: {test_time:.1f}s)")
            print(f"   Total Epoch Time: {epoch_duration:.2f} seconds")
            
            # Save best model
            if test_acc > best_acc:
                best_acc = test_acc
                if self.args.save_model:
                    torch.save(self.model.state_dict(), 
                              os.path.join(self.args.log_dir, 'best_model.pth'))
        
        # Calculate total training time
        total_end_time = time.time()
        total_duration = total_end_time - total_start_time
        
        # Calculate time statistics
        avg_epoch_time = sum(epoch_times) / len(epoch_times) if epoch_times else 0
        min_epoch_time = min(epoch_times) if epoch_times else 0
        max_epoch_time = max(epoch_times) if epoch_times else 0
        
        print(f"\n" + "="*70)
        print(f"🎉 Training completed! Best accuracy: {best_acc:.2f}%")
        print(f"📊 Time Statistics:")
        print(f"   Total training time: {total_duration:.2f} seconds ({total_duration/60:.2f} minutes)")
        print(f"   Average epoch time: {avg_epoch_time:.2f} seconds")
        print(f"   Fastest epoch: {min_epoch_time:.2f} seconds")
        print(f"   Slowest epoch: {max_epoch_time:.2f} seconds")
        print(f"   Epochs completed: {len(epoch_times)}")
        print(f"="*70)
        
        # Save training time statistics
        time_stats = {
            'total_duration': total_duration,
            'total_duration_minutes': total_duration / 60,
            'avg_epoch_time': avg_epoch_time,
            'min_epoch_time': min_epoch_time,
            'max_epoch_time': max_epoch_time,
            'epoch_times': epoch_times,
            'epochs_completed': len(epoch_times),
            'best_accuracy': best_acc
        }
        
        with open(os.path.join(self.args.log_dir, 'training_time_stats.json'), 'w') as f:
            json.dump(time_stats, f, indent=2)
        
        print(f"📝 Time statistics saved to: {os.path.join(self.args.log_dir, 'training_time_stats.json')}")
        
        self.writer.close()

def main():
    args = get_args()
    
    # Create directories
    os.makedirs(args.log_dir, exist_ok=True)
    os.makedirs(args.data_root, exist_ok=True)
    
    # Create trainer and start training
    trainer = ResNet50Trainer(args)
    trainer.train()

if __name__ == "__main__":
    main() 