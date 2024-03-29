#!/bin/bash

echo ""
echo "linuxdeploy Build Helper Container v2.0.0"
echo "https://github.com/andy5995/linuxdeploy-build-helper-container"
echo ""

OLDPWD=$PWD

if [ -z "HOSTUID" ]; then
  echo "HOSTUID is not set."
  exit 1
fi

if [ -z "$1" ]; then
  echo "One argument required -- the name of a script to run."
  exit 1
fi

usermod -u $HOSTUID builder
su builder -c "PATH=/home/builder/.local/bin:$PATH && cd $OLDPWD && $1"
