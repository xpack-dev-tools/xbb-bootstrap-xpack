# Scripts to test the xPack XBB Bootstrap

The binaries can be available from one of the pre-releases:

- <https://github.com/xpack-dev-tools/pre-releases/releases>

## Download the repo

The test script is part of the xPack XBB Bootstrap:

```sh
rm -rf ${HOME}/Work/xbb-bootstrap-xpack.git; \
git clone \
  --branch xpack-develop \
  https://github.com/xpack-dev-tools/xbb-bootstrap-xpack.git  \
  ${HOME}/Work/xbb-bootstrap-xpack.git; \
git -C ${HOME}/Work/xbb-bootstrap-xpack.git submodule update --init --recursive
```

## Start a local test

To check if XBB Bootstrap starts on the current platform, run a native test:

```sh
bash ${HOME}/Work/xbb-bootstrap-xpack.git/scripts/helper/tests/native-test.sh \
  --base-url "https://github.com/xpack-dev-tools/pre-releases/releases/download/test/"
```

The script stores the downloaded archive in a local cache, and
does not download it again if available locally.

To force a new download, remove the local archive:

```sh
rm -rf ~/Work/cache/xpack-xbb-bootstrap-*-*
```

## Start the GitHub Actions tests

The multi-platform tests run on GitHub Actions; they do not fire on
git commits, but only via a manual POST to the GitHub API.

```sh
bash ${HOME}/Work/xbb-bootstrap-xpack.git/scripts/helper/tests/trigger-workflow-test-prime.sh \
  --branch xpack-develop \
  --base-url "https://github.com/xpack-dev-tools/pre-releases/releases/download/test/"

bash ${HOME}/Work/xbb-bootstrap-xpack.git/scripts/helper/tests/trigger-workflow-test-docker-linux-intel.sh \
  --branch xpack-develop \
  --base-url "https://github.com/xpack-dev-tools/pre-releases/releases/download/test/"

bash ${HOME}/Work/xbb-bootstrap-xpack.git/scripts/helper/tests/trigger-workflow-test-docker-linux-arm.sh \
  --branch xpack-develop \
  --base-url "https://github.com/xpack-dev-tools/pre-releases/releases/download/test/"

```

The results are available at the project
[Actions](https://github.com/xpack-dev-tools/xbb-bootstrap-xpack/actions/) page.
