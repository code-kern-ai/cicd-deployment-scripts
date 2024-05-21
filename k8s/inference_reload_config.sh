# !/bin/bash
set -e

KUBERNETES_NAMESPACE=""

while getopts n: flag
do
    case "${flag}" in
        n) KUBERNETES_NAMESPACE=${OPTARG};;
    esac
done

kubectl config set-context --current --namespace=$KUBERNETES_NAMESPACE
echo "Context set to namespace: \"$KUBERNETES_NAMESPACE\""

KUBERNETES_INFERENCE_PODS=$(kubectl get pod --output json \
    | jq -r '.items[] | select(.spec.replicas==0 | not) 
        | select(.metadata.name | startswith("inference-"))
        | .metadata.name')

echo -e "Performing reload_last_config on inference pods:\n$KUBERNETES_INFERENCE_PODS\n\n"

for inference_pod in $KUBERNETES_INFERENCE_PODS; do
    inference_container=$(kubectl get pod --output json \
        | jq -r '.items[] | select(.metadata.name=="'$inference_pod'")
            | .metadata.labels.app')
    kubectl exec -t $inference_pod -- /bin/bash -c "curl -X PUT http://$inference_container:80/reload_last_config --no-progress-meter" > response.json
    echo -e "$inference_container:\n$(cat response.json | jq)"
done
