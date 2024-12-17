#!/bin/sh
set -e

packages="locales curl wget xz-utils sudo git rsync file python3 python3-pip python3-venv lshw gdisk fdisk parted fakechroot fakeroot bmap-tools qemu-system-x86 software-properties-common ca-certificates psmisc procps"

echo "Installing required packages"

apt update

echo "Installing required packages"

DEBIAN_FRONTEND=noninteractive TZ=Etc/UTC apt install -y $packages

echo "Setup en_US-UTF-8 locale"

export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8
locale-gen en_US.UTF-8


echo "Setting up build tooling for user $_CONTAINER_USER in home folder $_REMOTE_USER_HOME"

sudo -H -u $_CONTAINER_USER -c 'python3 -m venv $_REMOTE_USER_HOME/venv' 

echo "Using build tools from repo: $BUILD_TOOLS_REPO"
echo "Using build tools version: $BUILD_TOOLS_VERSION"

echo "Cloning build tools."

sudo -H -u $_CONTAINER_USER -c 'mkdir -p $_REMOTE_USER_HOME/tools'

sudo -H -u $_CONTAINER_USER -c 'git clone --branch $BUILD_TOOLS_VERSION $BUILD_TOOLS_REPO $_REMOTE_USER_HOME/tools/build_tools'

echo "Enabling venv as default."

echo "source ~/venv/bin/activate" >> $_REMOTE_USER_HOME/.bashrc

