# linuxdeploy Build Helper Container

A docker container that aims to help build an
[AppImage](https://github.com/AppImage/AppImageKit) on multiple architectures
using [linuxdeploy](https://github.com/linuxdeploy/linuxdeploy).

## Available architectures

    amd64
    arm64
    arm/v7

(The appimage plugin doesn't yet support 'ppc64le' or 's390x')

## Example usage

    docker run -t \
    --rm \
    -e HOSTUID=$(id -u) \
    -e VERSION=test \
    -v $PWD:/workspace \
    -w /workspace \
    andy5995/linuxdeploy:v2 packaging/appimage/pre-appimage.sh

This is meant to be run from the source root of your project. Using the
command above, your current directory will be mounted in the container at
`/workspace`.

When the container starts, 'root' changes the UID of user 'builder' (a user
created during the build of the Dockerfile) to HOSTUID. This allows builder to
build your project and create the AppImage without root privileges (the
resulting files will be owned by you).

The only argument given after the name of the docker image in the `docker run`
command is the path/name of the script that builds your projects and includes
the command to call linuxdeploy. You can see an example at
[rmw/packaging/appimage/pre-appimage.sh](https://github.com/theimpossibleastronaut/rmw/blob/master/packaging/appimage/pre-appimage.sh).

You may use `sudo` in your script to install packages or do other things.

If you would like to look around the container, you can use

    docker run -it --rm --entrypoint sh andy5995/linuxdeploy:v2

## Locally

If you want to clean your project build directory, you can add `-e
CLEAN_BUILD=true` to the `docker run` arguments, and use something like this
in your script:

```sh
# Clean build directory if specified and it exists
if [ "$CLEAN_BUILD" = "true" ] && [ -d "$BUILD_DIR" ]; then
  rm -rf "$BUILD_DIR"
fi

# Setup project for building, run ./configure, ./autogen.sh, cmake, etc
if [ ! -d "$BUILD_DIR" ]; then
  meson setup "$BUILD_DIR" \
    -Dbuildtype=release \
    -Dstrip=true \
    -Db_sanitize=none \
    -Dprefix=/usr
fi
```

To build for other architectures, you may need to use qemu with docker. There
may be other ways, but you can check out [this
document](https://www.stereolabs.com/docs/docker/building-arm-container-on-x86)
for starters. If you are set up to build on other architectures, add
`--platform=linux/<arch>` to the `docker run` arguments.

## In a GitHub Runner

See [tests.yml](https://github.com/andy5995/linuxdeploy-build-helper-container/blob/trunk/.github/workflows/test.yml)

## linuxdeploy Plugins

These plugins are installed in the container:

* [linuxdeploy-plugin-gtk](https://github.com/linuxdeploy/linuxdeploy-plugin-gtk)
* [linuxdeploy-plugin-qt](https://github.com/linuxdeploy/linuxdeploy-plugin-qt)

## Note

The container runs Ubuntu 20.04 (Focal Fossil). See [this
discussion](https://github.com/orgs/AppImage/discussions/1254) for more
details on why I chose that version of Ubuntu.

Some 'GITHUB_...' variables will not work inside the container.

Recent version of cmake, meson, and ninja are installed to
'/home/builder/.local/bin' which is the first path in PATH (installing them
with `apt` will probably offer no benefit).

If you want to see more details about the container or what packages are
pre-installed, look at the two Dockerfiles in this repository. If you'd like
more packages pre-installed, please open an issue.

## Contributing

Ok, but it's a good idea to open an issue and ask about a change before
starting work on a pull request. Someone, or myself, may already be working on
it, or planning to. Also, please consult [this
guide](https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/getting-started/best-practices-for-pull-requests)
before you submit a pull request.
