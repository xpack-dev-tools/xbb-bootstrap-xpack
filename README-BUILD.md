# How to build the xPack XBB Bootstrap binaries

## Introduction

This project also includes the scripts and additional files required to
build and publish the
[xPack XBB Bootstrap](https://github.com/xpack-dev-tools/xbb-bootstrap-xpack) binaries.

The build scripts use the
[xPack Build Box (XBB)](https://xpack.github.io/xbb/),
a set of elaborate build environments based on recent GCC versions
(Docker containers
for GNU/Linux or a custom folder for MacOS).

There are two types of builds:

- **local/native builds**, which use the tools available on the
  host machine; generally the binaries do not run on a different system
  distribution/version; intended mostly for development purposes;
- **distribution builds**, which create the archives distributed as
  binaries; expected to run on most modern systems.

This page documents the distribution builds.

For native builds, see the `build-native.sh` script.

## Repositories

- <https://github.com/xpack-dev-tools/xbb-bootstrap-xpack.git> -
  the URL of the xPack build scripts repository
- <https://github.com/xpack-dev-tools/build-helper> - the URL of the
  xPack build helper, used as the `scripts/helper` submodule.
- <https://github.com/xpack-dev-tools/xbb-bootstrap.git> - the URL of the
  [xPack XBB Bootstrap fork](https://github.com/xpack-dev-tools/xbb-bootstrap)

The build scripts use the first repo.

### Branches

- `xpack` - the updated content, used during builds
- `xpack-develop` - the updated content, used during development
- `master` - empty

## Prerequisites

The prerequisites are common to all binary builds. Please follow the
instructions in the separate
[Prerequisites for building binaries](https://xpack.github.io/xbb/prerequisites/)
page and return when ready.

Note: Building the Arm binaries requires an Arm machine.

## Download the build scripts

The build scripts are available in the `scripts` folder of the
[`xpack-dev-tools/xbb-bootstrap-xpack`](https://github.com/xpack-dev-tools/xbb-bootstrap-xpack)
Git repo.

To download them, issue the following commands:

```sh
rm -rf ${HOME}/Work/xbb-bootstrap-xpack.git; \
git clone https://github.com/xpack-dev-tools/xbb-bootstrap-xpack.git \
  ${HOME}/Work/xbb-bootstrap-xpack.git; \
git -C ${HOME}/Work/xbb-bootstrap-xpack.git submodule update --init --recursive
```

> Note: the repository uses submodules; for a successful build it is
> mandatory to recurse the submodules.

For development purposes, clone the `xpack-develop` branch:

```sh
rm -rf ${HOME}/Work/xbb-bootstrap-xpack.git; \
git clone \
  --branch xpack-develop \
  https://github.com/xpack-dev-tools/xbb-bootstrap-xpack.git \
  ${HOME}/Work/xbb-bootstrap-xpack.git; \
git -C ${HOME}/Work/xbb-bootstrap-xpack.git submodule update --init --recursive
```

## The `Work` folder

The scripts create a temporary build `Work/xbb-bootstrap-${version}` folder in
the user home. Although not recommended, if for any reasons you need to
change the location of the `Work` folder,
you can redefine `WORK_FOLDER_PATH` variable before invoking the script.

## Spaces in folder names

Due to the limitations of `make`, builds started in folders with
spaces in names are known to fail.

If on your system the work folder is in such a location, redefine it in a
folder without spaces and set the `WORK_FOLDER_PATH` variable before invoking
the script.

## Customizations

There are many other settings that can be redefined via
environment variables. If necessary,
place them in a file and pass it via `--env-file`. This file is
either passed to Docker or sourced to shell. The Docker syntax
**is not** identical to shell, so some files may
not be accepted by bash.

## Versioning

The version string is semver.

## How to build local/native binaries

### README-DEVELOP.md

The details on how to prepare the development environment for XBB Bootstrap are in the
[`README-DEVELOP.md`](https://github.com/xpack-dev-tools/xbb-bootstrap-xpack/blob/xpack/README-DEVELOP.md)
file.

## How to build distributions

## Build

The builds currently run on 5 dedicated machines (Intel GNU/Linux,
Arm 32 GNU/Linux, Arm 64 GNU/Linux, Intel macOS and Arm macOS.

### Build the Intel GNU/Linux and Windows binaries

The current platform for GNU/Linux and Windows production builds is a
Debian 11, running on an AMD 5600G PC with 16 GB of RAM
and 512 GB of fast M.2 SSD. The machine name is `xbbmli`.

```sh
caffeinate ssh xbbmli
```

Before starting a build, check if Docker is started:

```sh
docker info
```

Before running a build for the first time, it is recommended to preload the
docker images.

```sh
bash ${HOME}/Work/xbb-bootstrap-xpack.git/scripts/helper/build.sh preload-images
```

The result should look similar to:

```console
$ docker images
REPOSITORY       TAG                    IMAGE ID       CREATED         SIZE
ilegeul/ubuntu   amd64-18.04-xbb-v3.4   ace5ae2e98e5   4 weeks ago     5.11GB
```

It is also recommended to Remove unused Docker space. This is mostly useful
after failed builds, during development, when dangling images may be left
by Docker.

To check the content of a Docker image:

```sh
docker run --interactive --tty ilegeul/ubuntu:amd64-18.04-xbb-v3.4
```

To remove unused files:

```sh
docker system prune --force
```

Since the build takes a while, use `screen` to isolate the build session
from unexpected events, like a broken
network connection or a computer entering sleep.

```sh
screen -S xbb-bootstrap

sudo rm -rf ~/Work/xbb-bootstrap-*-*
bash ${HOME}/Work/xbb-bootstrap-xpack.git/scripts/helper/build.sh --develop --linux64
```

or, for development builds:

```sh
sudo rm -rf ~/Work/xbb-bootstrap-*-*
bash ${HOME}/Work/xbb-bootstrap-xpack.git/scripts/helper/build.sh --develop --without-html --disable-tests --linux64
```

To detach from the session, use `Ctrl-a` `Ctrl-d`; to reattach use
`screen -r xbb-bootstrap`; to kill the session use `Ctrl-a` `Ctrl-k` and confirm.

About 20 minutes later, the output of the build script is a set of 4
archives and their SHA signatures, created in the `deploy` folder:

```console
$ ls -l ~/Work/xbb-bootstrap-*-*/deploy
total 13248
-rw-rw-rw- 1 ilg ilg 3601358 Jun 10 13:45 xpack-xbb-bootstrap-4.0.0-linux-x64.tar.gz
-rw-rw-rw- 1 ilg ilg     107 Jun 10 13:45 xpack-xbb-bootstrap-4.0.0-linux-x64.tar.gz.sha
```

### Build the Arm GNU/Linux binaries

The supported Arm architectures are:

- `armhf` for 32-bit devices
- `aarch64` for 64-bit devices

The current platform for Arm GNU/Linux production builds is Raspberry Pi OS,
running on a pair of Raspberry Pi4s, for separate 64/32 binaries.
The machine names are `xbbla64` and `xbbla32`.

```sh
caffeinate ssh xbbmla
```

Before starting a build, check if Docker is started:

```sh
docker info
```

Before running a build for the first time, it is recommended to preload the
docker images.

```sh
bash ${HOME}/Work/xbb-bootstrap-xpack.git/scripts/helper/build.sh preload-images
```

The result should look similar to:

```console
$ docker images
REPOSITORY       TAG                      IMAGE ID       CREATED          SIZE
hello-world      latest                   46331d942d63   6 weeks ago     9.14kB
ilegeul/ubuntu   arm64v8-18.04-xbb-v3.4   4e7f14f6c886   4 months ago    3.29GB
ilegeul/ubuntu   arm32v7-18.04-xbb-v3.4   a3718a8e6d0f   4 months ago    2.92GB
```

Since the build takes a while, use `screen` to isolate the build session
from unexpected events, like a broken
network connection or a computer entering sleep.

```sh
screen -S xbb-bootstrap

sudo rm -rf ~/Work/xbb-bootstrap-*-*
bash ${HOME}/Work/xbb-bootstrap-xpack.git/scripts/helper/build.sh --develop --arm64 --arm32
```

or, for development builds:

```sh
sudo rm -rf ~/Work/xbb-bootstrap-*-*
bash ${HOME}/Work/xbb-bootstrap-xpack.git/scripts/helper/build.sh --develop --without-html --disable-tests --arm64 --arm32
```

To detach from the session, use `Ctrl-a` `Ctrl-d`; to reattach use
`screen -r xbb-bootstrap`; to kill the session use `Ctrl-a` `Ctrl-k` and confirm.

About 50 minutes later, the output of the build script is a set of 2
archives and their SHA signatures, created in the `deploy` folder:

```console
$ ls -l ~/Work/xbb-bootstrap-*-*/deploy
total 7120
-rw-rw-rw- 1 ilg ilg 3632743 Mar 26 15:25 xpack-xbb-bootstrap-4.0.0-linux-arm64.tar.gz
-rw-rw-rw- 1 ilg ilg     109 Mar 26 15:25 xpack-xbb-bootstrap-4.0.0-linux-arm64.tar.gz.sha
-rw-rw-rw- 1 ilg ilg 3646739 Mar 26 15:50 xpack-xbb-bootstrap-4.0.0-linux-arm.tar.gz
-rw-rw-rw- 1 ilg ilg     107 Mar 26 15:50 xpack-xbb-bootstrap-4.0.0-linux-arm.tar.gz.sha
```

### Build the macOS binaries

The current platforms for macOS production builds are:

- a macOS 10.13.6 running on a MacBook Pro 2011 with 32 GB of RAM and
  a fast SSD; the machine name is `xbbmi`
- a macOS 11.6.1 running on a Mac Mini M1 2020 with 16 GB of RAM;
  the machine name is `xbbma`

```sh
caffeinate ssh xbbmi
caffeinate ssh xbbma
```

To build the latest macOS version:

```sh
screen -S xbb-bootstrap

rm -rf ~/Work/xbb-bootstrap-*-*
caffeinate bash ${HOME}/Work/xbb-bootstrap-xpack.git/scripts/helper/build.sh --develop --macos
```

or, for development builds:

```sh
rm -rf ~/Work/xbb-bootstrap-arm-*-*
caffeinate bash ${HOME}/Work/xbb-bootstrap-xpack.git/scripts/helper/build.sh --develop --without-html --disable-tests --macos
```

To detach from the session, use `Ctrl-a` `Ctrl-d`; to reattach use
`screen -r xbb-bootstrap`; to kill the session use `Ctrl-a` `Ctrl-\` or
`Ctrl-a` `Ctrl-k` and confirm.

Several minutes later, the output of the build script is a compressed
archive and its SHA signature, created in the `deploy` folder:

```console
$ ls -l ~/Work/xbb-bootstrap-*-*/deploy
total 5536
-rw-r--r--  1 ilg  staff  2828202 Jun 10 17:44 xpack-xbb-bootstrap-4.0.0-darwin-x64.tar.gz
-rw-r--r--  1 ilg  staff      108 Jun 10 17:44 xpack-xbb-bootstrap-4.0.0-darwin-x64.tar.gz.sha
```

## Subsequent runs

### Separate platform specific builds

Instead of `--all`, you can use any combination of:

```console
--linux64
```

On Arm, instead of `--all`, you can use any combination of:

```console
--arm64 --arm32
```

### `clean`

To remove most build temporary files, use:

```sh
bash ${HOME}/Work/xbb-bootstrap-xpack.git/scripts/helper/build.sh --all clean
```

To also remove the library build temporary files, use:

```sh
bash ${HOME}/Work/xbb-bootstrap-xpack.git/scripts/helper/build.sh --all cleanlibs
```

To remove all temporary files, use:

```sh
bash ${HOME}/Work/xbb-bootstrap-xpack.git/scripts/helper/build.sh --all cleanall
```

Instead of `--all`, any combination of `--linux64`
will remove the more specific folders.

For production builds it is recommended to **completely remove the build folder**:

```sh
rm -rf ~/Work/xbb-bootstrap-*-*
```

### `--develop`

For performance reasons, the actual build folders are internal to each
Docker run, and are not persistent. This gives the best speed, but has
the disadvantage that interrupted builds cannot be resumed.

For development builds, it is possible to define the build folders in
the host file system, and resume an interrupted build.

In addition, the builds are more verbose.

### `--debug`

For development builds, it is also possible to create everything with
`-g -O0` and be able to run debug sessions.

### --jobs

By default, the build steps use all available cores. If, for any reason,
parallel builds fail, it is possible to reduce the load.

### Interrupted builds

The Docker scripts may run with root privileges. This is generally not a
problem, since at the end of the script the output files are reassigned
to the actual user.

However, for an interrupted build, this step is skipped, and files in
the install folder will remain owned by root. Thus, before removing
the build folder, it might be necessary to run a recursive `chown`.

## Testing

A simple test is performed by the script at the end, by launching the
executables to check if all shared/dynamic libraries are correctly used.

For a true test you need to unpack the archive in a temporary location
(like `~/Downloads`) and then run the
program from there. For example on macOS the output should
look like:

```console
$ .../xpack-xbb-bootstrap-4.0.0/bin/xxx
...
```

## Installed folders

After install, the package should create a structure like this (macOS files;
only the first two depth levels are shown):

```console
$ tree -L 2 /Users/ilg/Library/xPacks/\@xpack-dev-tools/xbb-bootstrap/4.0.0/.content/
/Users/ilg/Library/xPacks/\@xpack-dev-tools/xbb-bootstrap/4.0.0/.content/
...
```

No other files are installed in any system folders or other locations.

## Uninstall

The binaries are distributed as portable archives; thus they do not need
to run a setup and do not require an uninstall; simply removing the
folder is enough.

## Files cache

The XBB build scripts use a local cache such that files are downloaded only
during the first run, later runs being able to use the cached files.

However, occasionally some servers may not be available, and the builds
may fail.

The workaround is to manually download the files from an alternate
location (like
<https://github.com/xpack-dev-tools/files-cache/tree/master/libs>),
place them in the XBB cache (`Work/cache`) and restart the build.

## More build details

The build process is split into several scripts. The build starts on
the host, with `build.sh`, which runs `container-build.sh` several
times, once for each target, in one of the two docker containers.
Both scripts include several other helper scripts. The entire process
is quite complex, and an attempt to explain its functionality in a few
words would not be realistic. Thus, the authoritative source of details
remains the source code.
