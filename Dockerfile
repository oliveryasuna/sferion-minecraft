# Base image
ARG BASE_IMAGE=eclipse-temurin:21-jre
FROM ${BASE_IMAGE}

# Set working directory
WORKDIR /minecraft

# Install necessary utilities
RUN apt-get update && \
    apt-get install -y curl wget && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

ENV MEMORY_MIN=2G
ENV MEMORY_MAX=16G
ENV MC_VERSION=1.21.1
ENV NEOFORGE_VERSION=21.1.214
ENV EULA=FALSE

# Download NeoForge installer
RUN wget -O neoforge-installer.jar \
    "https://maven.neoforged.net/releases/net/neoforged/neoforge/${NEOFORGE_VERSION}/neoforge-${NEOFORGE_VERSION}-installer.jar"

# Run the installer to set up the server
RUN java -jar neoforge-installer.jar --installServer && \
    rm neoforge-installer.jar

# Create necessary directories
RUN mkdir -p /minecraft/mods /minecraft/config /minecraft/world

# Copy startup script
COPY start.sh /minecraft/start.sh
RUN chmod +x /minecraft/start.sh

# Expose Minecraft port
EXPOSE 25565

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=120s --retries=3 \
    CMD pgrep -f "nogui" > /dev/null || exit 1

# Use the startup script
CMD ["/minecraft/start.sh"]
