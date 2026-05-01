# Lemonade LLM Server

Локальний LLM-сервер на базі [Lemonade SDK](https://github.com/lemonade-sdk/lemonade), налаштований під два різних пристрої з екстремальною оптимізацією для кожного.

## Структура проекту

```
lemonade/
├── server-amd/          # Конфігурація для домашнього сервера (AMD Ryzen + Vega 11)
│   ├── docker-compose.yml
│   └── start.sh
│
├── laptop-nvidia/       # Конфігурація для ноутбука (Intel i7 + NVIDIA, Bazzite)
│   ├── docker-compose.yml
│   └── start.sh
│
└── README.md
```

Кожна папка має власні незалежні `volumes` — моделі, кеш та шейдери зберігаються окремо для кожної машини.

---

## Запуск

### На сервері (AMD Vega 11)
```bash
cd server-amd
./start.sh
```
API буде доступний на: **http://localhost:13305**

### На ноутбуці (NVIDIA, з Toolbx)
```bash
cd laptop-nvidia
./start.sh
```
API буде доступний на: **http://localhost:13306**

---

## Налаштування Podman на ноутбуці (Bazzite + Toolbx)

Оскільки ноутбук використовує Bazzite (immutable Fedora), `lemonade` запускається через **Podman хост-системи** з середини Toolbx.

### 1. На хості (один раз)
```bash
systemctl --user enable --now podman.socket
```

### 2. В Toolbx (один раз — вже налаштовано)
```bash
echo 'export CONTAINER_HOST=unix:///run/user/1000/podman/podman.sock' >> ~/.bashrc
source ~/.bashrc
```

Після цього `podman` та `podman-compose` всередині Toolbx автоматично використовують демон хост-системи.

---

## Архітектура оптимізацій

### server-amd (Vega 11 — Vulkan APU mode)

| Параметр | Значення | Причина |
|---|---|---|
| `LEMONADE_BACKEND` | `vulkan` | Єдиний нативний бекенд для AMD на Linux |
| `GGML_VULKAN_UNIFIED_MEMORY` | `1` | «Святий Грааль» APU: GPU бачить всю RAM напряму |
| `GGML_VULKAN_PINNED_MEMORY` | `1` | Забороняє swap для тензорів моделі |
| `RADV_PERFTEST=aco,gpl` | — | ACO — компілятор шейдерів від Valve (Steam Deck). GPL pre-link шейдери на першому запуску → наступні запуски миттєві |
| `RADV_DEBUG=nocache_reuse` | — | Прибирає перевірку кешу при старті після першого запуску |
| `GGML_VULKAN_MAX_NODES` | `8192` | MLC-style: GPU виконує більше операцій за один round-trip |
| `GGML_VULKAN_F16` | `1` | FP16 математика — найбільший одиничний приріст TPS |
| `GGML_VULKAN_CHECK_RESULTS` | `0` | Вимикає перевірку кожного dispatch (безпечно для inference) |
| `GGML_VULKAN_WMMAMATRIX` | `0` | Vega 11 не має матричних ядер → примусово використовуємо оптимізовані compute шейдери |
| `memlock: -1` | — | Необмежене блокування пам'яті |
| `stack: -1` | — | Необмежений стек для потоків компілятора шейдерів |

**Volumes (AMD):**
- `./lemonade-cache` → конфіг сервера
- `./huggingface-cache` → завантажені моделі (HuggingFace)
- `./llama-data` → дані Llama.cpp
- `./shader-cache` → скомпільовані Vulkan pipeline (Mesa)
- `./shader-cache-radv` → AMD RADV built-in шейдери

> **Перший запуск**: GPL компілює шейдери (~30-60 сек). Кожен наступний запуск — миттєвий.

**Очікувана швидкість на Vega 11:** ~10-15 TPS (Gemma-4-E2B)

---

### laptop-nvidia (Intel i7-8750H + NVIDIA — True CUDA mode)

**Швидкість:** ~40 TPS (неймовірний приріст завдяки CUDA)
**TTFT:** ~0.39 сек

Оскільки Vulkan має проблеми з прокиданням бібліотек в rootless Podman на Bazzite/Fedora, я написав спеціальний `Dockerfile`, який збирає справжній CUDA-образ для `lemonade`.

| Параметр | Значення | Причина |
|---|---|---|
| `Dockerfile` | Базується на `ghcr.io/ggml-org/llama.cpp:server-cuda` | Містить нативно скомпільований CUDA драйвер для llama.cpp |
| `LEMONADE_BACKEND` | `system` | Змушує сервер використовувати вбудований CUDA-бінарник |
| `devices:` | `nvidia.com/gpu=all` | Прокидання ядра відеокарти (CDI) |
| `NVIDIA_VISIBLE_DEVICES` | `all` | Видимість для CUDA |
| `NVIDIA_DRIVER_CAPABILITIES` | `compute,utility` | Дозволяє виконувати обчислення на GPU |

**Як це працює:**
При запуску `./start.sh` Docker автоматично скомпілює образ `laptop-nvidia_lemonade-nvidia` (займе ~1-2 хвилини лише на перший раз), який об'єднує веб-інтерфейс Lemonade зі справжньою міццю NVIDIA CUDA.

---

## Модель

За замовчуванням використовується **Gemma-4-E2B-it-GGUF** (Q4_0 квантизація, найоптимальніша для швидкості):
- Репозиторій: `unsloth/gemma-4-E2B-it-GGUF:Q4_0`
- Версія: Instruction Tuned (`-it`)
- Параметри: 4.6B (ефективних: ~2B через MoE)
- Ліцензія: Apache 2.0

Завантаження відбувається автоматично при першому запуску `start.sh`. Використовується оновлений, швидший бінарник сервера `lemond`.

---

## BIOS рекомендації (для сервера з Vega 11)

- **UMA Frame Buffer Size**: AUTO або 4GB — Vulkan виділить більше динамічно
- **DOCP/XMP**: Увімкніть — швидкість RAM напряму впливає на TPS для APU
- **Dual-channel RAM**: Обов'язково — подвоює пропускну здатність Vega 11
- **RAM Latency**: CL14/CL16 краще, ніж висока частота з CL18+

---

## API

Сервер сумісний з OpenAI API:

```bash
curl http://localhost:13305/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "Gemma-4-E2B-it-GGUF",
    "messages": [{"role": "user", "content": "Привіт!"}]
  }'
```
