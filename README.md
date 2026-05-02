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

### server-amd (Vega 11 — ROCm GPU Offloading)
Optimized for **GPU offloading** to keep CPU cores free for other services. This uses a custom ROCm build and architectural overrides to enable compute on the "unsupported" Vega 11 APU.

| Parameter | Value | Reason |
|---|---|---|
| `Dockerfile` | Custom multi-stage | Combines ROCm drivers with Lemonade binaries |
| `HSA_OVERRIDE_GFX_VERSION` | `9.0.0` | Emulates gfx900 to bypass driver restrictions |
| `LEMONADE_BACKEND` | `system` | Forces use of the ROCm-enabled llama-server |

#### Benchmark Results (Llama 3.2 1B)
| Configuration | Prompt TPS | Gen TPS | Verdict |
|---|---|---|---|
| **ROCm (Hacked)** | **38.10** | 33.78 | **Fastest Prompt (Low Latency)** |
| CPU (4 Threads) | 33.28 | 35.06 | Balanced |

**Conclusion:** We chose ROCm to maximize GPU utilization and offload the CPU, providing the fastest initial response time (Prompt TPS) for the development environment.


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
The configuration uses **Gemma 2 2.6B** (`unsloth/gemma-2-2b-it-GGUF:Q4_K_M`) by default:
- **Type**: Reasoning-native multimodal model.
- **Quantization**: **Q4_K_M** (Proven to be ~12% faster than Q4_0 on this hardware).
- **VRAM**: Fits perfectly in 4GB devices (~2.8GB total usage).

---

## BIOS Recommendations (AMD Server)
To get the most out of your Vega 11:
- **UMA Frame Buffer Size**: Set to AUTO or 4GB in BIOS.
- **Dual-channel RAM**: Mandatory (doubles iGPU bandwidth).
- **XMP/DOCP**: Enable to reduce memory latency.

---

## License
Apache 2.0
