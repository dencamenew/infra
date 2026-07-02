#!/usr/bin/env bash
set -euo pipefail

HOSTS_FILE=/etc/hosts

add_host() {
  local ip="$1"
  local host="$2"

  if grep -Eq "^[[:space:]]*${ip}[[:space:]].*\\b${host}\\b" "$HOSTS_FILE"; then
    return
  fi

  if grep -Eq "[[:space:]]${host}(\\s|$)" "$HOSTS_FILE"; then
    sudo sed -i.bak -E "s/^[^#].*[[:space:]]${host}(\\s|$)/${ip} ${host}/" "$HOSTS_FILE"
  else
    echo "${ip} ${host}" | sudo tee -a "$HOSTS_FILE" >/dev/null
  fi
}

add_host 127.0.0.1 gitlab.local
add_host 10.10.10.10 app.lab.local
add_host 10.10.10.10 api.lab.local
add_host 10.10.10.10 argocd.lab.local

echo "Host aliases are ready: gitlab.local, app.lab.local, api.lab.local, argocd.lab.local"
