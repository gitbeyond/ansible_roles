#!/bin/bash
TOKEN_PUB=$(openssl rand -hex 3)
TOKEN_SECRET=$(openssl rand -hex 8)
BOOTSTRAP_TOKEN="${TOKEN_PUB}.${TOKEN_SECRET}"
token_file=$1

echo "${BOOTSTRAP_TOKEN}" >${token_file}
echo "${BOOTSTRAP_TOKEN}"
