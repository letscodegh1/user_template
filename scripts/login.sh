#!/usr/bin/env bash
# Loguje `az` jako service principal kursanta (Terraform tego nie potrzebuje,
# ale przydaje się do `az resource list` itp.). Uruchom PO `source studentNN.env`.
set -euo pipefail

: "${ARM_CLIENT_ID:?Najpierw: source ~/.tf-training/studentNN.env}"

az login --service-principal \
  --username "$ARM_CLIENT_ID" \
  --password "$ARM_CLIENT_SECRET" \
  --tenant "$ARM_TENANT_ID" \
  --output none

az account set --subscription "$ARM_SUBSCRIPTION_ID"
az account show --query "{subscription:name, user:user.name}" --output table
