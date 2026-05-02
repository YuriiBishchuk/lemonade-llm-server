# Use the official OpenClaw image as base
FROM ghcr.io/openclaw/openclaw:latest

USER root

# Install All Development Tools
RUN apt-get update && apt-get install -y \
    build-essential \
    cmake \
    git \
    curl \
    wget \
    jq \
    unzip \
    python3 \
    python3-pip \
    python3-venv \
    ffmpeg \
    imagemagick \
    # Node.js 20.x
    && curl -fsSL https://deb.nodesource.com/setup_20.x | bash - \
    && apt-get install -y nodejs \
    # .NET SDK 10.0 (The latest for 2026 projects)
    && wget https://packages.microsoft.com/config/debian/12/packages-microsoft-prod.deb -O packages-microsoft-prod.deb \
    && dpkg -i packages-microsoft-prod.deb \
    && rm packages-microsoft-prod.deb \
    && apt-get update \
    && apt-get install -y dotnet-sdk-10.0 \
    # Cleanup
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Set environment variables for the tools
ENV DOTNET_CLI_TELEMETRY_OPTOUT=1

# We do NOT change WORKDIR or CMD to preserve the base image's entrypoint
