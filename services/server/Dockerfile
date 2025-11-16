# syntax=docker/dockerfile:1

#==================================================
# Builder stage
#==================================================

FROM eclipse-temurin:17-jdk AS builder

RUN apt-get update && \
    apt-get install -y curl unzip && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /server-files

ARG SERVER_FILE_SHA256="5551e78de29a2d869f5ea97eb6d8e8bd3b57b17cb920dba564292df5b836804a"
RUN curl -Lo "Server-Files-1.1.1.zip" "https://edge.forgecdn.net/files/7097/957/Server-Files-1.1.1.zip" && \
    echo "${SERVER_FILE_SHA256}  Server-Files-1.1.1.zip" | sha256sum -c - && \
    unzip -u -o "Server-Files-1.1.1.zip" -d /server-files && \
    if [ -d "Server-Files-1.1.1" ]; then mv Server-Files-1.1.1/* .; rmdir Server-Files-1.1.1; fi && \
    FORGE_INSTALLER=$(find . -maxdepth 1 -name "forge-*-installer.jar" -type f | head -n 1) && \
    java -jar "$FORGE_INSTALLER" --installServer && \
    rm -rf mods/cfm-forge-1.20.1-7.0.0-pre36.jar && \
    rm -f Server-Files-1.1.1.zip


#==================================================
# Runtime stage
#==================================================

FROM eclipse-temurin:17-jre

RUN apt-get update && \
    apt-get install -y vim && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

RUN adduser --uid 99 --gid 100 --home /data --disabled-password minecraft

# Copy prepared server files from builder
COPY --from=builder --chown=minecraft:users /server-files /server-files

COPY assets /assets

COPY start.sh /start.sh
RUN chmod +x /start.sh

USER minecraft

WORKDIR /data

EXPOSE 25565/tcp

ARG EULA=false
ARG MEMORY_MIN=8G
ARG MEMORY_MAX=16G
ARG EXIT_ON_OOM=true
ARG LEVEL_SEED
ARG MOTD="Who's the best boss?"
ARG DIFFICULTY="normal"
ARG MAX_PLAYERS=10
ARG VIEW_DISTANCE=20

ENV EULA=${EULA}
ENV MEMORY_MIN=${MEMORY_MIN}
ENV MEMORY_MAX=${MEMORY_MAX}
ENV EXIT_ON_OOM=${EXIT_ON_OOM}
ENV LEVEL_SEED=${LEVEL_SEED}
ENV MOTD=${MOTD}
ENV DIFFICULTY=${DIFFICULTY}
ENV MAX_PLAYERS=${MAX_PLAYERS}
ENV VIEW_DISTANCE=${VIEW_DISTANCE}

HEALTHCHECK --interval=30s --timeout=10s --start-period=120s --retries=3 \
    CMD pgrep -f "nogui" > /dev/null || exit 1

CMD ["/start.sh"]
