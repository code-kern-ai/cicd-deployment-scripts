#!/bin/bash

export PARENT_IMAGE_TYPES=(
    mini
    common
    exec_env
    torch_cpu
    torch_cuda
    next
)

export mini=(
    "refinery-authorizer"
    # "refinery-config"
    # "refinery-doc-ock"
    "refinery-gateway-proxy"
    # "platform-monitoring"
)

export common=(
    "refinery-gateway"
    "refinery-neural-search"
    "refinery-tokenizer"
    "refinery-updater"
    "refinery-weak-supervisor"
    "refinery-model-provider"
    # "refinery-commercial-proxy"
    # "gates-gateway"
    # "chat-gateway"
    "cognition-gateway"
)

export exec_env=(
    "refinery-ac-exec-env"
    "refinery-lf-exec-env"
    # "refinery-record-ide-env"
    # "gates-runtime"
    # "chat-exec-env"
    "cognition-exec-env"
)

export torch_cpu=(
    "refinery-embedder"
    "refinery-ml-exec-env"
    # "refinery-zero-shot"
    # "hosted-inference-api"
)

export torch_gpu=(
    "refinery-embedder"
    # "refinery-zero-shot"
)

export next=(
    # "gates-ui"
    "admin-dashboard"
    # "chat-ui"
    "cognition-ui"
    "refinery-ui"
)

export ALL_SERVICES=( "${mini[@]}" "${common[@]}" "${exec_env[@]}" "${torch_cpu[@]}" "${torch_gpu[@]}" )