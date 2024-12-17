#!/bin/sh
set -e

packages="locales sudo git python3 python3-pip python3-venv"

echo "Installing required packages"

apt update

echo "Installing required packages"

DEBIAN_FRONTEND=noninteractive TZ=Etc/UTC apt install -y $packages

echo "Setting up build tools in folder /build"

mkdir -p /build

python3 -m venv /build/venv

echo "Using build tools from repo: $BUILD_TOOLS_REPO"
echo "Using build tools version: $BUILD_TOOLS_VERSION"

echo "Cloning build tools."

mkdir -p /build/tools
git clone --branch $BUILD_TOOLS_VERSION $BUILD_TOOLS_REPO /build/tools/build_tools

if [ $_CONTAINER_USER != "root" ]; then
    echo "Fixing ownership of build tools."
    sudo chown -R $_CONTAINER_USER /build
fi

echo "Enabling venv as default."

echo "source ~/venv/bin/activate" >> $_REMOTE_USER_HOME/.bashrc

