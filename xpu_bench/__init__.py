"""
XPU Benchmark - GPU/NPU Performance Benchmarking Toolkit

This package provides benchmarking tools for testing GPU and NPU performance.
Supports NVIDIA GPUs and Huawei Ascend NPUs.
"""

__version__ = "0.1.0"
__author__ = "XPU Benchmark Team"
__email__ = "xpu-bench@example.com"

from .runner import BenchmarkRunner
from .metrics import MetricsCollector

__all__ = [
    'BenchmarkRunner',
    'MetricsCollector',
    '__version__',
    '__author__',
    '__email__'
] 