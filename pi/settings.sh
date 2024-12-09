#!/bin/bash

export torch_cpu=(
    "refinery-embedder"
    "refinery-ml-exec-env"
)

export torch_cuda=(
    "refinery-embedder"
)

export common=(
    "refinery-gateway"
    "refinery-neural-search"
    "refinery-tokenizer"
    "refinery-updater"
    "refinery-weak-supervisor"
    "refinery-model-provider"
    "cognition-gateway"
    "${torch_cpu[@]}"
    "${torch_cuda[@]}"
)

export mini=(
    "refinery-authorizer"
    "refinery-gateway-proxy"
    "${common[@]}"
)

export exec_env=(
    "refinery-ac-exec-env"
    "refinery-lf-exec-env"
    "cognition-exec-env"
)

export next=(
    "admin-dashboard"
    "cognition-ui"
    "refinery-ui"
)

export ALL_SERVICES=( "${mini[@]}" "${exec_env[@]}" "${next[@]}" )