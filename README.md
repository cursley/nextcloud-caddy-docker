# Nextcloud via Caddy in Docker

This repository contains a [Docker Compose](https://docs.docker.com/compose/) configuration to run [Nextcloud](https://nextcloud.com/) behind a [Caddy](https://caddyserver.com/) reverse proxy. Caddy provides automatic HTTPS via [Let's Encrypt](https://letsencrypt.org/).

This configuration uses [PostgreSQL](https://www.postgresql.org/) for the database and includes [Redis](https://redis.io/) for caching and file locking.

## Usage

Run this on a fresh [Debian](https://www.debian.org/) install to set up a Nextcloud server:

```sh
# Ensure Git is installed
sudo apt install git -y

# Clone this repository
git clone https://github.com/cursley/nextcloud-caddy-docker.git nextcloud
cd nextcloud

# Run the setup script
bin/nextcloud
```

The `nextcloud` script creates a configuration, ensures Docker is installed, and starts the application. It will:

1. Prompt for a domain name. Enter a domain name for the Nextcloud instance, such as `cloud.example.com`. Caddy will request TLS certificates for this domain name. The domain name should resolve to the server on which you are running the script, and ports 80 and 443 should be open. Enter `localhost` if testing locally.
1. Prompt for a username for the Nextcloud administrator account. The default is `admin` - it's a good idea to use something different.
1. Generate an initial password for the administrator account, and a password for the PostgreSQL database user, using `pwgen`. If `pwgen` isn't available, it's installed using `sudo`.
1. Install Docker if required.
1. Start the application. On the first run, this downloads the Docker images for Caddy, Nextcloud, PostgreSQL and Redis.
1. On the first run, show the username and generated password for the Nextcloud administrator account.

Here is an example first run:

```
$ bin/nextcloud
Generating a configuration file.
Domain name [localhost]: cloud.initech.com
Nextcloud admin username [admin]: lumbergh
Installing Docker...
--- snip ---
Starting Nextcloud...
--- snip ---
Started Nextcloud at https://cloud.initech.com

Username: lumbergh
Password: <generated password>

Change this password here: https://cloud.initech.com/settings/user/security
```

Nextcloud restarts automatically when the server reboots. To stop Nextcloud and prevent it from restarting, run `docker compose down`.

User files are stored in a Docker volume named `nextcloud_data`. To locate the volume, run `docker volume inspect nextcloud_data`.
