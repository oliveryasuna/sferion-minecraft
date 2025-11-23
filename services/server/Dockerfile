# syntax=docker/dockerfile:1

#==================================================
# Builder stage
#==================================================

FROM eclipse-temurin:17-jdk AS builder

# Install necessary packages
RUN apt-get update && \
    apt-get install -y curl unzip && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /tmp/server-files

# Download and install the server files
ARG SERVER_FILE_SHA256="5551e78de29a2d869f5ea97eb6d8e8bd3b57b17cb920dba564292df5b836804a"
RUN curl -Lo "Server-Files-1.1.1.zip" "https://edge.forgecdn.net/files/7097/957/Server-Files-1.1.1.zip" && \
    echo "${SERVER_FILE_SHA256}  Server-Files-1.1.1.zip" | sha256sum -c - && \
    unzip -u -o "Server-Files-1.1.1.zip" -d /tmp/server-files && \
    if [ -d "Server-Files-1.1.1" ]; then mv Server-Files-1.1.1/* .; rmdir Server-Files-1.1.1; fi && \
    FORGE_INSTALLER=$(find . -maxdepth 1 -name "forge-*-installer.jar" -type f | head -n 1) && \
    java -jar "$FORGE_INSTALLER" --installServer && \
    rm -f Server-Files-1.1.1.zip

# Remove MrCrayfish's Furniture Mod (Legacy) because we're using the new one
RUN rm -rf mods/cfm-forge-1.20.1-7.0.0-pre36.jar


#==================================================
# Runtime stage
#==================================================

FROM eclipse-temurin:17-jre

# Install necessary packages
RUN apt-get update && \
    apt-get install -y vim netcat-openbsd && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Create user
RUN groupadd -g 1003 minecraft && \
    adduser --uid 1003 --gid 1003 --home /data --disabled-password minecraft

# Copy files from builder stage
COPY --from=builder --chown=minecraft:users /tmp/server-files /tmp/server-files

# Copy scripts
COPY --chmod=755 ./scripts/get-player-uuid.sh /tmp/scripts/get-player-uuid.sh
COPY --chmod=755 ./scripts/generate-whitelist.sh /tmp/scripts/generate-whitelist.sh
COPY --chmod=755 ./scripts/generate-ops.sh /tmp/scripts/generate-ops.sh
COPY --chmod=755 ./scripts/update-server-properties.sh /tmp/scripts/update-server-properties.sh
COPY --chmod=755 ./scripts/update-jvm-args.sh /tmp/scripts/update-jvm-args.sh

# Copy assets
COPY ./assets /tmp/assets

# Copy start script
COPY --chmod=755 start.sh /start.sh

# Set user
USER minecraft

# Set working directory
WORKDIR /data

# Environment variables
ENV MC_EULA=false
ENV MC_OPS=""
ENV MC_WHITELIST=""

# Expose server port
EXPOSE 25565/tcp

# Healthcheck to check if server is running and accepting connections
HEALTHCHECK --interval=30s --timeout=10s --start-period=500s --retries=3 \
    CMD nc -z localhost 25565 || exit 1

# Start server
CMD ["/start.sh"]
