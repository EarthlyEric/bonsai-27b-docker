# syntax=docker/dockerfile:1.7

ARG CUDA_VERSION=12.8.1
ARG UBUNTU_VERSION=24.04

FROM nvidia/cuda:${CUDA_VERSION}-devel-ubuntu${UBUNTU_VERSION} AS builder

ARG LLAMA_REPO=https://github.com/PrismML-Eng/llama.cpp.git
ARG LLAMA_REF=master
ARG CUDA_ARCHITECTURES=89

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
      build-essential ca-certificates ccache cmake git libcurl4-openssl-dev ninja-build \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /src
RUN git clone --filter=blob:none --branch "${LLAMA_REF}" --depth 1 "${LLAMA_REPO}" llama.cpp

WORKDIR /src/llama.cpp
RUN --mount=type=cache,target=/root/.cache/ccache \
    cmake -S . -B build -G Ninja \
      -DCMAKE_BUILD_TYPE=Release \
      -DCMAKE_CUDA_ARCHITECTURES="${CUDA_ARCHITECTURES}" \
      -DGGML_CCACHE=ON \
      -DGGML_CUDA=ON \
      -DGGML_CUDA_FA_ALL_QUANTS=ON \
      -DGGML_NATIVE=OFF \
      -DLLAMA_CURL=ON \
    && cmake --build build --config Release --target llama-server -j "$(nproc)"

FROM nvidia/cuda:${CUDA_VERSION}-runtime-ubuntu${UBUNTU_VERSION} AS runtime

ENV DEBIAN_FRONTEND=noninteractive \
    CUDA_VISIBLE_DEVICES=0 \
    MODEL=/models/bonsai.gguf

RUN apt-get update && apt-get install -y --no-install-recommends ca-certificates curl libcurl4 \
    && rm -rf /var/lib/apt/lists/* \
    && useradd --create-home --uid 10001 app

COPY --from=builder /src/llama.cpp/build/bin/llama-server /usr/local/bin/llama-server
COPY docker/entrypoint.sh /usr/local/bin/entrypoint.sh

RUN chmod 0755 /usr/local/bin/entrypoint.sh && mkdir -p /models && chown app:app /models

USER app
WORKDIR /home/app
VOLUME ["/models"]
EXPOSE 8080

HEALTHCHECK --interval=30s --timeout=5s --start-period=120s --retries=3 \
  CMD curl --fail --silent http://127.0.0.1:8080/health >/dev/null || exit 1

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]

