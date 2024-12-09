#!/bin/bash

export mini=(
    "refinery-authorizer"
    "refinery-gateway-proxy"
)

export common=(
    "refinery-gateway"
    "refinery-neural-search"
    "refinery-tokenizer"
    "refinery-updater"
    "refinery-weak-supervisor"
    "refinery-model-provider"
    "cognition-gateway"
    "${mini[@]}"
)

export exec_env=(
    "refinery-ac-exec-env"
    "refinery-lf-exec-env"
    "cognition-exec-env"
)

export torch_cpu=(
    "refinery-embedder"
    "refinery-ml-exec-env"
    "${common[@]}"
)

export torch_cuda=(
    "refinery-embedder"
    "${common[@]}"
)

export next=(
    "admin-dashboard"
    "cognition-ui"
    "refinery-ui"
)

export ALL_SERVICES=( "${mini[@]}" "${common[@]}" "${exec_env[@]}" "${torch_cpu[@]}" "${torch_cuda[@]}" )