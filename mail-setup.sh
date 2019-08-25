#!/usr/bin/env bash

readonly SALT_MASTER=$1;

until [[ -f /var/lib/cloud/instance/boot-finished ]]; do
  sleep 1
done

set -euxo pipefail

apt-get update && apt-get install -y salt-minion

sudo sed -i "s/#master: salt/master: ${SALT_MASTER}/" /etc/salt/minion

systemctl restart salt-minion
