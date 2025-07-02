#!/bin/bash

set -e

IMAGE_NAME="shaowenchen/xpu-benchmark:gpu-inference-triton"

echo "Building Triton Server image: $IMAGE_NAME"
nerdctl build --tag $IMAGE_NAME .

echo "✅ Image built successfully!"
echo "Image: $IMAGE_NAME" 