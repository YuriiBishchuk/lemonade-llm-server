# Lemonade LLM Server 🍋

An extremely optimized Local LLM Server configuration based on [Lemonade SDK](https://github.com/lemonade-sdk/lemonade), tailored for both AMD Vega 11 APU and NVIDIA discrete GPUs on Linux (Fedora/Bazzite).

---

## 🌍 Language / Мова
- [English](#english-version)
- [Українська](#українська-версія)

---

<a name="english-version"></a>
# English Version

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
Each directory has its own independent volumes for models, caches, and shaders to prevent environment conflicts.

## Quick Start

### On Server (AMD Vega 11)
```bash
cd server-amd
chmod +x start.sh
./start.sh
```
API: **http://localhost:13305**

### On Laptop (NVIDIA + Bazzite/Fedora)
```bash
cd laptop-nvidia
chmod +x start.sh
./start.sh
```
API: **http://localhost:13306**

## Optimization Architecture

### server-amd (Vega 11 — Vulkan APU mode)
- **Unified Memory**: Enabled `GGML_VULKAN_UNIFIED_MEMORY=1`. Allows the iGPU to see all system RAM directly.
- **ACO/GPL Shaders**: Uses `RADV_PERFTEST=aco,gpl` (Valve's shader compiler used in Steam Deck) for instant startup after the first run.
- **MLC-style Tuning**: Graph optimization with `GGML_VULKAN_MAX_NODES=8192` and FP16 math for maximum TPS.

### laptop-nvidia (Intel + NVIDIA — True CUDA mode)
- **Custom CUDA Build**: Since Vulkan has library conflicts in rootless Podman on immutable distros, we build a custom image based on `ghcr.io/ggml-org/llama.cpp:server-cuda`.
- **Performance**: Achieves **~40 TPS** on GTX 1050 Ti.
- **CDI Passthrough**: Uses `nvidia.com/gpu=all` for native driver access without host library pollution.

## Model
Default model: **Gemma 4 b2q4** (unsloth/gemma-4-E2B-it-GGUF:Q4_0).
- Reasoning-native multimodal model.
- Optimized for 4GB VRAM devices.

---

<a name="українська-версія"></a>
# Українська версія

## Структура проекту
Кожна папка містить ізольоване середовище з власними `volumes`. Це дозволяє уникнути конфліктів кешу шейдерів та конфігурацій між AMD та NVIDIA.

## Оптимізації

### server-amd (Vega 11 — Vulkan APU)
- **Unified Memory**: Увімкнено прямий доступ iGPU до всієї оперативної пам'яті.
- **ACO/GPL**: Використання компілятора шейдерів від Valve для миттєвого запуску.
- **FP16 Math**: Максимальна пропускна здатність для інтегрованої графіки.

### laptop-nvidia (NVIDIA — True CUDA)
- **Спеціальний Dockerfile**: Збирає справжній CUDA-образ для подолання обмежень Vulkan на Fedora Bazzite.
- **Швидкість**: Близько **40 токенів на секунду** на ноутбуці.
- **NVIDIA CDI**: Пряме прокидання драйверів у контейнер.

## Модель
Використовується **Gemma 4 b2q4** — мультимодальна модель з вбудованим механізмом роздумів (Reasoning), квантована до Q4_0 для ідеального балансу швидкості та розуму.

## Рекомендації для BIOS (AMD)
- **UMA Frame Buffer**: AUTO або 4GB.
- **Dual-channel RAM**: Обов'язково для подвоєння швидкості iGPU.
- **XMP/DOCP**: Увімкніть для зниження затримок пам'яті.

---

## License
Apache 2.0
