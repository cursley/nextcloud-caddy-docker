#!/usr/bin/env bash

# Abort the script on errors.
set -e

REPOSITORY="https://github.com/cursley/nextcloud-caddy-docker.git"

main() {
    # Check for a Linux system.
    if [[ "$(uname)" != "Linux" ]]; then
        echo "This script only supports Linux systems."
        error=1
    fi

    # Check the current user is not root.
    if [[ "$EUID" -eq 0 ]]; then
        echo "Please run this script as a regular user. I'll sudo as needed."
        error=1
    fi

    # Exit if any of the above checks failed.
    if [[ "$error" ]]; then
        exit 1
    fi

    echo "Here's the plan:"
    echo
    PHASE=plan perform_installation
    echo
    if [[ "$LAST_SUDO_STEP" != 0 ]]; then
        echo "I'll use sudo for steps 1 to $LAST_SUDO_STEP. You may need to enter your password."
        echo
    fi
    read -p "Is this OK? [y/N] " -n1
    echo

    if [[ "$REPLY" == "y" ]]; then
        PHASE=run perform_installation
    else
        echo "Aborting."
    fi
}


# Perform the installation.
#
# Performs a dry run unless $PHASE is set to "run".
perform_installation() {
    STEP=0

    if ! installed git; then
        plan_step "Install git to clone the repository"
        running && install git
    fi

    if ! installed pwgen; then
        if [[ "$(os_release_id)" == "almalinux" ]]; then
            plan_step "Ensure EPEL repository is installed"
            running && install epel-release
        fi

        plan_step "Install pwgen to create passwords for the admin account and database user"
        running && install pwgen
    fi

    if ! installed docker; then
        if [[ "$(os_release_id)" == "almalinux" ]]; then
            plan_step "Install Docker"
            if running; then
                # Add Docker repo
                sudo dnf config-manager --add-repo=https://download.docker.com/linux/centos/docker-ce.repo

                # Install Docker CE
                sudo dnf install -y docker-ce

                # Enable and start the Docker service
                sudo systemctl enable --now docker
            fi
        else
            if ! installed curl; then
                plan_step "Install curl to fetch the Docker install script"
                running && install curl
            fi

            plan_step "Install Docker"
            if running; then
                curl -fsSL https://get.docker.com | sudo sh

                if [[ "$(os_release_id)" == "fedora" ]]; then
                    # Enable and start the Docker service
                    sudo systemctl enable --now docker
                fi
            fi
        fi

        # https://docs.docker.com/engine/install/linux-postinstall/
        plan_step "Enable user \"$USER\" to run Docker without sudo"
        running && sudo usermod -aG docker $USER
    fi

    # Steps from now on don't require root access
    LAST_SUDO_STEP="$STEP"

    plan_step "Clone the repository to $PWD/nextcloud"
    if running; then
        git clone "$REPOSITORY" nextcloud
        cd nextcloud
    fi

    plan_step "Create a configuration file at $PWD/nextcloud/.env"
    running && create_config

    plan_step "Start Nextcloud"
    if running; then
        # We add the current user to the "docker" group to allow them to use
        # Docker. Their group membership won't be re-evaluated in the current
        # shell session, so use sudo to create a new session and run Docker
        # inside it.
        sudo -u $USER docker compose up --build --wait

        echo
        echo "Started Nextcloud at https://$DOMAIN_NAME"
        echo
        echo "Username: $ADMIN_USER"
        echo "Password: $ADMIN_PASSWORD"
        echo
        echo "Change this password here: https://$DOMAIN_NAME/settings/user/security"
        echo
    fi
}

# Add a step to the plan.
plan_step() {
    if running; then
        echo "Step $((++STEP)) of $STEP_COUNT: $@"
    else
        echo "$((++STEP)). $@"

        # Keep count of the total number of steps.
        STEP_COUNT="$STEP"
    fi
}

# Check that the current run is not a dry run.
running() {
    [[ "$PHASE" == "run" ]]
}

# Check whether the specified command exists on the system.
#
# Returns 0 if the command exists.
#
# Example: installed git
installed() {
    command -v $1 &> /dev/null
}

# Install the named package using the system's package manager.
#
# Example: `install git`
install() {
    if installed dnf; then
        sudo dnf install -y "$@"
    elif installed apt-get; then
        sudo apt-get install -y "$@"
    else
        echo "Error: package manager not found (expected dnf or apt)"
        exit 1
    fi
}

# Get the OS release identifier.
#
# Examples: debian, almalinux
os_release_id() {
    source /etc/os-release
    echo $ID
}

# Prompt for configuration options and write a .env file.
create_config() {
    DEFAULT_DOMAIN_NAME="localhost"
    DEFAULT_ADMIN_USER="admin"

    read -p "Domain name [$DEFAULT_DOMAIN_NAME]: " DOMAIN_NAME
    read -p "Nextcloud admin username [$DEFAULT_ADMIN_USER]: " ADMIN_USER

    DOMAIN_NAME="${DOMAIN_NAME:-$DEFAULT_DOMAIN_NAME}"
    ADMIN_USER="${ADMIN_USER:-$DEFAULT_ADMIN_USER}"
    ADMIN_PASSWORD="$(pwgen -s 32)"

    echo "# Configuration generated by $USER on $(date)" > .env
    echo "DOMAIN_NAME=$DOMAIN_NAME" >> .env
    echo "NEXTCLOUD_ADMIN_USER=$ADMIN_USER" >> .env
    echo "NEXTCLOUD_INITIAL_ADMIN_PASSWORD=$ADMIN_PASSWORD" >> .env
    echo "POSTGRES_PASSWORD=$(pwgen -s 32)" >> .env
}

main
