# kuznetsov

This is an Ansible configuration for initializing and configuring Incus
(previously LXD) hosts on Ubuntu. Only Ubuntu is supported as this time
as the playbook assumes ZFS availability.

The purpose of this project is to write a generally usable Ansible
configuration that can help you target an Ubuntu system and both deploy
Incus, as well as maintain the deployments on it.

Both hosts and containers are configured as grouped Ansible host objects
in the inventory `hosts.yml`. Roles are then applied to groups of objects
in `main.yml`. For a detailed description of how this configuration
works, see *Technical Description* below.

Design goals:

- [x] Bootstrap an Ubuntu VM or physical server to serve as host.
  - [x] Use existing dataset (ZFS only)
  - [ ] Support clustering of multiple hosts
- [x] Deploy containers in Ansible group `lxd_containers` on its
  `parent`.
- [ ] Deploy virtual machines
- [x] Support IPv4 port forwarding from host -> container using `ports`
  attribute on container.
- [ ] Support HTTP forwarding based on host header (layer 7 routing) and
  automatic certificate handling with caddy.
- [ ] Provide useful standard roles
  - [ ] PostgreSQL
- [ ] Provide useful standard profiles, like increased root disk.

**NOTE**: Incus is not production ready and neither is this repo.

## Supported OS versions

- Ubuntu 22.04 LTS

## How to: Prepare

Install an Ubuntu system with a prepared ZFS dataset. The name of the
dataset can be set per host in `hosts.yml` as `zfs_pool`. This value
will be used during LXD init and set as the default datasource.

### Preparing a ZFS dataset

This example assumes `/dev/vdb` as the only initial designated ZFS
volume, but any type of setup could be done (for example RAIDz).

```sh
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

If you already have a `zpool` set up, for example if your Ubuntu root
partition is already zfs, you probably only have to do `zfs create
your_zpool/incus` and point `zfs_pool` in `main.yml` to it. You may not
even have to run `zfs create` first, who knows.

## How to: Kuznetsov configuration

* Set up `hosts.yml` to correctly refer to:
  * Prepared LXD host(s) and their ZFS datasets
  * Containers and their parents (hosts)
* Assign roles to groups of hosts in `main.yml` as necessary

To assist with understanding the expected syntax and values in these
files, you are provided with `.example` files for both.

## How to: Run Kuznetsov

- `git clone` the repo
- Initialize a python3 virtual environment in the cloned folder:
  `python3 -m venv kuznetsov`
- `cd` into the directory, run `source bin/activate` to activate the
  venv, and install requirements with `pip install -r requirements.txt`
- Run `ansible-playbook main.yml` (possibly with `--check` first) to
  target anything in `hosts.yml` with role mappings as defined in `main.yml`

## Technical Description

- `ansible.cfg` tells Ansible to use `hosts.yml` as inventory and
  `ssh_config` (generated) as configuration for all ssh connections
- Ansible parses both LXD hosts and containers as host objects in
  inventory `hosts.yml`. Each container has a `parent` attribute
  designating what host it should be present on.
- Ansible runs `main.yml`:
- Ansible first runs the `localhost` role locally, which creates
  necessary files from `templates/` to continue:
  - `cloudconfig.yml` contains `user-data` and `network-config` yaml for
    each container, which is passed in at container creation. Among
    other things, this contains SSH keys.
  - `ssh_config` is a normal ssh configuration file, pointed to by
    `ansible.cfg` with a block for each involved Ansible host object.
    Containers are reached via `ProxyJump` to the host.
- When local files are created, the `lxd_host` role is applied to all
  hosts:
  - `apt` and `snap` (lxd) installations run
  - `lxd` is initialized, if not already
  - a loop goes through all Ansible host objects in group
    `lxd_containers` that has the current LXD host set as `parent`
  - Ansible's `lxd_container` runs for each container, creating it if
    not present.
  - Each container gets passed data from `cloudconfig.yml` as well as
    any host variables for the container, such as `ip`, `cpu` etc.
  - Ansible waits for the container to be reachable over SSH, this only
    works when package `ssh` is configured to be installed. It ensures
    both that `cloud-init` ran successfully and that Ansible can SSH to
    this node going forward.
