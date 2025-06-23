if command -v nerdctl &>/dev/null; then
    CONTAINER_RUNTIME="nerdctl"
else
    CONTAINER_RUNTIME="docker"
fi

$CONTAINER_RUNTIME run -it --rm --gpus 1 shaowenchen/xpu-benchmark:npu-inference-latest 