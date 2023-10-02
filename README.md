# kuznetsov

This is an Ansible configuration for initializing and configuring LXD hosts on Ubuntu.

Both hosts and containers are configured as Ansible host objects in the inventory `hosts.yml`. For a detailed description of how this configuration works, see *Technical Description* below.

## Supported versions:

* Ubuntu 22.04 LTS

## How to: Prepare

Install an Ubuntu system with a prepared ZFS dataset. The name of the dataset can be set per host in `hosts.yml` as `zfs_pool`. This value will be used during LXD init and set as the default datasource.

### Preparing a ZFS dataset
This example assumes `/dev/vdb` as the only initial designated ZFS volume, but any type of setup could be done (for example RAIDz).
```
$ sudo apt install zfsutils-linux

$ sudo zpool create tank /dev/vdb

$ zfs list
NAME   USED  AVAIL     REFER  MOUNTPOINT
tank   102K  48.0G       24K  /tank

$ sudo zfs set compression=lz4 tank

$ sudo zfs create tank/lxd

$ sudo zfs set canmount=noauto tank
$ sudo zfs set canmount=noauto tank/lxd

# reboot, verify mounted=no (LXD owns this):

$ zfs get all tank | grep mount
tank  mounted               no                     -
```

## How to: Configuration

- Set up `hosts.yml` to correctly refer to:
  - Prepared LXD host(s) and their ZFS datasets
  - Containers and their parents (hosts)
- Assign roles to groups of hosts in `main.yml` as necessary

## How to: Run

- `git clone` the repo
- `python3 -m venv kuznetsov`
- `cd` into the directory, run `source bin/activate` and install
  requirements with `pip install -r requirements.txt`
- Run `ansible-playbook main.yml` (possibly with `--check` first)

## Technical Description

- `ansible.cfg` tells Ansible to use `hosts.yml` as inventory and `ssh_config` (generated) as configuration for all ssh connections
- Ansible parses both LXD hosts and containers as host objects in inventory `hosts.yml`. Each container has a `parent` attribute designating what host it should be present on.
- Ansible runs `main.yml`:
- Ansible first runs the `localhost` role locally, which creates necessary files from `templates/` to continue:
  - `cloudconfig.yml` contains `user-data` and `network-config` yaml for each container, which is passed in at container creation. Among other things, this contains SSH keys.
  - `ssh_config` is a normal ssh configuration file, pointed to by `ansible.cfg` with a block for each involved Ansible host object. Containers are reached via `ProxyJump` to the host.
- When local files are created, the `lxd_host` role is applied to all hosts:
  - `apt` and `snap` (lxd) installations run
  - `lxd` is initialized, if not already
  - a loop goes through all Ansible host objects in group `lxd_containers` that has the current LXD host set as `parent`
  - Ansible's `lxd_container` runs for each container, creating it if not present.
  - Each container gets passed data from `cloudconfig.yml` as well as any host variables for the container, such as `ip`, `cpu` etc.
  - Ansible waits for the container to be reachable over SSH, this only works when package `ssh` is configured to be installed. It ensures both that `cloud-init` ran successfully and that Ansible can SSH to this node going forward.

## TODO

- [ ] Finish `lxd_host_nginx_forwarder` to ensure host-header HTTP forwarding is set up on the LXD host if configured
- [ ] Finish `lxd_network_init` (probably rename it) to ensure TCP port forwarding can be done to containers.
- [ ] Create container roles.