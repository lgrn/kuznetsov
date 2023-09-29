# kuznetsov

TODO: Pretty much everything. Testing and documentation.

## How to: Prepare

Install an Ubuntu system with a prepared ZFS dataset called `tank/lxd`

### Preparing ZFS dataset
This example assumes `/dev/vdb` as the initial designated ZFS volume.
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

# reboot, verify mounted=no:

$ zfs get all tank | grep mount
tank  mounted               no                     -
```

Apart from ZFS storage, no additional preparation is needed as long as
it's an Ubuntu 22 system, currently the only osversion supported.

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
