#!/bin/bash
# ------------------------------------------------------------------------------
# CockroachDB binary install (idempotent).
# Only installs the binary + supporting GEOS libs + prepares directories.
# Cert generation, node startup, and cluster init are performed MANUALLY
# after `terraform apply`, because they need the VM IPs Terraform assigns.
# ------------------------------------------------------------------------------
set -euo pipefail
exec > >(tee -a /var/log/cockroach-startup.log) 2>&1

echo "[cockroach-startup] begin: $(date -Is)"

# Skip if already installed (script may re-run on VM restart)
if [ -x /usr/local/bin/cockroach ]; then
  echo "[cockroach-startup] cockroach already installed, exiting"
  exit 0
fi

apt-get update -y
apt-get install -y curl ca-certificates

cd /tmp
curl -fsSL "https://binaries.cockroachdb.com/cockroach-v${crdb_version}.linux-amd64.tgz" -o cockroach.tgz
tar -xzf cockroach.tgz

cp -i "cockroach-v${crdb_version}.linux-amd64/cockroach" /usr/local/bin/
mkdir -p /usr/local/lib/cockroach
cp -i "cockroach-v${crdb_version}.linux-amd64/lib/libgeos.so"    /usr/local/lib/cockroach/
cp -i "cockroach-v${crdb_version}.linux-amd64/lib/libgeos_c.so"  /usr/local/lib/cockroach/

# Dedicated user + data dir (used later by the systemd unit you create manually)
id -u cockroach >/dev/null 2>&1 || useradd -r -s /bin/false -m -d /var/lib/cockroach cockroach
mkdir -p /var/lib/cockroach/certs
chown -R cockroach:cockroach /var/lib/cockroach

# Verify
/usr/local/bin/cockroach version || true

echo "[cockroach-startup] done: $(date -Is)"
