#!/usr/bin/env bash
#
# Description: Drain haproxy by blocking health checks.

set -uo pipefail

drain_seconds=600

usage() {
  cat << USAGE
usage: $(basename "$0") <opts>
  -h           Display this message
  -u           Un-drain the node
  -w <seconds> Seconds to wait for drain (Default: ${drain_seconds})
USAGE
}

undrain='0'

iptables_drain() {
  local flag='-A'
  if [[ "${undrain}" -ne 0 ]]; then
    flag='-D'
  fi
  iptables \
    "${flag}" INPUT \
    -p tcp  \
    --dport 8001:8003 \
    -j REJECT \
    --reject-with tcp-reset
}

opt='' OPTIND='1' help='0'
while getopts 'huw:' opt ; do
  case "${opt}" in
    h) help='1' ;;
    u) undrain='1' ;;
    w) drain_seconds="${OPTARG}" ;;
    *)
      echo 'ERROR: Invalid flag'
      usage
      exit 1 ;;
  esac
done
shift $((OPTIND - 1))

if [[ "${help}" -ne 0 ]]; then
  usage
  exit
fi

if [[ "${drain_seconds}" -lt 0 ]]; then
  echo "ERROR: Invalid drain time '${drain_seconds}'"
  usage
  exit 1
fi

if [[ "${undrain}" -ne 0 ]]; then
  echo 'Un-Blocking health check'
else
  echo 'Blocking health check'
fi
if ! iptables_drain; then
  echo 'ERROR: Failed to run iptables command'
  exit 1
fi

if [[ "${undrain}" -eq 0 ]]; then
  echo 'Waiting for drain'
  sleep "${drain_seconds}"
  echo "Drain complete, undrain with '$(basename "$0") -u'"
fi
