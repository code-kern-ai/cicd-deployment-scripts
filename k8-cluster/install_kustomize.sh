#!/bin/bash
set -e

KUSTOMIZE_VERSION="5.3.0"

while getopts v flag
do
    case "${flag}" in
        v) KUSTOMIZE_VERSION=${OPTARG};;
    esac
done

curl -O "https://raw.githubusercontent.com/kubernetes-sigs/kustomize/master/hack/install_kustomize.sh"
bash ./install_kustomize.sh $KUSTOMIZE_VERSION
mv kustomize /usr/local/bin/kustomize && chmod +x /usr/local/bin/kustomize
rm -f ./install_kustomize.sh
