#!/bin/bash

export torch_cpu=(
    "refinery-embedder"
    "refinery-ml-exec-env"
)

export torch_cpu_dockerfile=(
    "refinery-embedder"
    "refinery-ml-exec-env"
)

export torch_cuda=(
    "refinery-embedder"
)
export torch_cuda_dockerfile=(
    "refinery-embedder"
)

export common_dockerfile=(
    "refinery-gateway"
    "refinery-neural-search"
    "refinery-tokenizer"
    "refinery-updater"
    "refinery-weak-supervisor"
    "refinery-model-provider"
    "cognition-gateway"
    "cognition-integration-provider"
)

export common=(
    "${common_dockerfile[@]}"
    "${torch_cpu[@]}"
    "${torch_cuda[@]}"
)

export mini_dockerfile=(
    "refinery-authorizer"
)

export mini=(
    "${mini_dockerfile[@]}"
    "${common[@]}"
)

export exec_env=(
    "refinery-ac-exec-env"
    "refinery-lf-exec-env"
    "cognition-exec-env"
)

export exec_env_dockerfile=(
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