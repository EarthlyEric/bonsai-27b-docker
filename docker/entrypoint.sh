#!/bin/sh
set -eu

if [ "$#" -gt 0 ]; then
  exec llama-server "$@"
fi

set -- \
  --model "${MODEL:-/models/bonsai.gguf}" \
  --host "${HOST:-0.0.0.0}" \
  --port "${PORT:-8080}" \
  --n-gpu-layers "${N_GPU_LAYERS:-999}" \
  --ctx-size "${CTX_SIZE:-131072}" \
  --parallel "${PARALLEL:-1}" \
  --flash-attn "${FLASH_ATTN:-on}" \
  --cache-type-k "${CACHE_TYPE_K:-q4_0}" \
  --cache-type-v "${CACHE_TYPE_V:-q4_0}"

exec llama-server "$@" ${LLAMA_EXTRA_ARGS:-}

