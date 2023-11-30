#!/bin/bash

set -e  # Exit immediately if a command exits with a non-zero status

# Initialize Conda
source /home/miniconda3/etc/profile.d/conda.sh # <--- Change this to the path of your conda.sh

# Path to the codebase and config file
SRC="$HOME/mbeir/src"  # Absolute path to codebse /mbeir/src # <--- Change this to the path of your mbeir/src

# Path to models_script dir
SCRIPT_DIR="$SRC/models_scripts"

# Path to MBEIR data and MBEIR directory where we store the checkpoints, embeddings, etc.
MBEIR_DIR="/data/mbeir/" # <--- Change this to the MBEIR directory
MBEIR_DATA_DIR="/data/mbeir/mbeir_data/" # <--- Change this to the MBEIR data directory

# Path to config dir
MODEL="clip_union/clip_scorefusion"  # <--- Change this to the model you want to run
MODEL_DIR="$SRC/models_scripts/$MODEL"
SIZE="large"
MODE="eval"  # <--- Change this to the mode you want to run
EXP_NAME="inbatch"
CONFIG_DIR="$MODEL_DIR/configs_scripts/$SIZE/$MODE/$EXP_NAME"

# Set CUDA devices and PYTHONPATH
export CUDA_VISIBLE_DEVICES=0,1,2,3,4,5,6,7  # <--- Change this to the CUDA devices you want to use
NPROC=8 # <--- Change this to the number of GPUs you want to use
export PYTHONPATH=$SRC
echo "PYTHONPATH: $PYTHONPATH"
echo  "CUDA_VISIBLE_DEVICES: $CUDA_VISIBLE_DEVICES"

# CD to script directory
cd $SCRIPT_DIR

# Activate conda environment
conda activate clip_sf # <--- Change this to the name of your conda environment

# Run Embedding command
CONFIG_PATH="$CONFIG_DIR/embed.yaml"
SCRIPT_NAME="mbeir_embedder.py"
echo "CONFIG_PATH: $CONFIG_PATH"
echo "SCRIPT_NAME: $SCRIPT_NAME"

python exp_utils.py \
    --update_mbeir_yaml_instruct_status \
    --mbeir_yaml_file_path $CONFIG_PATH \
    --enable_instruct False

python -m torch.distributed.run --nproc_per_node=$NPROC $SCRIPT_NAME \
    --config_path "$CONFIG_PATH" \
    --mbeir_dir "$MBEIR_DIR" \
    --mbeir_data_dir "$MBEIR_DATA_DIR"

# Activate faiss environment
conda activate faiss # <--- Change this to the name of your conda environment

# Run Index command
CONFIG_PATH="$CONFIG_DIR/index.yaml"
SCRIPT_NAME="mbeir_retriever.py"
echo "CONFIG_PATH: $CONFIG_PATH"
echo "SCRIPT_NAME: $SCRIPT_NAME"

python exp_utils.py \
    --update_mbeir_yaml_instruct_status \
    --mbeir_yaml_file_path $CONFIG_PATH \
    --enable_instruct False

python $SCRIPT_NAME \
    --config_path "$CONFIG_PATH" \
    --mbeir_dir "$MBEIR_DIR" \
    --mbeir_data_dir "$MBEIR_DATA_DIR" \
    --enable_create_index

# Run retrieval command
CONFIG_PATH="$CONFIG_DIR/retrieval.yaml"
SCRIPT_NAME="mbeir_retriever.py"
echo "CONFIG_PATH: $CONFIG_PATH"
echo "SCRIPT_NAME: $SCRIPT_NAME"

python exp_utils.py \
    --update_mbeir_yaml_instruct_status \
    --mbeir_yaml_file_path $CONFIG_PATH \
    --enable_instruct False

python $SCRIPT_NAME \
    --config_path "$CONFIG_PATH" \
    --mbeir_dir "$MBEIR_DIR" \
    --mbeir_data_dir "$MBEIR_DATA_DIR" \
    --enable_retrieval