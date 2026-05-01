# Lemonade LLM Server 🍋

An extremely optimized Local LLM Server configuration based on [Lemonade SDK](https://github.com/lemonade-sdk/lemonade), tailored for both AMD Vega 11 APU and NVIDIA discrete GPUs on Linux (Fedora/Bazzite).

---

## Project Structure
```
lemonade/
├── server-amd/          # Config for Home Server (AMD Ryzen + Vega 11)
│   ├── docker-compose.yml
│   └── start.sh
│
├── laptop-nvidia/       # Config for Laptop (Intel i7 + NVIDIA, Bazzite)
│   ├── Dockerfile       # Custom CUDA-enabled build
│   ├── docker-compose.yml
│   └── start.sh
│
└── README.md
```
Each directory provides an isolated environment with independent volumes for models, caches, and shaders to prevent configuration or driver conflicts.

## Quick Start

### 1. On Server (AMD Vega 11)
```bash
cd server-amd
chmod +x start.sh
./start.sh
```
The API will be available at: **http://localhost:13305**

### 2. On Laptop (NVIDIA + Bazzite/Fedora)
```bash
cd laptop-nvidia
chmod +x start.sh
./start.sh
```
The API will be available at: **http://localhost:13306**

---

## Optimization Architecture

### server-amd (Vega 11 — Vulkan APU mode)
Optimized for integrated graphics using the Vulkan backend with Unified Memory support.

| Parameter | Value | Reason |
|---|---|---|
| `LEMONADE_BACKEND` | `vulkan` | Native backend for AMD on Linux |
| `GGML_VULKAN_UNIFIED_MEMORY` | `1` | Allows iGPU to access system RAM directly |
| `GGML_VULKAN_PINNED_MEMORY` | `1` | Prevents swapping of model tensors |
| `RADV_PERFTEST` | `aco,gpl` | Uses Valve's ACO compiler for instant startup |
| `GGML_VULKAN_MAX_NODES` | `8192` | MLC-style graph optimization for higher TPS |
| `GGML_VULKAN_F16` | `1` | FP16 math for maximum throughput |

### laptop-nvidia (Intel + NVIDIA — True CUDA mode)
Optimized for NVIDIA discrete GPUs using a custom CUDA-enabled container to bypass library conflicts on immutable Fedora-based distros.

| Parameter | Value | Reason |
|---|---|---|
| `Dockerfile` | Based on `ggml-org/llama.cpp:server-cuda` | Includes native CUDA kernels |
| `LEMONADE_BACKEND` | `system` | Forces use of the internal CUDA engine |
| `devices:` | `nvidia.com/gpu=all` | CDI passthrough for native driver access |
| `NVIDIA_VISIBLE_DEVICES` | `all` | Visibility for CUDA tools |

**Performance:** Achieves **~40 TPS** on GTX 1050 Ti using the custom build.

---

## Model
The configuration uses **Gemma 4 b2q4** (`unsloth/gemma-4-E2B-it-GGUF:Q4_0`) by default:
- **Type**: Reasoning-native multimodal model (Text + Vision).
- **Quantization**: Q4_0 (Optimal speed/accuracy balance).
- **VRAM**: Fits perfectly in 4GB devices (~3.2GB total usage including system overhead).

---

## BIOS Recommendations (AMD Server)
To get the most out of your Vega 11:
- **UMA Frame Buffer Size**: Set to AUTO or 4GB in BIOS.
- **Dual-channel RAM**: Mandatory (doubles iGPU bandwidth).
- **XMP/DOCP**: Enable to reduce memory latency.

---

## License
Apache 2.0
