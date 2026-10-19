# syntax=docker/dockerfile:1
FROM node:22-bookworm-slim

RUN apt-get update && apt-get install -y --no-install-recommends \
    libvips42 \
  && rm -rf /var/lib/apt/lists/*

WORKDIR /app
COPY package.json package-lock.json* ./
RUN npm ci --omit=dev || npm install --omit=dev
COPY . .
CMD ["node", "index.js"]
