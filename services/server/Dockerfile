# syntax=docker/dockerfile:1

FROM eclipse-temurin:17-jdk

RUN apt-get update && \
    apt-get install -y curl unzip vim && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

RUN adduser --uid 99 --gid 100 --home /data --disabled-password minecraft

COPY assets /assets

COPY start.sh /start.sh
RUN chmod +x /start.sh

USER minecraft

# VOLUME /data
WORKDIR /data

EXPOSE 25565/tcp

ARG EULA=false
ARG MEMORY_MIN=8G
ARG MEMORY_MAX=16G
ARG LEVEL_SEED=31563250179158
ARG MOTD="Who's the best boss?"
ARG DIFFICULTY="normal"
ARG MAX_PLAYERS=10
ARG VIEW_DISTANCE=32
ARG ENABLE_RCON=false
ARG RCON_PASSWORD

ENV EULA=${EULA}
ENV MEMORY_MIN=${MEMORY_MIN}
ENV MEMORY_MAX=${MEMORY_MAX}
ENV LEVEL_SEED=${LEVEL_SEED}
ENV MOTD=${MOTD}
ENV DIFFICULTY=${DIFFICULTY}
ENV MAX_PLAYERS=${MAX_PLAYERS}
ENV VIEW_DISTANCE=${VIEW_DISTANCE}
ENV ENABLE_RCON=${ENABLE_RCON}
ENV RCON_PASSWORD=${RCON_PASSWORD}

HEALTHCHECK --interval=30s --timeout=10s --start-period=120s --retries=3 \
    CMD pgrep -f "nogui" > /dev/null || exit 1

CMD ["/start.sh"]
