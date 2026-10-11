# Homelab

A self-hosted server running on an old ThinkPad, built to practise Linux administration and server hardening. The first service it will host is a Minecraft server in Docker.

This README is a running log of what I set up and why.

## Hardware and OS

| | |
|---|---|
| Machine | Lenovo ThinkPad (type 20M6) |
| OS | Debian stable, installed headless (no desktop environment) |
| Hostname | `homelab` |
| Network | Wi-Fi (the laptop has no standard Ethernet port) |
| Access | SSH over Tailscale, key-only |

## What I have done so far

### 1. Installation

- I wrote the Debian netinst image to a USB stick with Rufus in DD image mode, so the stick is an exact copy of the official image.
- Installed with only **SSH server** and **standard system utilities** selected. No desktop environment.
  - Why: a GUI idles at over 1 GB of RAM that the server can use instead, and fewer installed packages means a smaller attack surface and less to patch.
- Left the root password empty during install. This disables direct root login and gives my own user `sudo` rights.
  - Why: admin rights are requested per command instead of working in a permanent root shell.
- Used the whole disk without encryption.
  - Why: full-disk encryption needs a passphrase typed on the laptop's own keyboard at every boot, which does not work for a machine that should come back up unattended after a power cut. This is a trade-off I may revisit.

### 2. Base configuration

- Updated all packages: `sudo apt update && sudo apt full-upgrade`
- Stopped the laptop suspending when the lid is closed, using a systemd-logind drop-in. See [`configs/logind/lid.conf`](configs/logind/lid.conf).

### 3. SSH hardening

- Added my ed25519 public key to `~/.ssh/authorized_keys` on the server.
- Disabled password authentication and root login over SSH with a drop-in config. See [`configs/ssh/hardening.conf`](configs/ssh/hardening.conf).
  - Why: a key cannot be guessed, while a password on an open SSH port is a constant target for brute-force attempts.
- Verified the change:
  - `ssh user@host` logs in with the key.
  - `ssh -o PubkeyAuthentication=no user@host` is refused with `Permission denied (publickey)`.

### 4. Firewall

- Installed `ufw` with a default-deny policy for incoming traffic.

```
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow 22/tcp
sudo ufw enable
```

- Why: nothing is reachable from the network unless I have added a rule for it.

### 5. Remote access

- Installed Tailscale on the server and on my laptop, which puts both on a private WireGuard-based network.
- I can now SSH to the server from any network using its Tailscale address, with the same key-only login as before.
  - Why: no ports are forwarded on my home router, so SSH is not exposed to the internet at all. Only devices signed in to my Tailscale network can reach it.
- Disabled key expiry for the server in the Tailscale admin console so it does not drop off the network unattended. Expiry stays on for my laptop.
- Added a host entry in `~/.ssh/config` on my laptop, so `ssh homelab` connects without typing the address.
- Verified by connecting from a mobile hotspot and  from my school campus instead of my home Wi-Fi.
- Restricted SSH in ufw to the Tailscale interface only and removed the general port 22 rule, so devices on my home network can no longer reach SSH either.

## Planned

- [ ] Install Docker
- [ ] Run a Minecraft server in a container
- [ ] Automatic security updates
- [ ] Backups of the Minecraft world data
- [ ] Website to manage whitelists etc for the Minecraft server.

## Config files

```
configs/
  logind/lid.conf        -> /etc/systemd/logind.conf.d/lid.conf
  ssh/hardening.conf     -> /etc/ssh/sshd_config.d/hardening.conf
```
