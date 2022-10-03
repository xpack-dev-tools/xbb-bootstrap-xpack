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

### Build the Intel GNU/Linux

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

sudo rm -rf ~/Work/xbb-bootstrap-[0-9]*
bash ${HOME}/Work/xbb-bootstrap-xpack.git/scripts/helper/build.sh --develop --linux64
```

or, for development builds:

```sh
sudo rm -rf ~/Work/xbb-bootstrap-[0-9]*
bash ${HOME}/Work/xbb-bootstrap-xpack.git/scripts/helper/build.sh --develop --without-html --disable-tests --linux64
```

To detach from the session, use `Ctrl-a` `Ctrl-d`; to reattach use
`screen -r xbb-bootstrap`; to kill the session use `Ctrl-a` `Ctrl-k` and confirm.

About 50 minutes later, the output of the build script is an
archive and the SHA signature, created in the `deploy` folder:

```console
$ ls -l ~/Work/xbb-bootstrap-[0-9]*/deploy
total 114108
-rw-rw-rw- 1 ilg ilg 116839844 Oct  3 17:11 xpack-xbb-bootstrap-4.0-linux-x64.tar.gz
-rw-rw-rw- 1 ilg ilg       107 Oct  3 17:11 xpack-xbb-bootstrap-4.0-linux-x64.tar.gz.sha
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

sudo rm -rf ~/Work/xbb-bootstrap-[0-9]*
bash ${HOME}/Work/xbb-bootstrap-xpack.git/scripts/helper/build.sh --develop --arm64 --arm32
```

or, for development builds:

```sh
sudo rm -rf ~/Work/xbb-bootstrap-[0-9]*
bash ${HOME}/Work/xbb-bootstrap-xpack.git/scripts/helper/build.sh --develop --without-html --disable-tests --arm64 --arm32
```

To detach from the session, use `Ctrl-a` `Ctrl-d`; to reattach use
`screen -r xbb-bootstrap`; to kill the session use `Ctrl-a` `Ctrl-k` and confirm.

About 50 minutes later, the output of the build script is a set of 2
archives and their SHA signatures, created in the `deploy` folder:

```console
$ ls -l ~/Work/xbb-bootstrap-[0-9]*/deploy
total 110732
-rw-rw-rw- 1 ilg ilg 113382502 Oct  3 16:33 xpack-xbb-bootstrap-4.0-linux-arm64.tar.gz
-rw-rw-rw- 1 ilg ilg       109 Oct  3 16:33 xpack-xbb-bootstrap-4.0-linux-arm64.tar.gz.sha
```

and

```console
$ ls -l ~/Work/xbb-bootstrap-[0-9]*/deploy
total 105580
-rw-rw-rw- 1 ilg ilg 108106534 Oct  3 17:05 xpack-xbb-bootstrap-4.0-linux-arm.tar.gz
-rw-rw-rw- 1 ilg ilg       107 Oct  3 17:05 xpack-xbb-bootstrap-4.0-linux-arm.tar.gz.sha
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

rm -rf ~/Work/xbb-bootstrap-[0-9]*
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
$ ls -l ~/Work/xbb-bootstrap-[0-9]*/deploy
total 197256
-rw-r--r--  1 ilg  staff  99068411 Oct  3 17:46 xpack-xbb-bootstrap-4.0-darwin-x64.tar.gz
-rw-r--r--  1 ilg  staff       108 Oct  3 17:46 xpack-xbb-bootstrap-4.0-darwin-x64.tar.gz.sha
```

and

```console
$ ls -l ~/Work/xbb-bootstrap-[0-9]*/deploy
total 198408
-rw-r--r--  1 ilg  staff  96533865 Oct  3 17:06 xpack-xbb-bootstrap-4.0-darwin-arm64.tar.gz
-rw-r--r--  1 ilg  staff       110 Oct  3 17:06 xpack-xbb-bootstrap-4.0-darwin-arm64.tar.gz.sha
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
rm -rf ~/Work/xbb-bootstrap-[0-9]*
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
program from there.

## Installed folders

After install, the package should create a structure like this (macOS files;
only the first two depth levels are shown):

```console
$ tree -L 2 /Users/ilg/Library/xPacks/\@xpack-dev-tools/xbb-bootstrap/4.0.0/.content/
/Users/ilg/Library/xPacks/\@xpack-dev-tools/xbb-bootstrap/4.0.0/.content/
├── README.md
├── bin
│   ├── 2to3-3.9
│   ├── 7z
│   ├── 7za
│   ├── 7zr
│   ├── [
│   ├── aclocal
│   ├── aclocal-1.16
│   ├── asn1Coding
│   ├── asn1Decoding
│   ├── asn1Parser
│   ├── autoconf
│   ├── autogen
│   ├── autoheader
│   ├── autom4te
│   ├── automake
│   ├── automake-1.16
│   ├── autoopts-config
│   ├── autoreconf
│   ├── autoscan
│   ├── autoupdate
│   ├── awk -> gawk
│   ├── b2sum
│   ├── base32
│   ├── base64
│   ├── basename
│   ├── basenc
│   ├── bash
│   ├── bashbug
│   ├── bison
│   ├── bunzip2
│   ├── bzcat
│   ├── bzcmp -> bzdiff
│   ├── bzdiff
│   ├── bzegrep -> bzgrep
│   ├── bzfgrep -> bzgrep
│   ├── bzgrep
│   ├── bzip2
│   ├── bzip2recover
│   ├── bzless -> bzmore
│   ├── bzmore
│   ├── c_rehash
│   ├── captoinfo -> tic
│   ├── cat
│   ├── certtool
│   ├── chcon
│   ├── chgrp
│   ├── chmod
│   ├── chown
│   ├── chroot
│   ├── cksum
│   ├── clear
│   ├── cmp
│   ├── columns
│   ├── comm
│   ├── corelist
│   ├── cp
│   ├── cpan
│   ├── cpanm
│   ├── csplit
│   ├── curl
│   ├── curl-config
│   ├── cut
│   ├── date
│   ├── dd
│   ├── df
│   ├── diff
│   ├── diff3
│   ├── dir
│   ├── dircolors
│   ├── dirmngr
│   ├── dirmngr-client
│   ├── dirname
│   ├── dos2unix
│   ├── du
│   ├── echo
│   ├── ed2k-link -> rhash
│   ├── edonr256-hash -> rhash
│   ├── edonr512-hash -> rhash
│   ├── enc2xs
│   ├── encguess
│   ├── env
│   ├── envsubst
│   ├── expand
│   ├── expr
│   ├── factor
│   ├── false
│   ├── flex
│   ├── flex++ -> flex
│   ├── fmt
│   ├── fold
│   ├── gawk
│   ├── gawk-5.1.1
│   ├── getdefs
│   ├── gettext
│   ├── gettext.sh
│   ├── gm4 -> m4
│   ├── gmake
│   ├── gnutar -> tar
│   ├── gnutls-cli
│   ├── gnutls-cli-debug
│   ├── gnutls-serv
│   ├── gost12-256-hash -> rhash
│   ├── gost12-512-hash -> rhash
│   ├── gpg
│   ├── gpg-agent
│   ├── gpg-card
│   ├── gpg-connect-agent
│   ├── gpg-wks-client
│   ├── gpg-wks-server
│   ├── gpgconf
│   ├── gpgparsemail
│   ├── gpgscm
│   ├── gpgsm
│   ├── gpgsplit
│   ├── gpgtar
│   ├── gpgv
│   ├── groups
│   ├── gsed -> sed
│   ├── guild
│   ├── guile
│   ├── guile-config
│   ├── guile-snarf
│   ├── guile-tools -> guild
│   ├── h2ph
│   ├── h2xs
│   ├── has160-hash -> rhash
│   ├── head
│   ├── hostid
│   ├── iconv
│   ├── id
│   ├── idle3.9
│   ├── ifnames
│   ├── info
│   ├── infocmp
│   ├── infotocap -> tic
│   ├── install
│   ├── install-info
│   ├── instmodsh
│   ├── join
│   ├── json_pp
│   ├── kbxutil
│   ├── kill
│   ├── libnetcfg
│   ├── link
│   ├── ln
│   ├── logname
│   ├── ls
│   ├── lzcat -> xz
│   ├── lzcmp -> xzdiff
│   ├── lzdiff -> xzdiff
│   ├── lzegrep -> xzgrep
│   ├── lzfgrep -> xzgrep
│   ├── lzgrep -> xzgrep
│   ├── lzless -> xzless
│   ├── lzma -> xz
│   ├── lzmadec
│   ├── lzmainfo
│   ├── lzmore -> xzmore
│   ├── m4
│   ├── mac2unix -> dos2unix
│   ├── magnet-link -> rhash
│   ├── make -> gmake
│   ├── makedepend
│   ├── makeinfo -> texi2any
│   ├── md5sum
│   ├── mkdir
│   ├── mkfifo
│   ├── mknod
│   ├── mktemp
│   ├── mv
│   ├── ncurses6-config
│   ├── ngettext
│   ├── nice
│   ├── nl
│   ├── nohup
│   ├── nproc
│   ├── numfmt
│   ├── ocsptool
│   ├── od
│   ├── openssl
│   ├── paste
│   ├── patch
│   ├── patchelf
│   ├── pathchk
│   ├── pdftexi2dvi
│   ├── perl
│   ├── perl5.34.0
│   ├── perlbug
│   ├── perldoc
│   ├── perlivp
│   ├── perlthanks
│   ├── piconv
│   ├── pinky
│   ├── pkg-config
│   ├── pkg-config-verbose
│   ├── pl2pm
│   ├── pod2html
│   ├── pod2man
│   ├── pod2texi
│   ├── pod2text
│   ├── pod2usage
│   ├── podchecker
│   ├── pr
│   ├── printenv
│   ├── printf
│   ├── prove
│   ├── psktool
│   ├── ptar
│   ├── ptardiff
│   ├── ptargrep
│   ├── ptx
│   ├── pwd
│   ├── pydoc3.9
│   ├── python3 -> python3.9
│   ├── python3.9
│   ├── python3.9-config
│   ├── re2c
│   ├── re2go
│   ├── readlink
│   ├── realpath
│   ├── reset -> tset
│   ├── rhash
│   ├── rm
│   ├── rmdir
│   ├── runcon
│   ├── sdiff
│   ├── sed
│   ├── seq
│   ├── sfv-hash -> rhash
│   ├── sha1sum
│   ├── sha224sum
│   ├── sha256sum
│   ├── sha384sum
│   ├── sha512sum
│   ├── shasum
│   ├── shred
│   ├── shuf
│   ├── sleep
│   ├── sort
│   ├── splain
│   ├── split
│   ├── sqlite3
│   ├── sqlite3_analyzer
│   ├── srptool
│   ├── stat
│   ├── streamzip
│   ├── stty
│   ├── sum
│   ├── sync
│   ├── tabs
│   ├── tac
│   ├── tail
│   ├── tar
│   ├── tclsh8.6
│   ├── tee
│   ├── test
│   ├── texi2any
│   ├── texi2dvi
│   ├── texi2pdf
│   ├── texindex
│   ├── tic
│   ├── tiger-hash -> rhash
│   ├── timeout
│   ├── toe
│   ├── touch
│   ├── tput
│   ├── tr
│   ├── true
│   ├── truncate
│   ├── tset
│   ├── tsort
│   ├── tth-hash -> rhash
│   ├── tty
│   ├── uname
│   ├── unexpand
│   ├── uniq
│   ├── unix2dos
│   ├── unix2mac -> unix2dos
│   ├── unlink
│   ├── unlzma -> xz
│   ├── unxz -> xz
│   ├── uptime
│   ├── users
│   ├── vdir
│   ├── watchgnupg
│   ├── wc
│   ├── wget
│   ├── whirlpool-hash -> rhash
│   ├── who
│   ├── whoami
│   ├── xml2-config
│   ├── xml2ag
│   ├── xmlcatalog
│   ├── xmllint
│   ├── xsubpp
│   ├── xz
│   ├── xzcat -> xz
│   ├── xzcmp -> xzdiff
│   ├── xzdec
│   ├── xzdiff
│   ├── xzegrep -> xzgrep
│   ├── xzfgrep -> xzgrep
│   ├── xzgrep
│   ├── xzless
│   ├── xzmore
│   ├── yacc
│   ├── yes
│   └── zipdetails
├── distro-info
│   ├── CHANGELOG.md
│   ├── licenses
│   ├── patches
│   └── scripts
├── etc
│   ├── profile.d
│   ├── rhashrc
│   └── wgetrc
├── include
│   └── python3.9
├── lib
│   ├── bash
│   ├── libpython3.9.dylib
│   ├── perl5
│   ├── pkgconfig
│   ├── python3.9
│   ├── tcl8
│   └── tcl8.6
├── libexec
│   ├── awk
│   ├── dirmngr_ldap
│   ├── gpg-check-pattern
│   ├── gpg-pair-tool
│   ├── gpg-preset-passphrase
│   ├── gpg-protect-tool
│   ├── gpg-wks-client
│   ├── keyboxd
│   ├── libassuan.0.dylib
│   ├── libbz2.1.0.8.dylib
│   ├── libcrypt.2.dylib
│   ├── libcrypto.1.1.dylib
│   ├── libcurl.4.dylib
│   ├── libexpat.1.8.1.dylib
│   ├── libexpat.1.dylib -> libexpat.1.8.1.dylib
│   ├── libffi.8.dylib
│   ├── libgc.1.dylib
│   ├── libgcrypt.20.dylib
│   ├── libgmp.10.dylib
│   ├── libgnutls.30.dylib
│   ├── libgpg-error.0.dylib
│   ├── libguile-2.2.1.dylib
│   ├── libhistory.8.1.dylib
│   ├── libhistory.8.dylib -> libhistory.8.1.dylib
│   ├── libhogweed.6.4.dylib
│   ├── libhogweed.6.dylib -> libhogweed.6.4.dylib
│   ├── libiconv.2.dylib
│   ├── libksba.8.dylib
│   ├── libltdl.7.dylib
│   ├── liblzma.5.dylib
│   ├── libmpfr.6.dylib
│   ├── libncurses.6.dylib
│   ├── libnettle.8.4.dylib
│   ├── libnettle.8.dylib -> libnettle.8.4.dylib
│   ├── libnpth.0.dylib
│   ├── libopts.25.dylib
│   ├── libpanel.6.dylib
│   ├── libpython3.9.dylib
│   ├── libreadline.8.1.dylib
│   ├── libreadline.8.dylib -> libreadline.8.1.dylib
│   ├── librhash.0.dylib
│   ├── libsqlite3.0.dylib
│   ├── libssl.1.1.dylib
│   ├── libtasn1.6.dylib
│   ├── libtcl8.6.dylib
│   ├── libunistring.2.dylib
│   ├── libxml2.2.dylib
│   ├── libz.1.2.11.dylib
│   ├── libz.1.dylib -> libz.1.2.11.dylib
│   └── scdaemon
├── sbin
│   ├── addgnupghome
│   └── applygnupgdefaults
└── share
    ├── aclocal
    ├── aclocal-1.16
    ├── autoconf
    ├── autogen
    ├── automake-1.16
    ├── awk
    ├── bison
    ├── gettext
    ├── gnupg
    ├── gtk-doc
    ├── guile
    ├── locale
    ├── pkgconfig
    ├── re2c
    ├── readline
    ├── tabset
    ├── texinfo
    └── util-macros

38 directories, 364 files
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
