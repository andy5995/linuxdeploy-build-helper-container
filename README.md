# linuxdeploy Build Helper

An action that aims to help build an
[AppImage](https://github.com/AppImage/AppImageKit) using
[linuxdeploy](https://github.com/linuxdeploy/linuxdeploy).

Currently supported platforms:

    amd64
    arm64

## Inputs available

```
  platform:
    description: 'Target platform for LinuxDeploy'
    required: true
    default: 'amd64'
  dependency_commands:
    description: 'Commands to install dependencies'
    required: false
    default: ''
  build_commands:
    description: 'Commands to build the project'
    required: true
    default: ''
  install_to_appdir_commands:
    description: 'Commands to install and copy files to the destination AppDir'
    required: true
    default: ''
  linuxdeploy_output_version:
    description: 'Version string used by linuxdeploy used for the image filename'
    required: true
    default: ''
  linuxdeploy_args:
    description: 'Argument string to pass to linuxdeploy'
    required: true
    default: ''
```

## Example usage

```yaml
  build-appimage:
    runs-on: ubuntu-latest
    strategy:
      matrix:
        platform: [amd64, arm64]
    env:
      VERSION: ${{ inputs.version }}
    steps:
      - name: Checkout
        uses: actions/checkout@v4
        with:
          submodules: true
      - if: ${{ inputs.version }} == ''
        run: echo "VERSION=${{ github.sha }}" >> $GITHUB_ENV
      - name: Build AppImage
        uses: andy5995/linuxdeploy-build-helper@v1
        with:
          platform: ${{ matrix.platform }}
          dependency_commands: |
            sudo apt install -y libncursesw5-dev
          build_commands: |
            export -p
            meson setup _build -Dprefix=/usr
            cd _build
            ninja
          install_to_appdir_commands: |
            meson install --destdir=$APPDIR --skip-subprojects
          linuxdeploy_output_version: $VERSION
          linuxdeploy_args: |
            -d packaging/rmw.desktop \
            --icon-file=packaging/rmw_icon_32x32.png \
            --icon-filename=rmw \
            --executable=$APPDIR/usr/bin/rmw \
            -o appimage

      - name: Create sha256sum
        run: |
          cd out
          sha256sum $IMAGE_FILENAME > $IMAGE_FILENAME.sha256sum

      - name: Upload AppImage
        uses: actions/upload-artifact@v4
        with:
          name: ${{ env.IMAGE_FILENAME }}
          path: ./out/*
          if-no-files-found: error
```
## Notes

The AppImage will be placed in `./` (relative to your GitHub workspace).

The value of these variables are set in the action:

    ACTION_WORKSPACE
    APPDIR
    IMAGE_FILENAME (after the AppImage has been created)

Use '$ACTION_WORKSPACE' if you need to specify an absolute path.
GITHUB_WORKSPACE won't work in most sections because the commands are run
inside a docker container as an unprivileged user.

The arm64 builds are done using
[qemu](https://github.com/docker/setup-qemu-action) and will take much longer
than on a native arm64 system. GitHub has a timeout and if your build takes
longer than the timeout setting, then the job will exit before the image is
created.

If you have access to a native arm64 system, you can use the docker image from
this action, which is `andy5995/linuxdeploy:latest` or use a linuxdeploy
release from their repository (link above).

## Contributing

Open an issue and ask about a change before starting work on a pull
request.

