# Development info

Note: this page may be occasionally out of date.

## Prerequisites

For active development of XBB Bootstrap, the supported environments are macOS and
Ubuntu 18 LTS (native or on top of WSL).

To create these environments, these instructions use the scripts
provided in the separate
[xpack/xpack-build-box](https://github.com/xpack/xpack-build-box) project.

XBB, or _The xPack Build Box_ is a project intended to provide
build environments for the [xPack](https://github.com/xpack) tools.

### macOS

The macOS XBB is a custom set of tools installed in the
`${HOME}/.local/xbb` folder.

To compile and install these tools, please read the separate
[The macOS XBB](https://github.com/xpack/xpack-build-box/tree/master/macos)
page.

The current macOS XBB is based on macOS 10.13. If you manage to build
it on a more recent macOS, please contribute back the changes to the script.

### Ubuntu

The Ubuntu XBB is currently a dedicated Ubuntu Desktop 18 LTS 64-bit virtual
machine running on Parallels. It obviously can run on any virtualisation
platform, or even be a physical machine. However, for consistent and
reproducible results, it is recommended to do not install other packages.

To install it, please read the separate
[The Ubuntu XBB](https://github.com/xpack/xpack-build-box/tree/master/ubuntu)
page.

### Windows

The Windows development environment is based on Windows 10 and the new
[WSL (Windows Subsystem for Linux)](https://docs.microsoft.com/en-us/windows/wsl/install-win10)
subsystem, which allows to install a traditional GNU/Linux distribution on
Windows.

#### Install WSL

To install WSL, open a PowerShell console (mandatory, old CMD consoles do
not work) and issue:

```console
PS> Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux
```

#### Install Ubuntu

Follow the instruction in the
[WSL](https://docs.microsoft.com/en-us/windows/wsl/install-win10)
page and install Ubuntu.

Start the new `ubuntu.exe` (there is also a graphical shortcut).

This step should
[initialise the new distro](https://docs.microsoft.com/en-us/windows/wsl/initialize-distro),
and when completed, ask for the separate UNIX name.
Any name is accepted, but to keep things consistent, preferably use the same
name as for Windows.

When running on a VirtualBox VM, this step may apparently hang, so if the
_Installation successful_ message does not arrive after a few minutes and the
process uses almost no CPU, it probably did hang. In my case it helped to
enter a space.

After installation is completed, it is recommended to update Ubuntu:

```sh
sudo apt --yes update && sudo apt --yes upgrade
```

#### Install the Ubuntu XBB

The next step is to install
[The Ubuntu XBB](https://github.com/xpack/xpack-build-box/tree/master/ubuntu).

#### Create links

The Ubuntu file system is mapped to a folder deep down in the `AppData` folder,
and [its content should not be changed from Windows](https://blogs.msdn.microsoft.com/commandline/2016/11/17/do-not-change-linux-files-using-windows-apps-and-tools/)

However, it is possible for the WSL processes to access the entire Windows
file system, mounted as `/mnt/c`.

For a convenient access, make soft links from the Ubuntu account back to the
Windows account

```sh
mkdir -p /mnt/c/Users/ilg/Work
ln -s /mnt/c/Users/ilg/Work Work
ln -s /mnt/c/Users/ilg/Downloads Downloads
```

#### Install Git

Although Git comes in the Ubuntu distribution, it is useful to have it
available in Windows too.

It can be downloaded from [git-scm.com](https://git-scm.com/download/win).

#### Install GDB

To run debug session on Windows, the tools available in Ubuntu cannot be used,
a Windows `gdb.exe` is needed.

A good candidate is the one packed in the
[MinGW Distro](https://nuwen.net/mingw.html). Get the package without
Git, since you already installed the
most recent Git in the previous step.

Prefer to install in user space, and the default location used in the provided
launchers is `${env:USERPROFILE}/Downloads/MinGW/bin/gdb.exe`.

### Visual Studio Code

The recommended development tool is [Visual Studio Code](https://code.visualstudio.com),
and for it there are already build tasks and debug launchers available
in the `.vscode` folder of the `xpack-dev-tools/xbb-bootstrap` Git project. (to be added)

[Download](https://code.visualstudio.com/Download) and install the
user installer as recommended by Microsoft, and add the
[C/C++ extension](https://code.visualstudio.com/docs/languages/cpp).

Obviously any other editor can be used, but you'll need to recreate
the details of the configuration. Probably a good strategy would be
to first use VSC to get a functional environment, and later migrate
it to your favourite tools.

### Git client

For macOS and Windows, the recommended Git client is
[Fork](https://fork.dev).

Since Fork is not available for GNU/Linux, the second choice is
Git Kraken, which can be downloaded for freely from
[gitkraken.com](https://www.gitkraken.com/download).

This is an optional step and your selection is not relevant for this
project, any other Git client is perfectly ok, even the command line one.

Amongst the alternate solutions are:

- [ungit](https://www.npmjs.com/package/ungit), the easiest way to use git.
  On any platform, since it runs in a browser; available as a `npm` module
- [Fork](https://git-fork.com), a fast and friendly git client for Mac
  and Windows
- etc

## How to use

### Download the build scripts

The build scripts are available in the `scripts` folder of the
[`xpack-dev-tools/xbb-bootstrap-xpack`](https://github.com/xpack-dev-tools/xbb-bootstrap-xpack)
Git repo.

To download them, the following shortcut is available:

```sh
rm -rf ${HOME}/Work/xbb-bootstrap-xpack.git; \
git clone \
  https://github.com/xpack-dev-tools/xbb-bootstrap-xpack.git \
  ${HOME}/Work/xbb-bootstrap-xpack.git; \
git -C ${HOME}/Work/xbb-bootstrap-xpack.git submodule update --init --recursive
```

For more details please read the `README-BUILD.md` file.

### Initial build

To build a binary which is suitable for debug sessions, run the
`build-native.sh` script with the shown options:

```sh
rm -rf ~/Work/xbb-bootstrap-dev

bash ${HOME}/Work/xbb-bootstrap-xpack.git/scripts/helper/build-native.sh --debug --develop
```

To build the Windows binaries, use:

```sh
bash ${HOME}/Work/xbb-bootstrap-xpack.git/scripts/helper/build-native.sh --debug --develop --win
```

The result is the `${HOME}/Work/xbb-bootstrap-dev/${platform}-${arch}` folder. The build
is performed in the separate `build` folder, and the result is installed
in `install`, with the executable in `install/bin`.

### Open xbb-bootstrap.git

The `build-native.sh` script clones the XBB Bootstrap Git repository in a
folder like `${HOME}/Work/xbb-bootstrap-dev/xbb-bootstrap.git`.

Open this folder in VSC; it contains the project source code. (not yet)

If you used the `--develop` option, the development branch is checked out.

### VSC build tasks

There are two build tasks, one to build and one to clean.
To start these tasks, use **Terminal** -> **Run Build Task**, or
**Ctrl+Shift+B**, and select the desired task.

The actual task definitions are in `.vscode/tasks.json`. Both tasks run the
`build-native.sh` script, with different options.

The build options are:

- `--debug`, to preserve the debugging info,
- `--develop`, to use the development repository branch.

### Clean

The `clean` task removes the `build/xbb-bootstrap` and `install/xbb-bootstrap` folders,
in preparation for a new build.

The operation can also be performed manually:

```sh
bash ${HOME}/Work/xbb-bootstrap-xpack.git/scripts/helper/build-native.sh clean
```

To remove the library folders, use:

```sh
bash ${HOME}/Work/xbb-bootstrap-xpack.git/scripts/helper/build-native.sh cleanlibs
```

To remove all:

```sh
bash ${HOME}/Work/xbb-bootstrap-xpack.git/scripts/helper/build-native.sh cleanall
```

### Edit & IntelliSense

VSC is quite convenient for editing the project source files.

For advanced browsing, the `#include` folders are already configured
in `c_cpp_properties.json`, so most definitions should be already
available via IntelliSense.

There are 3 configurations available, for each platform.

To select the one appropriate for your environment, open a C/C++ file and
click the bottom right **C/C++ Configuration** selector; in the
selection window that appears on top, select the desired configuration.

Note: VSC configurations are not available yet; see the QEMU similar
configurations for an example.

#### `HOME` vs `USERPROFILE`

The environment variables used to define the user home folder
are different, on macOS and GNU/Linux it is `${env:HOME}`, while on
Windows it is `${env:USERPROFILE}`.

This generally makes sharing launcher configurations between
platforms more difficult.

#### `sourceFileMap`

For Windows, since the build was performed in the Ubuntu WSL
environment, where paths are below `/home`, it is necessary to
map them back to the `/Users` folder.

Add the following to the launch configurations:

```json
      "sourceFileMap": {
        "/home": "/Users"
      },
```

#### `miDebuggerPath`

Also on Windows, since usually the GDB executable is not in the
system path, it must be explicitly defined, for example as:

```json
      "miDebuggerPath": "${env:USERPROFILE}/Downloads/MinGW/bin/gdb.exe",
```

#### `stopAtEntry`

This option should place a breakpoint in `main()`.

#### `externalConsole`

This option is set differently on each platform. On macOS, the
LLDB plug-in does not interpret properly the process output and
the external console must be enabled to see it.

On Windows the external console is automatically closed when the
debug session is terminated, so it is more convenient to use
the internal console, which remains visible.

## Contributing back to the project

Contributions are welcomed, preferably as GitHub pull requests.

For this, the workflow is:

- fork the [xpack-dev-tools/xbb-bootstrap](https://github.com/xpack-dev-tools/xbb-bootstrap)
  Git project
- clone it to a place of your choice
- create a new branch based on the `xpack-develop` branch
- link the fork folder to `${HOME}/Work/xbb-bootstrap-dev/` instead of the
  existing `xbb-bootstrap.git` folder
- edit-compile-debug until ready
- commit & push the changes, and mark them as pull requests
