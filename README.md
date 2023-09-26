# kuznetsov

TODO: Pretty much everything. Testing and documentation.

## How to: Prepare

- Install an Ubuntu system with a prepared ZFS dataset called `tank/lxd`

## How to: Configuration

- Set up `hosts.yml` to correctly point out one prepared LXD host and
  its containers
- Assign roles to groups of hosts in `main.yml` as necessary
- Run `ansible-playbook`