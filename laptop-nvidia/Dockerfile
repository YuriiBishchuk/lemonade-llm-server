FROM ghcr.io/ggml-org/llama.cpp:server-cuda

# Install dependencies for Lemonade
RUN apt-get update && apt-get install -y curl jq wget && rm -rf /var/lib/apt/lists/*

# Copy lemonade binaries and resources from the official image
COPY --from=ghcr.io/lemonade-sdk/lemonade-server:latest /opt/lemonade /opt/lemonade

# Make llama-server available in PATH for the 'system' backend
RUN cp -r /app/* /usr/local/bin/ || true
RUN cp -r /app/libggml* /usr/lib/x86_64-linux-gnu/ || true

ENV LEMONADE_BACKEND=system

# Required for NVIDIA CUDA passthrough in rootless podman
ENV NVIDIA_VISIBLE_DEVICES=all
ENV NVIDIA_DRIVER_CAPABILITIES=compute,utility

ENTRYPOINT ["/opt/lemonade/lemond", "--host", "0.0.0.0"]
