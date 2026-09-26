# syntax=docker/dockerfile:1

# ─────────────────────────────────────────────────────────────
# Stage 1: Build the React UI
# ─────────────────────────────────────────────────────────────
FROM node:22-slim AS ui-builder

WORKDIR /app/ui

# Enable corepack for pnpm
RUN corepack enable && corepack prepare pnpm@latest --activate

# Copy UI package specifications
COPY ui/package.json ui/pnpm-lock.yaml* ./

# Install dependencies (permitting build scripts required by esbuild)
RUN pnpm install --frozen-lockfile --dangerously-allow-all-builds || \
    pnpm install --dangerously-allow-all-builds

# Copy full UI source and build to dist
COPY ui/ ./
RUN pnpm run build

# ─────────────────────────────────────────────────────────────
# Stage 2: CUDA / Python 3.12 Runtime
# ─────────────────────────────────────────────────────────────
FROM nvidia/cuda:12.8.1-devel-ubuntu24.04 AS runtime

ENV DEBIAN_FRONTEND=noninteractive \
    PYTHONUNBUFFERED=1 \
    HF_HOME=/home/user/.cache/huggingface \
    TORCH_ALLOW_TF32_CUBLAS=1 \
    TORCH_ALLOW_TF32_CUDNN=1 \
    SDL_AUDIODRIVER=dummy \
    PULSE_RUNTIME_PATH=/tmp/pulse-runtime \
    SERVER_NAME=0.0.0.0 \
    SERVER_PORT=7860 \
    VIRTUAL_ENV=/opt/venv \
    PATH="/opt/venv/bin:$PATH"

# Install system dependencies
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    python3 python3-pip python3-dev python3-venv \
    git wget curl cmake ninja-build \
    libgl1 libglib2.0-0 ffmpeg \
    ca-certificates && \
    rm -rf /var/lib/apt/lists/*

# Install uv for fast, reliable Python dependency installation
RUN curl -LsSf https://astral.sh/uv/install.sh | sh && \
    mv /root/.local/bin/uv /usr/local/bin/uv

# Create virtual environment
RUN uv venv /opt/venv

# Install PyTorch 2.10.0 with CUDA 12.8
RUN uv pip install --no-cache \
    torch==2.10.0+cu128 torchvision==0.25.0+cu128 torchaudio==2.10.0+cu128 \
    --index-url https://download.pytorch.org/whl/cu128

WORKDIR /workspace

# Install requirements
COPY app/requirements.txt /workspace/app/requirements.txt
RUN uv pip install --no-cache \
    -r /workspace/app/requirements.txt \
    --index-strategy unsafe-best-match

# Clone maestro-seedvc voice-conversion component (GPL-3.0)
RUN git clone --depth 1 --branch v1.0.0 https://github.com/Blizaine/maestro-seedvc /workspace/app/postprocessing/seedvc

# Copy application source code
COPY app/ /workspace/app/

# Copy built React UI from ui-builder stage
COPY --from=ui-builder /app/ui/dist /workspace/ui/dist

# Copy entrypoint script
COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

# Ubuntu 24.04 includes a default 'ubuntu' user with UID 1000; remove it first
RUN (userdel -r ubuntu 2>/dev/null || true) && \
    (groupdel ubuntu 2>/dev/null || true) && \
    useradd -u 1000 -ms /bin/bash user && \
    mkdir -p /home/user/.cache/huggingface \
             /workspace/app/ckpts \
             /workspace/app/outputs \
             /workspace/app/loras \
             /workspace/app/settings && \
    chown -R user:user /workspace /home/user

USER user
WORKDIR /workspace/app

EXPOSE 7860

ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
CMD ["python3", "launch.py"]
