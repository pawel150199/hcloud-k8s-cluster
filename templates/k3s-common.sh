# Helpers shared by the master and worker bootstrap scripts. Sourced, not run,
# so it deliberately sets no shell options of its own: those belong to the
# script that sources it.

log() {
  echo "[k3s-bootstrap] $*"
}

# Print the name of the interface holding the given address, waiting for it to
# appear. The private NIC is brought up by DHCP after `netplan apply`, so it is
# not there yet the moment cloud-init reaches runcmd.
wait_for_private_iface() {
  local address="$1" attempts="${2:-60}" iface=""

  for _ in $(seq 1 "$attempts"); do
    iface=$(ip -4 -o addr show | awk -v prefix="^$address/" '$4 ~ prefix { print $2 }' | head -n 1)
    [ -n "$iface" ] && break
    sleep 2
  done

  if [ -z "$iface" ]; then
    log "private address $address never came up" >&2
    return 1
  fi

  printf '%s\n' "$iface"
}

# Wait until a k3s API server answers /ping. Agents and joining servers are
# rejected outright if they start before the one they join is serving.
wait_for_api_server() {
  local endpoint="$1" attempts="${2:-180}"

  for _ in $(seq 1 "$attempts"); do
    if curl -skf --max-time 5 "https://$endpoint:6443/ping" > /dev/null; then
      log "API server at $endpoint:6443 is up"
      return 0
    fi
    sleep 5
  done

  log "API server at $endpoint:6443 did not answer in time" >&2
  return 1
}

# Run the k3s installer, configured through the INSTALL_K3S_* and K3S_*
# variables the caller exports. The script is downloaded before it is run: a
# pipe into sh succeeds even when the download failed.
install_k3s() {
  local attempts="${1:-10}"

  for _ in $(seq 1 "$attempts"); do
    if curl -sfL https://get.k3s.io -o /tmp/k3s-install.sh && sh /tmp/k3s-install.sh; then
      return 0
    fi
    log "k3s installation attempt failed, retrying"
    sleep 15
  done

  log "k3s installation failed after $attempts attempts" >&2
  return 1
}
