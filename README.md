# Bonsai 27B CUDA container

CUDA-optimized `llama-server` image for PrismML Bonsai / Bonsai 2 on an RTX 4070 Ti SUPER. The image downloads and verifies PrismML's pre-built CUDA 12.8 release; it does not compile llama.cpp during Actions. The model is not embedded in the image; mount a GGUF file at runtime.

## Published image

Every push to `main` publishes `ghcr.io/<owner>/<repo>:latest`. Version tags such as `v1.0.0` also publish matching semantic-version tags. Pull requests build without pushing.

## Run

Place your GGUF at `models/bonsai.gguf`, then run:

```bash
GITHUB_OWNER=<owner> docker compose up -d
curl http://localhost:8080/health
```

The default is tuned for one RTX 4070 Ti SUPER: CUDA architecture 8.9, full GPU offload, 128K context, Flash Attention, and Q4 KV cache. Override settings through Compose environment variables:

```yaml
environment:
  CTX_SIZE: "262144"
  CACHE_TYPE_K: q4_0
  CACHE_TYPE_V: q4_0
  LLAMA_EXTRA_ARGS: "--temp 0.7 --top-p 0.95 --top-k 20"
```

For maximum speed with shorter prompts, start with 64K context. A 262K context is workload-dependent and should be tested against available VRAM.

## Build locally

```bash
docker build -t bonsai-27b:cuda .
```

The default binary is pinned to `prism-b10709-9a9394a` and verified with SHA-256. Override the release only when you also provide the matching checksum:

```bash
docker build \
  --build-arg LLAMA_RELEASE=<release-tag> \
  --build-arg LLAMA_CUDA_VERSION=12.8 \
  --build-arg LLAMA_SHA256=<sha256> \
  -t bonsai-27b:cuda .
```

## API

The OpenAI-compatible endpoint is available at:

```text
http://localhost:8080/v1/chat/completions
```

## Notes

- Requires the NVIDIA driver and NVIDIA Container Toolkit on the host.
- Bonsai 2 currently requires PrismML's llama.cpp fork; the Dockerfile uses its pre-built CUDA 12.8 binary by default.
- The Actions runner only compiles the CUDA image. A GPU is required when running it, not while building it.
