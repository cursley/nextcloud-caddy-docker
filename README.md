# Nextcloud via Caddy in Docker

This is a script to deploy a containerised [Nextcloud](https://nextcloud.com/) instance with HTTPS support on a Linux server.

## What's included

- [Docker Engine](https://docs.docker.com/engine/)
- [Nextcloud](https://nextcloud.com/)
- [Caddy](https://caddyserver.com/), used as a reverse proxy to provide automatic HTTPS via [Let's Encrypt](https://letsencrypt.org/)
- [PostgreSQL](https://www.postgresql.org/) for Nextcloud's database
- [Redis](https://redis.io/) for caching and file locking

## Tested on

- [Debian 12](https://www.debian.org/)
- [Ubuntu Server 22.04 LTS](https://ubuntu.com/download/server)
- [AlmaLinux 9](https://almalinux.org/)
- [Fedora 39](https://fedoraproject.org/server/)

## Pre-requisites

A fresh install of any of the Linux distributions listed above.

## Installation

Run:

```sh
bash -c "$(curl -fsSL https://raw.githubusercontent.com/cursley/nextcloud-caddy-docker/main/install.sh)"
```

[The script](https://github.com/cursley/nextcloud-caddy-docker/blob/main/install.sh) explains what it will do and waits for confirmation before making any changes to your system. The installation steps may vary depending on the Linux distribution and what's already installed. Here is an example:

```
Here's the plan:

1. Install git to clone the repository
2. Install pwgen to create passwords for the admin account and database user
3. Install Docker
4. Enable user "alec" to run Docker without sudo
5. Clone the repository to /home/alec/nextcloud
6. Create a configuration file at /home/alec/nextcloud/.env
7. Start Nextcloud

I'll use sudo for steps 1 to 4. You may need to enter your password.

Is this OK? [y/N]
```

During the "Create a configuration file" step, the script prompts for two pieces of information:

1. A domain name for the Nextcloud instance, such as `cloud.example.com`. Caddy requests TLS certificates for this domain name, so the domain name should resolve to the server where you are running the script, and ports 80 and 443 should be open. Accept the default value of `localhost` if testing locally.
1. A username for the Nextcloud admin account. The default is `admin` - it's a good idea to use something different

The script generates an initial admin password, which you should change after the installation.

Once Nextcloud has started, the Nextcloud instance's URL and admin credentials are shown:

```
Started Nextcloud at https://cloud.initech.com

Username: lumbergh
Password: <generated password>

Change this password here: https://cloud.initech.com/settings/user/security
```

Nextcloud restarts automatically when the server reboots. To stop Nextcloud and prevent it from restarting, run `docker compose down` in the `nextcloud` directory.

User files are stored in a Docker volume named `nextcloud_data`. To locate the volume, run `docker volume inspect nextcloud_data`.
