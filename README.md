# linuxdeploy Build Helper Container

A docker container that aims to help build an
[AppImage](https://github.com/AppImage/AppImageKit) using
[linuxdeploy](https://github.com/linuxdeploy/linuxdeploy).

## Note:

Formerly this was an action. After much trial-and-error, I've decided to focus
on making an image that can be run locally or in a GitHub runner by project
managers using a script. Examples will be provided.

## Available architectures

    amd64 (x86_64)
    arm64 (aarch64)
    arm/v7 (armhf)

## Locally

To build for other architectures, you may need to use qemu with docker. There
may be other ways, but you can check out [this
document](https://www.stereolabs.com/docs/docker/building-arm-container-on-x86)
for starters.

## In a GitHub Runner

See [tests.yml](https://github.com/andy5995/linuxdeploy-build-helper-container/blob/trunk/.github/workflows/test.yml)

## Example

    docker run \
      -t --rm \
      --platform linux/arm64 \
      -e VERSION="helpme" \
      -e HOSTUID="$(id -u)" \
      -w /workspace \
      -v $PWD:/workspace \
      ldtest:latest /workspace/packaging/appimage/pre-appimage.sh

<!--
## Contributing

Open an issue and ask about a change before starting work on a pull
request. -->
