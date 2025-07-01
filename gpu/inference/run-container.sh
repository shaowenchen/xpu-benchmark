if command -v nerdctl &>/dev/null; then
    CONTAINER_RUNTIME="nerdctl"
else
    CONTAINER_RUNTIME="docker"
fi

$CONTAINER_RUNTIME run -it --gpus all shaowenchen/xpu-benchmark:gpu-inference-latest 