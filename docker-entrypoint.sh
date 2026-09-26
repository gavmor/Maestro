#!/usr/bin/env bash
set -e

export HOME=/home/user
export PYTHONUNBUFFERED=1
export HF_HOME=${HF_HOME:-/home/user/.cache/huggingface}
export SERVER_NAME=${SERVER_NAME:-0.0.0.0}
export SERVER_PORT=${SERVER_PORT:-7860}

export OMP_NUM_THREADS=$(nproc)
export MKL_NUM_THREADS=$(nproc)
export OPENBLAS_NUM_THREADS=$(nproc)
export NUMEXPR_NUM_THREADS=$(nproc)

export TORCH_ALLOW_TF32_CUBLAS=1
export TORCH_ALLOW_TF32_CUDNN=1
export SDL_AUDIODRIVER=dummy
export PULSE_RUNTIME_PATH=/tmp/pulse-runtime

cd /workspace/app

# If the command starts with an option flag, pass it to launch.py
if [ "${1#-}" != "$1" ]; then
    set -- python3 launch.py "$@"
fi

exec "$@"
