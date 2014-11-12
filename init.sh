#!/bin/bash

# This script is run to provision the virtual machine for development.  It
# should not be run directly.  Instead, run `vagrant provision` from your host
# machine.  This script in turn delegates to the Makefile for incrementally
# provisioning the machine.
set -o errexit

if [[ $EUID -gt 0 ]] || [[ -z "$SUDO_USER" ]]; then
  echo "run this with sudo"
  exit 1
fi

USER_HOME=$(getent passwd $SUDO_USER | cut -d: -f6)
TOP=$(cd $(dirname $0) && pwd)

# change into TOP for interactive login
if ! grep --quiet "cd $TOP" $USER_HOME/.bashrc; then
  echo >> $USER_HOME/.bashrc
  echo "cd $TOP" >> $USER_HOME/.bashrc
fi

# this should be superflous, but the machine comes without make and
# without restarting networking, archive.ubuntu.com cannot be resolved reliably
# TODO: upgrade to trusty and see if virtualbox & vagrant upgrades help
/etc/init.d/networking restart && apt-get install --yes curl make

cd $TOP
make provision
