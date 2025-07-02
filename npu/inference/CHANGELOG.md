# Changelog

## [1.1.0] - 2024-01-XX

### Added
- **Model Parameter Support**: Added `--model` parameter to specify custom model paths
- **Default Model Path**: Set default model path to `/data/models/Qwen3-0.6B-Base`
- **Enhanced Command Line Interface**: Improved argument parsing and help messages
- **Model Path Validation**: Added model path existence checking
- **Docker Integration**: Updated Dockerfile to support model parameter
- **Documentation**: Added comprehensive README and usage examples
- **Testing**: Added test script to verify model parameter functionality

### Changed
- **Configuration**: Updated `config.yaml` to use new default model path
- **Script Structure**: Refactored `run.sh` to support command line arguments
- **Python Script**: Enhanced `bert_mindspore.py` to accept and use model parameter
- **Docker Command**: Changed default CMD to use `run.sh` instead of direct Python execution

### Technical Details

#### Files Modified

1. **`bert_mindspore.py`**
   - Added `--model` argument with default value `/data/models/Qwen3-0.6B-Base`
   - Enhanced `BERTMindSporeBenchmark` class to accept `model_path` parameter
   - Added model path validation and logging
   - Updated benchmark results to include model path information

2. **`run.sh`**
   - Added command line argument parsing for `--model` parameter
   - Added help message and usage examples
   - Enhanced error handling for invalid options
   - Updated script to pass model parameter to Python script

3. **`config.yaml`**
   - Changed default `model_path` from `/models/bert-base-uncased` to `/data/models/Qwen3-0.6B-Base`

4. **`Dockerfile`**
   - Added `DEFAULT_MODEL_PATH` environment variable
   - Updated to copy and use `run.sh` script
   - Changed default CMD to use `run.sh`
   - Added model directory creation

#### Files Added

1. **`README.md`**
   - Comprehensive documentation for NPU inference benchmark
   - Usage examples and command line options
   - Docker usage instructions
   - Troubleshooting guide

2. **`test_model_param.sh`**
   - Test script to verify model parameter functionality
   - Tests for default model, custom model, and invalid options

### Usage Examples

```bash
# Use default model
./run.sh

# Use custom model
./run.sh --model /data/models/custom-model

# Use specific model
./run.sh --model /data/models/Qwen3-0.6B-Base

# Show help
./run.sh --help
```

### Backward Compatibility

- All existing functionality remains unchanged
- Default behavior uses the new default model path
- Existing configuration files will work with the new system
- Docker containers built with previous versions will continue to work

### Testing

The new functionality has been tested with:
- ✅ Default model parameter (no `--model` specified)
- ✅ Custom model path parameter
- ✅ Invalid option handling
- ✅ Help message display
- ✅ Python script argument parsing
- ✅ Docker integration

### Migration Guide

For existing users:
1. No action required - the new default model path will be used automatically
2. To use a custom model, simply add `--model /path/to/model` to your commands
3. Update any scripts that hardcode the old model path to use the new parameter 