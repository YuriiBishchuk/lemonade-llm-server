FROM ghcr.io/ggml-org/llama.cpp:server-rocm

# Install dependencies for Lemonade
RUN apt-get update && apt-get install -y curl jq wget && rm -rf /var/lib/apt/lists/*

# Copy lemonade binaries from the official image
COPY --from=ghcr.io/lemonade-sdk/lemonade-server:latest /opt/lemonade /opt/lemonade

# Make llama-server available in PATH for the 'system' backend
RUN cp -r /app/* /usr/local/bin/ || true
RUN cp -r /app/libggml* /usr/lib/x86_64-linux-gnu/ || true

# ROCm hack for unsupported Vega 11 (gfx902 -> emulate gfx900)
ENV HSA_OVERRIDE_GFX_VERSION=9.0.0
ENV HSA_ENABLE_SDMA=0
ENV LEMONADE_BACKEND=system

ENTRYPOINT ["/opt/lemonade/lemond", "--host", "0.0.0.0"]
