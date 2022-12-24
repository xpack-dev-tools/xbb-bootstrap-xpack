# -----------------------------------------------------------------------------
# This file is part of the xPack distribution.
#   (https://xpack.github.io)
# Copyright (c) 2020 Liviu Ionescu.
#
# Permission to use, copy, modify, and/or distribute this software
# for any purpose is hereby granted, under the terms of the MIT license.
# -----------------------------------------------------------------------------

# -----------------------------------------------------------------------------
# Common functions used in various tests.
#
# Requires
# - app_folder_path
# - test_folder_path
# - archive_platform (win32|linux|darwin)

# -----------------------------------------------------------------------------

# TEST_BIN_PATH - folder with the tested binaries
# TESTS_FOLDER_PATH - temporary folder where individual tests are performed

function tests_run_all()
{
  local test_bin_path="$1"

  # Removed, they use absolute paths.
  # autoconf_test "${TEST_BIN_PATH}"
  # autogen_test "${TEST_BIN_PATH}"
  # automake_test "${TEST_BIN_PATH}"

  bash_test "${TEST_BIN_PATH}"
  bison_test "${TEST_BIN_PATH}"
  coreutils_test "${TEST_BIN_PATH}"
  curl_test "${TEST_BIN_PATH}"
  diffutils_test "${TEST_BIN_PATH}"
  dos2unix_test "${TEST_BIN_PATH}"

  if false # [ "${XBB_HOST_PLATFORM}" == "darwin" ] && [ "${XBB_HOST_ARCH}" == "arm64" ]
  then
    :
  else
    : # flex_test "${TEST_BIN_PATH}"
  fi

  gawk_test "${TEST_BIN_PATH}"
  gettext_test "${TEST_BIN_PATH}"
  gnutls_test "${TEST_BIN_PATH}"
  gpg_test "${TEST_BIN_PATH}"

  # Removed, on Linux it fails with --version
  # guile_test "${TEST_BIN_PATH}"

  m4_test "${TEST_BIN_PATH}"
  make_test "${TEST_BIN_PATH}"
  makedepend_test "${TEST_BIN_PATH}"
  p7zip_test "${TEST_BIN_PATH}"
  patch_test "${TEST_BIN_PATH}"
  patchelf_test "${TEST_BIN_PATH}"
  perl_test "${TEST_BIN_PATH}"
  pkg_config_test "${TEST_BIN_PATH}"
  python3_test "${TEST_BIN_PATH}"

  if [ "${XBB_HOST_PLATFORM}" == "darwin" ]
  then
    test_realpath "${TEST_BIN_PATH}"
  fi

  rhash_test "${TEST_BIN_PATH}"
  re2c_test "${TEST_BIN_PATH}"
  test_sed "${TEST_BIN_PATH}"
  tar_test "${TEST_BIN_PATH}"
  tcl_test "${TEST_BIN_PATH}"
  texinfo_test "${TEST_BIN_PATH}"
  wget_test "${TEST_BIN_PATH}"
}

function tests_update_system()
{
  local image_name="$1"

  # Make sure that the minimum prerequisites are met.
  if [[ ${image_name} == github-actions-ubuntu* ]]
  then
    : # sudo apt-get -qq install -y XXX
  elif [[ ${image_name} == *ubuntu* ]] || [[ ${image_name} == *debian* ]] || [[ ${image_name} == *raspbian* ]]
  then
    run_verbose apt-get -qq update
    run_verbose apt-get -qq install -y git-core curl tar gzip lsb-release binutils
    run_verbose apt-get -qq install -y g++ libc6-dev libstdc++6
  elif [[ ${image_name} == *centos* ]] || [[ ${image_name} == *redhat* ]] || [[ ${image_name} == *fedora* ]]
  then
    run_verbose yum install -y -q git curl tar gzip redhat-lsb-core binutils which
    run_verbose yum install -y -q diffutils
    run_verbose yum install -y -q gcc-c++ glibc-devel libstdc++-devel
  elif [[ ${image_name} == *suse* ]]
  then
    run_verbose zypper -q --no-gpg-checks in -y git-core curl tar gzip lsb-release binutils findutils util-linux
    run_verbose zypper -q --no-gpg-checks in -y diffutils
    run_verbose zypper -q --no-gpg-checks in -y gcc-c++ glibc-devel libstdc++6
  elif [[ ${image_name} == *manjaro* ]]
  then
    # run_verbose pacman-mirrors -g
    run_verbose pacman -S -y -q --noconfirm

    # Update even if up to date (-yy) & upgrade (-u).
    # pacman -S -yy -u -q --noconfirm
    run_verbose pacman -S -q --noconfirm --noprogressbar git curl tar gzip lsb-release binutils which
    run_verbose pacman -S -q --noconfirm --noprogressbar diffutils # For cmp
    run_verbose pacman -S -q --noconfirm --noprogressbar gcc gcc-libs
  elif [[ ${image_name} == *archlinux* ]]
  then
    run_verbose pacman -S -y -q --noconfirm

    # Update even if up to date (-yy) & upgrade (-u).
    # pacman -S -yy -u -q --noconfirm
    run_verbose pacman -S -q --noconfirm --noprogressbar git curl tar gzip lsb-release binutils which
    run_verbose pacman -S -q --noconfirm --noprogressbar diffutils # For cmp
    run_verbose pacman -S -q --noconfirm --noprogressbar gcc gcc-libs
  fi
}

# -----------------------------------------------------------------------------
