#!/bin/bash
set -e

AZCOPY_VERSION="v10"

while getopts v: flag
do
    case "${flag}" in
        v) AZCOPY_VERSION=${OPTARG};;
    esac
done

cd /usr/local/bin
curl -L https://aka.ms/downloadazcopy-${AZCOPY_VERSION}-linux | tar --strip-components=1 --exclude=*.txt -xzvf -
chmod +x azcopy
