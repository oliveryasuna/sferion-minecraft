# syntax=docker/dockerfile:1

FROM eclipse-temurin:17-jdk

RUN apt-get update && \
    apt-get install -y curl unzip && \
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

CMD ["/start.sh"]
