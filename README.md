
[![GitHub release (latest by date)](https://img.shields.io/github/v/release/xpack-dev-tools/xbb-bootstrap-xpack)](https://github.com/xpack-dev-tools/xbb-bootstrap-xpack/releases)
[![npm (scoped)](https://img.shields.io/npm/v/@xpack-dev-tools/xbb-bootstrap.svg)](https://www.npmjs.com/package/@xpack-dev-tools/xbb-bootstrap/)

# The xPack XBB Bootstrap

A standalone cross-platform (macOS/Linux) **XBB Bootstrap**
binary distribution, intended for reproducible builds.

It includes most of the tools available in the XBB Docker v3.4 images,
and is intended to be used to bootstrap the creation of separate
packages with these tools.

In addition to the the binary archives and the package meta data,
this project also includes the build scripts.

## Early deprecation notice

This package is not recommended for new designs. It will be used
as a direct replacement for the Docker images, to build all existing
binary xPacks.

Once the new build scripts are functional, the plan is to move
components out as separate packages, to the point when there will be
no components left, when this package will be retired.

## Overview

This open source project is hosted on GitHub as
[`xpack-dev-tools/xbb-bootstrap-xpack`](https://github.com/xpack-dev-tools/xbb-bootstrap-xpack)
and provides the platform specific binaries for the
[xPack XBB Bootstrap](https://xpack.github.io/xbb-bootstrap/).

The binaries can be installed automatically as **binary xPacks** or manually as
**portable archives**.

## Release schedule

There are no scheduled releases.

## User info

This section is intended as a shortcut for those who plan
to use the XBB Bootstrap binaries. For full details please read the
[xPack XBB](https://xpack.github.io/xbb/) pages.

### Easy install

The easiest way to install XBB Bootstrap is using the **binary xPack**, available as
[`@xpack-dev-tools/xbb-bootstrap`](https://www.npmjs.com/package/@xpack-dev-tools/xbb-bootstrap)
from the [`npmjs.com`](https://www.npmjs.com) registry.

#### Prerequisites

A recent [xpm](https://xpack.github.io/xpm/),
which is a portable [Node.js](https://nodejs.org/) command line application.

It is recommended to update to the latest version with:

```sh
npm install --location=global xpm@latest
```

For details please follow the instructions in the
[xPack install](https://xpack.github.io/install/) page.

#### Install

With the `xpm` tool available, installing
the latest version of the package and adding it as
a dependency for a project is quite easy:

```sh
cd my-project
xpm init # Only at first use.

xpm install @xpack-dev-tools/xbb-bootstrap@latest

ls -l xpacks/.bin
```

This command will:

- install the latest available version,
into the central xPacks store, if not already there
- add symbolic links to the central store
into the local `xpacks/.bin` folder.

The central xPacks store is a platform dependent
folder; check the output of the `xpm` command for the actual
folder used on your platform).
This location is configurable via the environment variable
`XPACKS_STORE_FOLDER`; for more details please check the
[xpm folders](https://xpack.github.io/xpm/folders/) page.

For xPacks aware tools, like the **Eclipse Embedded C/C++ plug-ins**,
it is also possible to install XBB Bootstrap globally, in the user home folder:

```sh
xpm install --global @xpack-dev-tools/xbb-bootstrap@latest
```

#### Uninstall

To remove the links created by xpm in the current project:

```sh
cd my-project

xpm uninstall @xpack-dev-tools/xbb-bootstrap
```

To completely remove the package from the global store:

```sh
xpm uninstall --global @xpack-dev-tools/xbb-bootstrap
```

### Manual install

For all platforms, the **xPack XBB Bootstrap**
binaries are released as portable
archives that can be installed in any location.

The archives can be downloaded from the
GitHub [Releases](https://github.com/xpack-dev-tools/xbb-bootstrap-xpack/releases/)
page.

For more details please read the
[Install](https://xpack.github.io/xbb-bootstrap/install/) page.

### Versioning

The version strings used by the XBB project are semver strings
like `4.0.0`.

## Maintainer info

- [How to build](https://github.com/xpack-dev-tools/xbb-bootstrap-xpack/blob/xpack/README-BUILD.md)
- [How to make new releases](https://github.com/xpack-dev-tools/xbb-bootstrap-xpack/blob/xpack/README-RELEASE.md)
- [Developer info](https://github.com/xpack-dev-tools/xbb-bootstrap-xpack/blob/xpack/README-DEVELOP.md)

## Support

The quick advice for getting support is to use the GitHub
[Discussions](https://github.com/xpack-dev-tools/xbb-bootstrap-xpack/discussions/).

For more details please read the
[Support](https://xpack.github.io/xbb-bootstrap/support/) page.

## License

The original content is released under the
[MIT License](https://opensource.org/licenses/MIT), with all rights
reserved to [Liviu Ionescu](https://github.com/ilg-ul/).

The binary distributions include several open-source components; the
corresponding licenses are available in the installed
`distro-info/licenses` folder.

## Download analytics

- GitHub [`xpack-dev-tools/xbb-bootstrap-xpack`](https://github.com/xpack-dev-tools/xbb-bootstrap-xpack/) repo
  - latest xPack release
[![Github All Releases](https://img.shields.io/github/downloads/xpack-dev-tools/xbb-bootstrap-xpack/latest/total.svg)](https://github.com/xpack-dev-tools/xbb-bootstrap-xpack/releases/)
  - all xPack releases [![Github All Releases](https://img.shields.io/github/downloads/xpack-dev-tools/xbb-bootstrap-xpack/total.svg)](https://github.com/xpack-dev-tools/xbb-bootstrap-xpack/releases/)
  - [individual file counters](https://somsubhra.github.io/github-release-stats/?username=xpack-dev-tools&repository=xbb-bootstrap-xpack) (grouped per release)
- npmjs.com [`@xpack-dev-tools/xbb-bootstrap`](https://www.npmjs.com/package/@xpack-dev-tools/xbb-bootstrap/) xPack
  - latest release, per month
[![npm (scoped)](https://img.shields.io/npm/v/@xpack-dev-tools/xbb-bootstrap.svg)](https://www.npmjs.com/package/@xpack-dev-tools/xbb-bootstrap/)
[![npm](https://img.shields.io/npm/dm/@xpack-dev-tools/xbb-bootstrap.svg)](https://www.npmjs.com/package/@xpack-dev-tools/xbb-bootstrap/)
  - all releases [![npm](https://img.shields.io/npm/dt/@xpack-dev-tools/xbb-bootstrap.svg)](https://www.npmjs.com/package/@xpack-dev-tools/xbb-bootstrap/)

Credit to [Shields IO](https://shields.io) for the badges and to
[Somsubhra/github-release-stats](https://github.com/Somsubhra/github-release-stats)
for the individual file counters.
