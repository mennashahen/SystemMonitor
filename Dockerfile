FROM ubuntu:latest

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
    bash \
    coreutils \
    sysstat \
    lm-sensors \
    bc \
    net-tools \
    iproute2 \
    python3 \
    dos2unix \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY scripts/ /app/scripts/

RUN find /app/scripts -name "*.sh" -exec dos2unix {} \; && \
    chmod +x /app/scripts/*.sh

CMD ["/bin/bash", "/app/scripts/start.sh"]