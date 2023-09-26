#!/bin/bash

# this script initializes lxd with the config below
# doc: https://linuxcontainers.org/lxd/docs/latest/howto/initialize/

# note that tank/lxd must exist

lxd init --preseed <<'EOF'
config: {}
networks:
- config:
    ipv4.address: 10.13.37.1/24
    ipv4.nat: "true"
    ipv6.address: none
    ipv6.nat: "false"
  description: ""
  name: lxdbr0
  type: bridge
  project: default
storage_pools:
- name: default
  driver: dir
  config:
    source: /var/snap/lxd/common/lxd/storage-pools/default
  description: ""
- name: lxd-pool
  driver: zfs
  config:
    source: "tank/lxd"
  description: "lxd zfs pool targeting tank/lxd"
profiles:
- config:
    snapshots.schedule: ""
  description: Default LXD profile
  devices:
    eth0:
      name: eth0
      network: lxdbr0
      type: nic
    root:
      path: /
      pool: default
      type: disk
  name: default
- config:
    snapshots.schedule: "0 5 * * *"
    snapshots.expiry: "1w"
  description: 10GB root disk, 1w of daily snapshots.
  devices:
    eth0:
      name: eth0
      network: lxdbr0
      type: nic
    root:
      path: /
      pool: lxd-pool
      type: disk
      size: 10GB
  name: default
- config:
    snapshots.schedule: "0 5 * * *"
    snapshots.expiry: "1w"
  description: 25GB root disk, 1w of daily snapshots.
  devices:
    eth0:
      name: eth0
      network: lxdbr0
      type: nic
    root:
      path: /
      pool: lxd-pool
      type: disk
      size: 25GB
  name: 25G

EOF
