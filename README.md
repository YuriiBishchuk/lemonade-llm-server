# Lemonade LLM Server 🍋

An extremely optimized, unified Local LLM Server & Agent deployment based on [Lemonade SDK](https://github.com/lemonade-sdk/lemonade), tailored for AMD Vega 11 APUs and general Linux environments.

---

## 🚀 The "One-Script" Deployment

The project is now unified into a single management system. You no longer need to manually manage multiple directories or configurations.

### 1. Bootstrap
Just copy the `manage.sh` script to your server and run it:
```bash
wget https://raw.githubusercontent.com/YuriiBishchuk/lemonade-llm-server/main/server/manage.sh
chmod +x manage.sh
./manage.sh
```

### 2. What happens automatically:
- **Interactive Setup**: On the first run, it will ask for your **Telegram Bot Token** and **Chat ID**.
- **Auto-Updates**: Every time you run `./manage.sh`, it checks GitHub for the latest version and updates your local files without requiring `git`.
- **Docker Orchestration**: It manages two optimized stacks:
    - **Model Stack**: Lemonade server (Vulkan/APU optimized).
    - **Agent Stack**: OpenClaw (Autonomous agent), Qdrant (Memory), and SearXNG (Search).

---

## 🚚 Migration (Move to new path)

If you need to move the entire project to a different directory or disk:
1. Download and run the migration script:
   ```bash
   wget https://raw.githubusercontent.com/YuriiBishchuk/lemonade-llm-server/main/server/migrate.sh
   chmod +x migrate.sh
   ./migrate.sh
   ```
2. Enter the new absolute path when prompted.
3. The script will stop all services, copy everything to the new location, and restart the system there.

---

## 📂 Project Structure
```
lemonade/
├── server/               # Unified deployment directory
│   ├── manage.sh         # The "One-Script" entry point
│   ├── docker-compose.model.yml
│   ├── docker-compose.openclaw.yml
│   └── openclaw/         # Agent source & configurations
│       ├── Dockerfile    # Advanced tool-set build
│       └── searxng/      # Search engine config
└── README.md
```

---

## 🧠 Optimization Architecture (Vega 11)

After exhaustive testing, we use **Vulkan Baseline** with RADV/ACO tuning. This provides the highest raw throughput (**44 TPS Prompt / 35 TPS Gen**) while maintaining stability.

| Parameter | Value | Reason |
|---|---|---|
| `LEMONADE_BACKEND` | `vulkan` | Native high-performance backend |
| `GGML_VULKAN_UNIFIED_MEMORY` | `1` | **APU Optimization:** Shared RAM access without copy overhead |
| `RADV_PERFTEST` | `aco,gpl` | Uses Valve's ACO compiler for fastest execution |
| `OMP_NUM_THREADS` | `4` | Physical core pinning (avoids SMT overhead) |

### Key Benchmark Results (TinyLlama 1.1B)
| Variant | Prompt (TPS) | Gen (TPS) |
|---|---|---|
| **Vulkan Baseline** | **44.08** | **35.21** |
| ROCm Hack | 38.10 | 33.78 |
| CPU Only | 41.79 | 34.17 |

---

## 🛠️ Configuration & Secrets

All configuration is managed via a `.env` file created by the script.

- **Telegram**: Enable notifications by providing your token from [@BotFather](https://t.me/BotFather).
- **Restart Policy**: All containers are set to `restart: always` to ensure they survive reboots.
- **Port Mapping**:
    - **OpenClaw Web UI**: `http://localhost:3000`
    - **Lemonade API**: `http://localhost:13305`
    - **SearXNG**: `http://localhost:8081`

---

## 📋 Prerequisites
- **Docker** & **Docker Compose**
- **curl** & **unzip**
- **AMD Drivers** (for APU acceleration)

---

## 📜 License
Apache 2.0
