# Maestro Docker Deployment Guide

This guide covers building, deploying, and running [Blizaine/Maestro](https://github.com/Blizaine/Maestro) in Docker with NVIDIA GPU acceleration.

---

## Quick Start (Docker Compose)

### 1. Prerequisites
- Docker Engine with NVIDIA Container Toolkit (`nvidia-container-toolkit`)
- NVIDIA GPU with drivers supporting CUDA 12.8+ (RTX 30-series, 40-series, 50-series, A-series, H-series)
- Docker Compose v2+

### 2. Build and Start
```bash
# Build the image and start Maestro in the background
docker compose up -d --build
```

### 3. Access Maestro
- **Maestro Studio UI**: `http://localhost:7861/` (or configured host port)
- **Classic Gradio UI**: `http://localhost:7861/classic/`
- **REST API Docs**: `http://localhost:7861/docs`

> **Note**: Host port `7861` is used by default in `docker-compose.yml` to avoid collisions with any existing services listening on port 7860. You can customize this by setting `HOST_PORT=7860` or any other free port.

---

## Directory Mounts & Persistence

The `docker-compose.yml` mounts the following local directories for data persistence:

| Host Path | Container Path | Purpose |
|---|---|---|
| `./app/ckpts` | `/workspace/app/ckpts` | Downloaded model checkpoints and weights |
| `./app/outputs` | `/workspace/app/outputs` | Generated videos, images, and audio files |
| `./app/loras` | `/workspace/app/loras` | Custom LoRAs |
| `./app/settings` | `/workspace/app/settings` | Maestro studio settings and preferences |
| `~/.cache/huggingface` | `/home/user/.cache/huggingface` | Shared Hugging Face cache across containers |

---

## GitHub Actions & GHCR Publishing

The included workflow in `.github/workflows/docker-publish.yml` automatically builds and publishes images to GitHub Container Registry:

- **Registry**: `ghcr.io/gavmor/maestro`
- **Triggers**:
  - Push to `main` branch (tags as `:latest`)
  - Tag release (e.g. `v2.4.0`)
  - Manual trigger via **Actions → Run workflow** with custom tag

Once published, you can pull and run the prebuilt image directly without local building:
```bash
docker pull ghcr.io/gavmor/maestro:latest
docker compose up -d
```
