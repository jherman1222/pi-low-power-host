# Lightweight VE.Direct → MQTT bridge based on birdie1/victron + karioja/vedirect.
# Build: docker compose --profile victron build
FROM python:3.12-slim-bookworm

RUN apt-get update && apt-get install -y --no-install-recommends \
    git \
    python3-dbus \
    gcc \
    libdbus-1-dev \
    libglib2.0-dev \
  && rm -rf /var/lib/apt/lists/*

WORKDIR /opt/victron

RUN git clone --depth 1 https://github.com/birdie1/victron.git . \
  && pip install --no-cache-dir -r requirements.txt \
  && pip install --no-cache-dir git+https://github.com/karioja/vedirect.git

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

VOLUME ["/config"]
ENTRYPOINT ["/entrypoint.sh"]
