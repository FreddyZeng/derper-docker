FROM golang:latest AS builder

WORKDIR /app

# 参数化源码仓库和分支
ARG DERP_REPO=https://github.com/FreddyZeng/tailscale-1.82.5.git
ARG DERP_BRANCH=main

# 克隆指定版本源码
RUN git clone --branch ${DERP_BRANCH} ${DERP_REPO} tailscale-src

# 切换到 derper 源码目录
WORKDIR /app/tailscale-src/cmd/derper

# Release 构建 derper，去除调试信息
RUN go build -trimpath -ldflags="-s -w" -o /usr/local/bin/derper

# 验证是否可执行（可选）
RUN /usr/local/bin/derper --help



FROM ubuntu
WORKDIR /app

ARG DEBIAN_FRONTEND=noninteractive

RUN apt-get update && \
    apt-get install -y --no-install-recommends apt-utils && \
    apt-get install -y ca-certificates && \
    mkdir /app/certs

ENV DERP_DOMAIN your-hostname.com
ENV DERP_CERT_MODE letsencrypt
ENV DERP_CERT_DIR /app/certs
ENV DERP_ADDR :443
ENV DERP_STUN true
ENV DERP_STUN_PORT 3478
ENV DERP_HTTP_PORT 80
ENV DERP_VERIFY_CLIENTS false
ENV DERP_VERIFY_CLIENT_URL ""

COPY --from=builder /usr/local/bin/derper .

CMD /app/derper --hostname=$DERP_DOMAIN \
    --certmode=$DERP_CERT_MODE \
    --certdir=$DERP_CERT_DIR \
    --a=$DERP_ADDR \
    --stun=$DERP_STUN  \
    --stun-port=$DERP_STUN_PORT \
    --http-port=$DERP_HTTP_PORT \
    --verify-clients=$DERP_VERIFY_CLIENTS \
    --verify-client-url=$DERP_VERIFY_CLIENT_URL

