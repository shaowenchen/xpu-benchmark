#!/bin/bash

set -e

IMAGE_NAME="shaowenchen/xpu-benchmark:gpu-inference"

nerdctl build --tag $IMAGE_NAME .