#!/bin/bash

set -e

echo ""
echo "linuxdeploy Build Helper Container v3.2.0"
echo "https://github.com/andy5995/linuxdeploy-build-helper-container"
echo ""

OLDPWD=$PWD

# Auto-detect the host's UID/GID from the owner of the bind-mounted
# workspace. Docker preserves host ownership across bind mounts, so the
# numeric IDs we read in here correspond to whoever ran `docker compose
# run` on the host. Callers can still pass HOSTUID/HOSTGID explicitly to
# override (useful in CI matrices or when the workspace ownership doesn't
# match the invoking user).
HOSTUID=${HOSTUID:-$(stat -c %u "$OLDPWD")}
HOSTGID=${HOSTGID:-$(stat -c %g "$OLDPWD")}

if [ -z "$HOSTUID" ] || [ "$HOSTUID" = "0" ]; then
  echo "Could not determine a non-root HOSTUID."
  echo "Either run from a workspace owned by a regular user, or pass HOSTUID explicitly."
  exit 1
fi

if [ -z "$1" ]; then
  echo "One argument required -- the name of a script to run."
  exit 1
fi

usermod -u "$HOSTUID" builder
groupmod -g "$HOSTGID" builder

# The docs state to use '-w /workdir when running the container, but switching
# to builder here will change the directory. Using cd to change back...
su builder -c "cd $OLDPWD && . ~/.profile && $1"
