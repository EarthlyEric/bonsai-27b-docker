# syntax=docker/dockerfile:1.7

ARG CUDA_VERSION=12.8.1
ARG UBUNTU_VERSION=24.04

FROM nvidia/cuda:${CUDA_VERSION}-runtime-ubuntu${UBUNTU_VERSION}

ARG LLAMA_RELEASE=prism-b10709-9a9394a
ARG LLAMA_CUDA_VERSION=12.8
ARG LLAMA_SHA256=8aec67eb023b251712c7e6490f367b5671bf587eced1436a9b85f4a90c3b7d3d

ENV DEBIAN_FRONTEND=noninteractive \
    CUDA_VISIBLE_DEVICES=0 \
    MODEL=/models/bonsai.gguf \
    PATH=/opt/llama/bin:/opt/llama:${PATH} \
    LD_LIBRARY_PATH=/opt/llama:/opt/llama/lib:/usr/local/cuda/lib64:/usr/local/cuda/targets/x86_64-linux/lib:${LD_LIBRARY_PATH}

RUN apt-get update && apt-get install -y --no-install-recommends \
      ca-certificates curl libcurl4 tar \
    && rm -rf /var/lib/apt/lists/* \
    && mkdir -p /opt/llama \
    && asset="llama-${LLAMA_RELEASE}-bin-linux-cuda-${LLAMA_CUDA_VERSION}-x64.tar.gz" \
    && curl --fail --location --retry 3 --retry-delay 2 \
         "https://github.com/PrismML-Eng/llama.cpp/releases/download/${LLAMA_RELEASE}/${asset}" \
         --output /tmp/llama.tar.gz \
    && echo "${LLAMA_SHA256}  /tmp/llama.tar.gz" | sha256sum --check --strict \
    && tar --extract --gzip --file /tmp/llama.tar.gz --directory /opt/llama --strip-components=1 \
    && test -x /opt/llama/llama-server \
    && rm -f /tmp/llama.tar.gz

RUN useradd --create-home --uid 10001 app \
    && mkdir -p /models \
    && chown app:app /models

COPY docker/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod 0755 /usr/local/bin/entrypoint.sh

USER app
WORKDIR /home/app
VOLUME ["/models"]
EXPOSE 8080

HEALTHCHECK --interval=30s --timeout=5s --start-period=60s --retries=3 \
  CMD curl --fail --silent http://127.0.0.1:8080/health >/dev/null || exit 1

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]

