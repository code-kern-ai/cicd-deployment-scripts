APP_REPOS=(
    admin-dashboard
    cognition-exec-env
    cognition-gateway
    cognition-pdf2md
    cognition-task-master
    cognition-ui
    refinery-authorizer
    refinery-embedder
    refinery-entry
    refinery-gateway
    refinery-gateway-proxy
    refinery-model-provider
    refinery-neural-search
    refinery-tokenizer
    refinery-ui
    refinery-updater
    refinery-weak-supervisor
    refinery-websocket
    refinery-ac-exec-env
    refinery-lf-exec-env
    refinery-ml-exec-env
)

for repo in ${APP_REPOS[@]}; do
    cd $repo
    git checkout -b ci-updates
    cp ../hosted-inference-api/.github/workflows/az_acr_delete.yml .github/workflows/az_acr_delete.yml
    git add .github
    git commit -m "ci(feat): add acr delete workflow"
    git push origin ci-updates
    gh pr create --head ci-updates --base dev --fill
    git checkout dev
    git branch -D ci-updates
    cd ..
done