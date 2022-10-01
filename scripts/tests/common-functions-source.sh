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

function run_tests()
{
  echo
  env | sort

  if [ "${TARGET_PLATFORM}" == "darwin" ]
  then
    test_realpath "${TEST_BIN_PATH}"
  fi

  test_gnutls "${TEST_BIN_PATH}"
  test_patchelf "${TEST_BIN_PATH}"
  test_findutils "${TEST_BIN_PATH}"
  test_gettext "${TEST_BIN_PATH}"
  test_python3 "${TEST_BIN_PATH}"

  test_pkg_config "${TEST_BIN_PATH}"
  test_curl "${TEST_BIN_PATH}"
  test_tar "${TEST_BIN_PATH}"
  test_guile "${TEST_BIN_PATH}"
  test_autogen "${TEST_BIN_PATH}"
  test_coreutils "${TEST_BIN_PATH}"
  test_m4 "${TEST_BIN_PATH}"
  test_gawk "${TEST_BIN_PATH}"
  test_sed "${TEST_BIN_PATH}"
  test_autoconf "${TEST_BIN_PATH}"
  test_automake "${TEST_BIN_PATH}"
  test_patch "${TEST_BIN_PATH}"
  test_diffutils "${TEST_BIN_PATH}"
  test_bison "${TEST_BIN_PATH}"
  test_make "${TEST_BIN_PATH}"
  test_bash "${TEST_BIN_PATH}"
  test_wget "${TEST_BIN_PATH}"
  test_texinfo "${TEST_BIN_PATH}"
  test_dos2unix "${TEST_BIN_PATH}"

  if [ "${TARGET_PLATFORM}" == "darwin" ] && [ "${TARGET_ARCH}" == "arm64" ]
  then
    :
  else
    test_flex "${TEST_BIN_PATH}"
  fi

  test_perl "${TEST_BIN_PATH}"
  test_tcl "${TEST_BIN_PATH}"

  test_p7zip "${TEST_BIN_PATH}"
  test_rhash "${TEST_BIN_PATH}"
  test_re2c "${TEST_BIN_PATH}"
  test_gpg "${TEST_BIN_PATH}"
  test_makedepend "${TEST_BIN_PATH}"
}

function update_image()
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
    run_verbose apt-get -qq install -y libc6-dev libstdc++6 # TODO: get rid of them
  elif [[ ${image_name} == *centos* ]] || [[ ${image_name} == *redhat* ]] || [[ ${image_name} == *fedora* ]]
  then
    run_verbose yum install -y -q git curl tar gzip redhat-lsb-core binutils
    run_verbose yum install -y -q glibc-devel libstdc++-devel # TODO: get rid of them
  elif [[ ${image_name} == *suse* ]]
  then
    run_verbose zypper -q --no-gpg-checks in -y git-core curl tar gzip lsb-release binutils findutils util-linux
    run_verbose zypper -q --no-gpg-checks in -y glibc-devel libstdc++6 # TODO: get rid of them
  elif [[ ${image_name} == *manjaro* ]]
  then
    # run_verbose pacman-mirrors -g
    run_verbose pacman -S -y -q --noconfirm

    # Update even if up to date (-yy) & upgrade (-u).
    # pacman -S -yy -u -q --noconfirm
    run_verbose pacman -S -q --noconfirm --noprogressbar git curl tar gzip lsb-release binutils
    run_verbose pacman -S -q --noconfirm --noprogressbar gcc-libs # TODO: get rid of them
  elif [[ ${image_name} == *archlinux* ]]
  then
    run_verbose pacman -S -y -q --noconfirm

    # Update even if up to date (-yy) & upgrade (-u).
    # pacman -S -yy -u -q --noconfirm
    run_verbose pacman -S -q --noconfirm --noprogressbar git curl tar gzip lsb-release binutils
    run_verbose pacman -S -q --noconfirm --noprogressbar gcc-libs
  fi
}

# -----------------------------------------------------------------------------
