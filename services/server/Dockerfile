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

VOLUME /data
WORKDIR /data

EXPOSE 25565/tcp

ARG EULA=false
ARG MEMORY_MIN=8G
ARG MEMORY_MAX=16G

ENV EULA=${EULA}
ENV MEMORY_MIN=${MEMORY_MIN}
ENV MEMORY_MAX=${MEMORY_MAX}

HEALTHCHECK --interval=30s --timeout=10s --start-period=120s --retries=3 \
    CMD pgrep -f "nogui" > /dev/null || exit 1

CMD ["/start.sh"]
