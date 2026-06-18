# syntax=docker/dockerfile:1.7

# ===== Stage 1: Frontend =====
FROM node:24-alpine AS web-builder
WORKDIR /src/seanime-web
COPY seanime-web/package.json seanime-web/package-lock.json ./
RUN npm ci --no-audit --no-fund \
    || npm install --no-audit --no-fund
COPY seanime-web/ ./
RUN npm run build && mkdir -p /build && cp -r out /build/web

# ===== Stage 2: Backend =====
FROM golang:1.26.2-alpine AS go-builder
WORKDIR /src
RUN apk add --no-cache git
COPY go.mod go.sum ./
RUN go mod download
COPY . .
COPY --from=web-builder /build/web ./web
RUN CGO_ENABLED=0 go build \
    -trimpath \
    -ldflags="-s -w" \
    -o /out/seanime \
    .

# ===== Stage 3: Runtime =====
FROM alpine:3.23
RUN apk update && apk upgrade --no-cache \
    && apk add --no-cache \
        ca-certificates \
        ffmpeg \
        tini \
        tzdata \
        wget \
    && addgroup -g 1000 seanime \
    && adduser -D -u 1000 -G seanime -h /home/seanime seanime \
    && mkdir -p /data \
    && chown -R seanime:seanime /data

COPY --from=go-builder /out/seanime /usr/local/bin/seanime

ENV SEANIME_DATA_DIR=/data \
    SEANIME_SERVER_HOST=0.0.0.0 \
    SEANIME_SERVER_PORT=43211

USER seanime
WORKDIR /home/seanime
VOLUME ["/data"]
EXPOSE 43211

HEALTHCHECK --interval=30s --timeout=5s --start-period=20s --retries=3 \
    CMD wget --spider -q http://127.0.0.1:43211/ || exit 1

ENTRYPOINT ["/sbin/tini", "--"]
CMD ["/usr/local/bin/seanime"]
