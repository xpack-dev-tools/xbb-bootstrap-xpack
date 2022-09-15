# -----------------------------------------------------------------------------
# This file is part of the xPack distribution.
#   (https://xpack.github.io)
# Copyright (c) 2019 Liviu Ionescu.
#
# Permission to use, copy, modify, and/or distribute this software
# for any purpose is hereby granted, under the terms of the MIT license.
# -----------------------------------------------------------------------------

# Helper script used in the second edition of the xPack build
# scripts. As the name implies, it should contain only functions and
# should be included with 'source' by the container build scripts.

# -----------------------------------------------------------------------------

# Minimalistic realpath to be used on macOS
function build_realpath()
{
  # https://github.com/harto/realpath-osx
  # https://github.com/harto/realpath-osx/archive/1.0.0.tar.gz

  # 18 Oct 2012 "1.0.0"

  local realpath_version="$1"

  local realpath_src_folder_name="realpath-osx-${realpath_version}"

  local realpath_archive="${realpath_src_folder_name}.tar.gz"
  # GitHub release archive.
  local realpath_url="https://github.com/harto/realpath-osx/archive/${realpath_version}.tar.gz"

  local realpath_folder_name="${realpath_src_folder_name}"

  local realpath_stamp_file_path="${STAMPS_FOLDER_PATH}/stamp-${realpath_folder_name}-installed"
  if [ ! -f "${realpath_stamp_file_path}" ]
  then

    echo
    echo "realpath in-source building"

    if [ ! -d "${BUILD_FOLDER_PATH}/${realpath_folder_name}" ]
    then
      cd "${BUILD_FOLDER_PATH}"

      download_and_extract "${realpath_url}" "${realpath_archive}" \
        "${realpath_src_folder_name}"

      if [ "${realpath_src_folder_name}" != "${realpath_folder_name}" ]
      then
        mv -v "${realpath_src_folder_name}" "${realpath_folder_name}"
      fi
    fi

    mkdir -pv "${LOGS_FOLDER_PATH}/${realpath_folder_name}"

    (
      cd "${BUILD_FOLDER_PATH}/${realpath_folder_name}"

      # xbb_activate_installed_dev

      CPPFLAGS="${XBB_CPPFLAGS}"
      CFLAGS="${XBB_CFLAGS_NO_W}"
      CXXFLAGS="${XBB_CXXFLAGS_NO_W}"

      LDFLAGS="${XBB_LDFLAGS_APP_STATIC_GCC}"
      if [ "${TARGET_PLATFORM}" == "linux" ]
      then
        LDFLAGS+=" -Wl,-rpath,${LD_LIBRARY_PATH}"
      fi

      export CPPFLAGS
      export CFLAGS
      export CXXFLAGS
      export LDFLAGS

      (
        if [ "${IS_DEVELOP}" == "y" ]
        then
          env | sort
        fi

        echo
        echo "Running realpath make..."

        run_verbose make

        install -v -d "${BINS_INSTALL_FOLDER_PATH}/bin"
        install -v -c -m 644 realpath "${BINS_INSTALL_FOLDER_PATH}/bin"

      ) 2>&1 | tee "${LOGS_FOLDER_PATH}/${realpath_folder_name}/make-output-$(ndate).txt"
    )

    (
      test_realpath
    ) 2>&1 | tee "${LOGS_FOLDER_PATH}/${realpath_folder_name}/test-output-$(ndate).txt"

    hash -r

    touch "${realpath_stamp_file_path}"

  else
    echo "Component realpath already installed."
  fi

  test_functions+=("test_realpath")
}

function test_realpath()
{
  (
    # xbb_activate_installed_bin

    echo
    echo "Checking the realpath binaries shared libraries..."

    show_libs "${TEST_PATH}/bin/realpath"
  )
}

# -----------------------------------------------------------------------------

function build_patchelf()
{
  # https://nixos.org/patchelf.html
  # https://github.com/NixOS/patchelf
  # https://github.com/NixOS/patchelf/releases/
  # https://github.com/NixOS/patchelf/releases/download/0.12/patchelf-0.12.tar.bz2
  # https://github.com/NixOS/patchelf/archive/0.12.tar.gz

  # 2016-02-29, "0.9"
  # 2019-03-28, "0.10"
  # 2020-06-09, "0.11"
  # 2020-08-27, "0.12"
  # 05 Aug 2021, "0.13"
  # 05 Dec 2021, "0.14.3"

  local patchelf_version="$1"

  local patchelf_src_folder_name="patchelf-${patchelf_version}"

  local patchelf_archive="${patchelf_src_folder_name}.tar.bz2"
  # GitHub release archive.
  local patchelf_github_archive="${patchelf_version}.tar.gz"
  local patchelf_url="https://github.com/NixOS/patchelf/archive/${patchelf_github_archive}"

  local patchelf_folder_name="${patchelf_src_folder_name}"

  local patchelf_stamp_file_path="${STAMPS_FOLDER_PATH}/stamp-${patchelf_folder_name}-installed"
  if [ ! -f "${patchelf_stamp_file_path}" ]
  then

    cd "${SOURCES_FOLDER_PATH}"

    download_and_extract "${patchelf_url}" "${patchelf_archive}" \
      "${patchelf_src_folder_name}"

    mkdir -pv "${LOGS_FOLDER_PATH}/${patchelf_folder_name}"

    (
      if [ ! -x "${SOURCES_FOLDER_PATH}/${patchelf_src_folder_name}/configure" ]
      then

        cd "${SOURCES_FOLDER_PATH}/${patchelf_src_folder_name}"

        xbb_activate_installed_bin
        xbb_activate_installed_dev

        run_verbose bash ${DEBUG} "bootstrap.sh"

      fi
    ) 2>&1 | tee "${LOGS_FOLDER_PATH}/${patchelf_folder_name}/autogen-output-$(ndate).txt"

    (
      mkdir -pv "${BUILD_FOLDER_PATH}/${patchelf_folder_name}"
      cd "${BUILD_FOLDER_PATH}/${patchelf_folder_name}"

      xbb_activate_installed_dev

      CPPFLAGS="${XBB_CPPFLAGS}"
      CFLAGS="${XBB_CFLAGS_NO_W}"
      CXXFLAGS="${XBB_CXXFLAGS_NO_W}"
      # Wihtout -static-libstdc++, the bootstrap lib folder is needed to
      # find libstdc++.

      LDFLAGS="${XBB_LDFLAGS_APP_STATIC_GCC}"
      if [ "${TARGET_PLATFORM}" == "linux" ]
      then
        LDFLAGS+=" -Wl,-rpath,${LD_LIBRARY_PATH}"
      fi

      export CPPFLAGS
      export CFLAGS
      export CXXFLAGS
      export LDFLAGS

      if [ ! -f "config.status" ]
      then
        (
          if [ "${IS_DEVELOP}" == "y" ]
          then
            env | sort
          fi

          echo
          echo "Running patchelf configure..."

          if [ "${IS_DEVELOP}" == "y" ]
          then
            run_verbose bash "${SOURCES_FOLDER_PATH}/${patchelf_src_folder_name}/configure" --help
          fi

          config_options=()

          config_options+=("--prefix=${BINS_INSTALL_FOLDER_PATH}")
          config_options+=("--libdir=${LIBS_INSTALL_FOLDER_PATH}/lib")
          config_options+=("--includedir=${LIBS_INSTALL_FOLDER_PATH}/include")
          # config_options+=("--datarootdir=${LIBS_INSTALL_FOLDER_PATH}/share")
          config_options+=("--mandir=${LIBS_INSTALL_FOLDER_PATH}/share/man")

          config_options+=("--build=${BUILD}")
          config_options+=("--host=${HOST}")
          config_options+=("--target=${TARGET}")

          if false # is_linux
          then
            config_options+=("--disable-new-dtags")
          fi

          run_verbose bash ${DEBUG} "${SOURCES_FOLDER_PATH}/${patchelf_src_folder_name}/configure" \
            "${config_options[@]}"

          cp "config.log" "${LOGS_FOLDER_PATH}/${patchelf_folder_name}/config-log-$(ndate).txt"
        ) 2>&1 | tee "${LOGS_FOLDER_PATH}/${patchelf_folder_name}/configure-output-$(ndate).txt"
      fi

      (
        echo
        echo "Running patchelf make..."

        # Build.
        run_verbose make -j ${JOBS}

        # make install-strip
        run_verbose make install

        # Fails.
        # x86_64: FAIL: set-rpath-library.sh (Segmentation fault (core dumped))
        # x86_64: FAIL: set-interpreter-long.sh (Segmentation fault (core dumped))
        # make -C tests -j1 check

      ) 2>&1 | tee "${LOGS_FOLDER_PATH}/${patchelf_folder_name}/make-output-$(ndate).txt"

      copy_license \
        "${SOURCES_FOLDER_PATH}/${patchelf_src_folder_name}" \
        "${patchelf_folder_name}"
    )

    (
      test_patchelf
    ) 2>&1 | tee "${LOGS_FOLDER_PATH}/${patchelf_folder_name}/test-output-$(ndate).txt"

    hash -r

    touch "${patchelf_stamp_file_path}"

  else
    echo "Component patchelf already installed."
  fi

  test_functions+=("test_patchelf")
}

function test_patchelf()
{
  (
    # xbb_activate_installed_bin

    echo
    echo "Checking the patchelf binaries shared libraries..."

    show_libs "${TEST_PATH}/bin/patchelf"

    echo
    echo "Testing if patchelf binaries start properly..."

    run_app "${TEST_PATH}/bin/patchelf" --version
  )
}

# -----------------------------------------------------------------------------

# https://stackoverflow.com/questions/44150871/embeded-python3-6-with-mingw-in-c-fail-on-linking

function build_python3()
{
  # https://www.python.org
  # https://www.python.org/downloads/source/
  # https://www.python.org/ftp/python/
  # https://www.python.org/ftp/python/3.7.3/Python-3.7.3.tar.xz

  # https://github.com/Homebrew/homebrew-core/blob/master/Formula/python@3.10.rb

  # https://archlinuxarm.org/packages/aarch64/python/files/PKGBUILD
  # https://git.archlinux.org/svntogit/packages.git/tree/trunk/PKGBUILD?h=packages/python
  # https://git.archlinux.org/svntogit/packages.git/tree/trunk/PKGBUILD?h=packages/python-pip

  # 2018-12-24, "3.7.2"
  # March 25, 2019, "3.7.3"
  # Dec. 18, 2019, "3.8.1"
  # 17-Aug-2020, "3.7.9"
  # 23-Sep-2020, "3.8.6"
  # May 3, 2021 "3.8.10"
  # May 3, 2021 "3.9.5"
  # Aug. 30, 2021, "3.8.12"
  # Aug. 30, 2021, "3.9.7"
  # Sept. 4, 2021, "3.7.12"
  # 24-Mar-2022, "3.9.12"
  # 23-Mar-2022, "3.10.4"

  local python3_version="$1"

  local python3_version_major=$(echo ${python3_version} | sed -e 's|\([0-9]\)\..*|\1|')
  local python3_version_minor=$(echo ${python3_version} | sed -e 's|\([0-9]\)\.\([0-9][0-9]*\)\..*|\2|')

  PYTHON3_VERSION_MAJOR=$(echo ${python3_version} | sed -e 's|\([0-9]\)\..*|\1|')
  PYTHON3_VERSION_MINOR=$(echo ${python3_version} | sed -e 's|\([0-9]\)\.\([0-9][0-9]*\)\..*|\2|')
  export PYTHON3_VERSION_MAJOR_MINOR=${PYTHON3_VERSION_MAJOR}${PYTHON3_VERSION_MINOR}

  local python3_src_folder_name="Python-${python3_version}"

  # Used in add_python3_syslibs()
  PYTHON3_SRC_FOLDER_NAME=${python3_src_folder_name}

  local python3_archive="${python3_src_folder_name}.tar.xz"
  local python3_url="https://www.python.org/ftp/python/${python3_version}/${python3_archive}"

  local python3_folder_name="python-${python3_version}"

  mkdir -pv "${LOGS_FOLDER_PATH}/${python3_folder_name}"

  local python3_stamp_file_path="${STAMPS_FOLDER_PATH}/stamp-${python3_folder_name}-installed"
  if [ ! -f "${python3_stamp_file_path}" ]
  then

    cd "${SOURCES_FOLDER_PATH}"

    download_and_extract "${python3_url}" "${python3_archive}" \
      "${python3_src_folder_name}"

    (
if false
then
      mkdir -pv "${LIBS_BUILD_FOLDER_PATH}/${python3_folder_name}"
      cd "${LIBS_BUILD_FOLDER_PATH}/${python3_folder_name}"
else
      mkdir -pv "${BUILD_FOLDER_PATH}/${python3_folder_name}"
      cd "${BUILD_FOLDER_PATH}/${python3_folder_name}"
fi

      if [ "${TARGET_PLATFORM}" == "darwin" ] && [[ ${CC} =~ .*gcc.* ]]
      then
        # HACK! GCC chokes on dynamic sizes:
        # error: variably modified ‘bytes’ at file scope
        # char bytes[kAuthorizationExternalFormLength];
        # -DkAuthorizationExternalFormLength=32 not working
        prepare_clang_env ""
      fi

      # To pick the new libraries
      xbb_activate_installed_dev

      CPPFLAGS="${XBB_CPPFLAGS} -I${LIBS_INSTALL_FOLDER_PATH}/include/ncurses"
      CFLAGS="${XBB_CFLAGS_NO_W}"
      CXXFLAGS="${XBB_CXXFLAGS_NO_W}"

      LDFLAGS="${XBB_LDFLAGS_APP_STATIC_GCC}"
      if [ "${TARGET_PLATFORM}" == "linux" ]
      then
        LDFLAGS+=" -Wl,-rpath,${LD_LIBRARY_PATH}"
      elif [ "${TARGET_PLATFORM}" == "darwin" ]
      then
        :
      fi

      if [[ ${CC} =~ .*gcc.* ]]
      then
        # Inspired from Arch; not supported by clang.
        CFLAGS+=" -fno-semantic-interposition"
        CXXFLAGS+=" -fno-semantic-interposition"
        LDFLAGS+=" -fno-semantic-interposition"
      fi

      export CPPFLAGS
      export CFLAGS
      export CXXFLAGS
      export LDFLAGS

      if [ ! -f "config.status" ]
      then
        (
          if [ "${IS_DEVELOP}" == "y" ]
          then
            env | sort
          fi

          echo
          echo "Running python3 configure..."

          if [ "${IS_DEVELOP}" == "y" ]
          then
            run_verbose bash "${SOURCES_FOLDER_PATH}/${python3_src_folder_name}/configure" --help
          fi

          # Fail on macOS:
          # --enable-universalsdk
          # --with-lto

          # "... you should not skip tests when using --enable-optimizations as
          # the data required for profiling is generated by running tests".

          # --enable-optimizations takes too long

          config_options=()

          config_options+=("--prefix=${BINS_INSTALL_FOLDER_PATH}")
          # Exception: use BINS_INSTALL_*.
          config_options+=("--libdir=${BINS_INSTALL_FOLDER_PATH}/lib")
          config_options+=("--includedir=${LIBS_INSTALL_FOLDER_PATH}/include")
          # config_options+=("--datarootdir=${LIBS_INSTALL_FOLDER_PATH}/share")
          config_options+=("--mandir=${LIBS_INSTALL_FOLDER_PATH}/share/man")

          config_options+=("--build=${BUILD}")
          config_options+=("--host=${HOST}")
          config_options+=("--target=${TARGET}")

          config_options+=("--with-universal-archs=${TARGET_BITS}-bit")
          config_options+=("--with-computed-gotos")
          config_options+=("--with-dbmliborder=gdbm:ndbm")

          # From Brew, but better not, allow configure to choose.
          # config_options+=("--with-system-expat")
          # config_options+=("--with-system-ffi")
          # config_options+=("--with-system-libmpdec")

          # config_options+=("--with-openssl=${INSTALL_FOLDER_PATH}")
          config_options+=("--without-ensurepip")
          config_options+=("--without-lto")

          # Create the PythonX.Y.so.
          config_options+=("--enable-shared")

          # config_options+=("--enable-loadable-sqlite-extensions")
          config_options+=("--disable-loadable-sqlite-extensions")

          run_verbose bash ${DEBUG} "${SOURCES_FOLDER_PATH}/${python3_src_folder_name}/configure" \
            "${config_options[@]}"

          cp "config.log" "${LOGS_FOLDER_PATH}/${python3_folder_name}/config-log-$(ndate).txt"
        ) 2>&1 | tee "${LOGS_FOLDER_PATH}/${python3_folder_name}/configure-output-$(ndate).txt"
      fi

      (
        echo
        echo "Running python3 make..."

        # export LD_RUN_PATH="${LIBS_INSTALL_FOLDER_PATH}/lib"

        # Build.
        run_verbose make -j ${JOBS} # build_all

        run_verbose make altinstall

        # Hundreds of tests, take a lot of time.
        # Many failures.
        if false # [ "${WITH_TESTS}" == "y" ]
        then
          run_verbose make -j1 quicktest
        fi

      ) 2>&1 | tee "${LOGS_FOLDER_PATH}/${python3_folder_name}/make-output-$(ndate).txt"
    )

    (
      test_python3
    ) 2>&1 | tee "${LOGS_FOLDER_PATH}/${python3_folder_name}/test-output-$(ndate).txt"

    copy_license \
      "${SOURCES_FOLDER_PATH}/${python3_src_folder_name}" \
      "${python3_folder_name}"

    touch "${python3_stamp_file_path}"

  else
    echo "Component python3 already installed."
  fi

# TODO
    test_functions+=("test_python3")
}

function test_python3()
{
  (
    # xbb_activate_installed_bin

    echo
    echo "Checking the python3 binary shared libraries..."

if false
then
    show_libs "${LIBS_INSTALL_FOLDER_PATH}/bin/python3.${PYTHON3_VERSION_MINOR}"
    if [ -f "${LIBS_INSTALL_FOLDER_PATH}/lib/libpython${PYTHON3_VERSION_MAJOR}.${PYTHON3_VERSION_MINOR}m.${SHLIB_EXT}" ]
    then
      show_libs "${LIBS_INSTALL_FOLDER_PATH}/lib/libpython${PYTHON3_VERSION_MAJOR}.${PYTHON3_VERSION_MINOR}m.${SHLIB_EXT}"
    elif [ -f "${LIBS_INSTALL_FOLDER_PATH}/lib/libpython${PYTHON3_VERSION_MAJOR}.${PYTHON3_VERSION_MINOR}.${SHLIB_EXT}" ]
    then
      show_libs "${LIBS_INSTALL_FOLDER_PATH}/lib/libpython${PYTHON3_VERSION_MAJOR}.${PYTHON3_VERSION_MINOR}.${SHLIB_EXT}"
    fi
else
    show_libs "${TEST_PATH}/bin/python3.${PYTHON3_VERSION_MINOR}"
    if [ -f "${TEST_PATH}/lib/libpython${PYTHON3_VERSION_MAJOR}.${PYTHON3_VERSION_MINOR}m.${SHLIB_EXT}" ]
    then
      show_libs "${TEST_PATH}/lib/libpython${PYTHON3_VERSION_MAJOR}.${PYTHON3_VERSION_MINOR}m.${SHLIB_EXT}"
    elif [ -f "${TEST_PATH}/lib/libpython${PYTHON3_VERSION_MAJOR}.${PYTHON3_VERSION_MINOR}.${SHLIB_EXT}" ]
    then
      show_libs "${TEST_PATH}/lib/libpython${PYTHON3_VERSION_MAJOR}.${PYTHON3_VERSION_MINOR}.${SHLIB_EXT}"
    fi
fi
    echo
    echo "Testing if the python3 binary starts properly..."

    export LD_LIBRARY_PATH="${LIBS_INSTALL_FOLDER_PATH}/lib"
if false
then
    run_app "${LIBS_INSTALL_FOLDER_PATH}/bin/python3.${PYTHON3_VERSION_MINOR}" --version

    run_app "${LIBS_INSTALL_FOLDER_PATH}/bin/python3.${PYTHON3_VERSION_MINOR}" -c 'import sys; print(sys.path)'
    run_app "${LIBS_INSTALL_FOLDER_PATH}/bin/python3.${PYTHON3_VERSION_MINOR}" -c 'import sys; print(sys.prefix)'
else
    run_app "${TEST_PATH}/bin/python3.${PYTHON3_VERSION_MINOR}" --version

    run_app "${TEST_PATH}/bin/python3.${PYTHON3_VERSION_MINOR}" -c 'import sys; print(sys.path)'
    run_app "${TEST_PATH}/bin/python3.${PYTHON3_VERSION_MINOR}" -c 'import sys; print(sys.prefix)'
fi
  )
}

# -----------------------------------------------------------------------------

function build_scons()
{
  # http://scons.org
  # http://prdownloads.sourceforge.net/scons/
  # https://sourceforge.net/projects/scons/files/scons/3.1.2/scons-3.1.2.tar.gz/download
  # https://sourceforge.net/projects/scons/files/latest/download
  # http://prdownloads.sourceforge.net/scons/scons-3.1.2.tar.gz

  # https://archlinuxarm.org/packages/any/scons/files/PKGBUILD
  # https://aur.archlinux.org/cgit/aur.git/tree/PKGBUILD?h=python2-scons

  # 2017-09-16, "3.0.1" (sourceforge)
  # 2019-03-27, "3.0.5" (sourceforge)
  # 2019-08-08, "3.1.1"
  # 2019-12-17, "3.1.2"
  # 2021-01-19, "4.1.0"
  # 2021-08-01, "4.2.0"
  # 2021-11-17, "4.3.0"

  local scons_version="$1"

  # Previous versions used lower case.
  local scons_src_folder_name="SCons-${scons_version}"

  local scons_archive="${scons_src_folder_name}.tar.gz"

  local scons_url
  scons_url="https://sourceforge.net/projects/scons/files/scons/${scons_version}/${scons_archive}"

  local scons_folder_name="scons-${scons_version}"

  local scons_stamp_file_path="${STAMPS_FOLDER_PATH}/stamp-${scons_folder_name}-installed"
  if [ ! -f "${scons_stamp_file_path}" ]
  then

    # In-source build

    if [ ! -d "${BUILD_FOLDER_PATH}/${scons_folder_name}" ]
    then
      cd "${BUILD_FOLDER_PATH}"

      download_and_extract "${scons_url}" "${scons_archive}" \
        "${scons_src_folder_name}"

      if [ "${scons_src_folder_name}" != "${scons_folder_name}" ]
      then
        # Trick to avoid
        # mv: cannot move 'SCons-4.4.0' to a subdirectory of itself, 'scons-4.4.0/SCons-4.4.0'
        mv -v "${scons_src_folder_name}" "${scons_folder_name}-tmp"
        mv -v "${scons_folder_name}-tmp" "${scons_folder_name}"
      fi
    fi

    mkdir -pv "${LOGS_FOLDER_PATH}/${scons_folder_name}"

    (
      cd "${BUILD_FOLDER_PATH}/${scons_folder_name}"

      xbb_activate_installed_dev
      # For Python
      xbb_activate_installed_bin

      CPPFLAGS="${XBB_CPPFLAGS}"
      CFLAGS="${XBB_CFLAGS_NO_W}"
      CXXFLAGS="${XBB_CXXFLAGS_NO_W}"

      LDFLAGS="${XBB_LDFLAGS_APP_STATIC_GCC}"
      if [ "${TARGET_PLATFORM}" == "linux" ]
      then
        LDFLAGS+=" -Wl,-rpath,${LD_LIBRARY_PATH}"
      fi

      export CPPFLAGS
      export CFLAGS
      export CXXFLAGS
      export LDFLAGS

      if [ "${IS_DEVELOP}" == "y" ]
      then
        env | sort
      fi

      echo
      echo "Running scons install..."

      echo
      which python3

      echo
      run_verbose python3 setup.py install \
        --prefix="${BINS_INSTALL_FOLDER_PATH}" \
        \
        --optimize=1 \

    ) 2>&1 | tee "${LOGS_FOLDER_PATH}/${scons_folder_name}/install-output-$(ndate).txt"

    (
      test_scons
    ) 2>&1 | tee "${LOGS_FOLDER_PATH}/${scons_folder_name}/test-output-$(ndate).txt"

    hash -r

    touch "${scons_stamp_file_path}"

  else
    echo "Component scons already installed."
  fi

  test_functions+=("test_scons")
}

function test_scons()
{
  (
    echo
    echo "Testing if scons binaries start properly..."

    run_app "${TEST_PATH}/bin/scons" --version
  )
}

# -----------------------------------------------------------------------------

function build_pkg_config()
{
  # https://www.freedesktop.org/wiki/Software/pkg-config/
  # https://pkgconfig.freedesktop.org/releases/

  # https://archlinuxarm.org/packages/aarch64/pkgconf/files/PKGBUILD
  # https://aur.archlinux.org/cgit/aur.git/tree/PKGBUILD?h=pkg-config-git

  # 2017-03-20, "0.29.2", latest

  local pkg_config_version="$1"

  local pkg_config_src_folder_name="pkg-config-${pkg_config_version}"

  local pkg_config_archive="${pkg_config_src_folder_name}.tar.gz"
  local pkg_config_url="https://pkgconfig.freedesktop.org/releases/${pkg_config_archive}"
  # local pkg_config_url="https://github.com/gnu-mcu-eclipse/files/raw/master/libs/${pkg_config_archive}"

  local pkg_config_folder_name="${pkg_config_src_folder_name}"

  local pkg_config_stamp_file_path="${STAMPS_FOLDER_PATH}/stamp-${pkg_config_folder_name}-installed"
  if [ ! -f "${pkg_config_stamp_file_path}" ]
  then

    cd "${SOURCES_FOLDER_PATH}"

    download_and_extract "${pkg_config_url}" "${pkg_config_archive}" \
      "${pkg_config_src_folder_name}"

    mkdir -pv "${LOGS_FOLDER_PATH}/${pkg_config_folder_name}"

    (
      mkdir -pv "${BUILD_FOLDER_PATH}/${pkg_config_folder_name}"
      cd "${BUILD_FOLDER_PATH}/${pkg_config_folder_name}"

      if [ "${TARGET_PLATFORM}" == "darwin" ] && [[ ${CC} =~ .*gcc.* ]]
      then
        # error: variably modified 'bytes' at file scope
        prepare_clang_env ""
      fi

      xbb_activate_installed_dev

      CPPFLAGS="${XBB_CPPFLAGS}"
      CFLAGS="${XBB_CFLAGS_NO_W}"
      CXXFLAGS="${XBB_CXXFLAGS_NO_W}"

      LDFLAGS="${XBB_LDFLAGS_APP_STATIC_GCC}"
      if [ "${TARGET_PLATFORM}" == "linux" ]
      then
        LDFLAGS+=" -Wl,-rpath,${LD_LIBRARY_PATH}"
      fi

      export CPPFLAGS
      export CFLAGS
      export CXXFLAGS
      export LDFLAGS

      if [ ! -f "config.status" ]
      then
        (
          if [ "${IS_DEVELOP}" == "y" ]
          then
            env | sort
          fi

          echo
          echo "Running pkg_config configure..."

          if [ "${IS_DEVELOP}" == "y" ]
          then
            run_verbose bash "${SOURCES_FOLDER_PATH}/${pkg_config_src_folder_name}/configure" --help
            run_verbose bash "${SOURCES_FOLDER_PATH}/${pkg_config_src_folder_name}/glib/configure" --help
          fi

          config_options=()

          config_options+=("--prefix=${BINS_INSTALL_FOLDER_PATH}")
          config_options+=("--libdir=${LIBS_INSTALL_FOLDER_PATH}/lib")
          config_options+=("--includedir=${LIBS_INSTALL_FOLDER_PATH}/include")
          # config_options+=("--datarootdir=${LIBS_INSTALL_FOLDER_PATH}/share")
          config_options+=("--mandir=${LIBS_INSTALL_FOLDER_PATH}/share/man")

          config_options+=("--build=${BUILD}")
          config_options+=("--host=${HOST}")
          config_options+=("--target=${TARGET}")

          config_options+=("--with-internal-glib")
          config_options+=("--with-pc-path=\"\"")

          config_options+=("--disable-debug")
          config_options+=("--disable-host-tool")

          # --with-internal-glib fails with
          # gconvert.c:61:2: error: #error GNU libiconv not in use but included iconv.h is from libiconv
          run_verbose bash ${DEBUG} "${SOURCES_FOLDER_PATH}/${pkg_config_src_folder_name}/configure" \
            "${config_options[@]}"

          cp "config.log" "${LOGS_FOLDER_PATH}/${pkg_config_folder_name}/config-log-$(ndate).txt"
        ) 2>&1 | tee "${LOGS_FOLDER_PATH}/${pkg_config_folder_name}/configure-output-$(ndate).txt"
      fi

      (
        echo
        echo "Running pkg_config make..."

        # Build.
        run_verbose make -j ${JOBS}

        # make install-strip
        run_verbose make install-exec

        if [ "${WITH_TESTS}" == "y" ]
        then
          run_verbose make -j1 check
        fi

      ) 2>&1 | tee "${LOGS_FOLDER_PATH}/${pkg_config_folder_name}/make-output-$(ndate).txt"

      copy_license \
        "${SOURCES_FOLDER_PATH}/${pkg_config_src_folder_name}" \
        "${pkg_config_folder_name}"
    )

    (
      test_pkg_config
    ) 2>&1 | tee "${LOGS_FOLDER_PATH}/${pkg_config_folder_name}/test-output-$(ndate).txt"

    hash -r

    touch "${pkg_config_stamp_file_path}"

  else
    echo "Component pkg_config already installed."
  fi

  test_functions+=("test_pkg_config")
}

function test_pkg_config()
{
  (
    # xbb_activate_installed_bin

    echo
    echo "Checking the pkg_config binaries shared libraries..."

    show_libs "${TEST_PATH}/bin/pkg-config"

    echo
    echo "Testing if pkg_config binaries start properly..."

    run_app "${TEST_PATH}/bin/pkg-config" --version
  )
}

# -----------------------------------------------------------------------------

function build_curl()
{
  # https://curl.haxx.se
  # https://curl.haxx.se/download/
  # https://curl.haxx.se/download/curl-7.64.1.tar.xz

  # https://archlinuxarm.org/packages/aarch64/curl/files/PKGBUILD
  # https://aur.archlinux.org/cgit/aur.git/tree/PKGBUILD?h=curl-git

  # https://github.com/Homebrew/homebrew-core/blob/master/Formula/curl.rb

  # 2017-10-23, "7.56.1"
  # 2017-11-29, "7.57.0"
  # 2019-03-27, "7.64.1"
  # 2019-11-06, "7.67.0"
  # 2020-01-08, "7.68.0"
  # May 26 2021, "7.77.0"
  # Nov 10, 2021, "7.80.0"

  local curl_version="$1"

  local curl_src_folder_name="curl-${curl_version}"

  local curl_archive="${curl_src_folder_name}.tar.xz"
  local curl_url="https://curl.haxx.se/download/${curl_archive}"

  local curl_folder_name="curl-${curl_version}"

  local curl_stamp_file_path="${STAMPS_FOLDER_PATH}/stamp-${curl_folder_name}-installed"
  if [ ! -f "${curl_stamp_file_path}" ]
  then

    cd "${SOURCES_FOLDER_PATH}"

    download_and_extract "${curl_url}" "${curl_archive}" \
      "${curl_src_folder_name}"

    mkdir -pv "${LOGS_FOLDER_PATH}/${curl_folder_name}"

    (
      mkdir -pv "${BUILD_FOLDER_PATH}/${curl_folder_name}"
      cd "${BUILD_FOLDER_PATH}/${curl_folder_name}"

      xbb_activate_installed_dev

      CPPFLAGS="${XBB_CPPFLAGS}"
      CFLAGS="${XBB_CFLAGS_NO_W}"
      CXXFLAGS="${XBB_CXXFLAGS_NO_W}"

      LDFLAGS="${XBB_LDFLAGS_APP_STATIC_GCC}"
      if [ "${TARGET_PLATFORM}" == "linux" ]
      then
        LDFLAGS+=" -Wl,-rpath,${LD_LIBRARY_PATH}"
      fi

      export CPPFLAGS
      export CFLAGS
      export CXXFLAGS
      export LDFLAGS

      if [ ! -f "config.status" ]
      then
        (
          if [ "${IS_DEVELOP}" == "y" ]
          then
            env | sort
          fi

          echo
          echo "Running curl configure..."

          if [ "${IS_DEVELOP}" == "y" ]
          then
            run_verbose bash "${SOURCES_FOLDER_PATH}/${curl_src_folder_name}/configure" --help
          fi

          # HomeBrew options failed:
          # --with-secure-transport
          # --without-libpsl
          # --disable-silent-rules

          config_options=()

          config_options+=("--prefix=${BINS_INSTALL_FOLDER_PATH}")
          config_options+=("--libdir=${LIBS_INSTALL_FOLDER_PATH}/lib")
          config_options+=("--includedir=${LIBS_INSTALL_FOLDER_PATH}/include")
          # config_options+=("--datarootdir=${LIBS_INSTALL_FOLDER_PATH}/share")
          config_options+=("--mandir=${LIBS_INSTALL_FOLDER_PATH}/share/man")

          config_options+=("--build=${BUILD}")
          config_options+=("--host=${HOST}")
          config_options+=("--target=${TARGET}")

          config_options+=("--with-gssapi")
#          config_options+=("--with-ca-bundle=${BINS_INSTALL_FOLDER_PATH}/openssl/ca-bundle.crt")
          config_options+=("--with-ssl")

          config_options+=("--enable-optimize")
          config_options+=("--enable-versioned-symbols")
          config_options+=("--enable-threaded-resolver")
          config_options+=("--disable-manual")
          config_options+=("--disable-ldap")
          config_options+=("--disable-ldaps")
          config_options+=("--disable-werror")
          config_options+=("--disable-warnings")
          config_options+=("--disable-debug")

          run_verbose bash ${DEBUG} "${SOURCES_FOLDER_PATH}/${curl_src_folder_name}/configure" \
            "${config_options[@]}"

          cp "config.log" "${LOGS_FOLDER_PATH}/${curl_folder_name}/config-log-$(ndate).txt"
        ) 2>&1 | tee "${LOGS_FOLDER_PATH}/${curl_folder_name}/configure-output-$(ndate).txt"
      fi

      (
        echo
        echo "Running curl make..."

        # Build.
        run_verbose make -j ${JOBS}

        run_verbose make install-exec

        if false # [ "${WITH_TESTS}" == "y" ]
        then
          # It takes very long (1200+ tests).
          if is_darwin
          then
            run_verbose make -j1 check || true
          else
            run_verbose make -j1 check
          fi
        fi

      ) 2>&1 | tee "${LOGS_FOLDER_PATH}/${curl_folder_name}/make-output-$(ndate).txt"

      copy_license \
        "${SOURCES_FOLDER_PATH}/${curl_src_folder_name}" \
        "${curl_folder_name}"
    )

    (
      test_curl
    ) 2>&1 | tee "${LOGS_FOLDER_PATH}/${curl_folder_name}/test-output-$(ndate).txt"

    touch "${curl_stamp_file_path}"

  else
    echo "Component curl already installed."
  fi

  test_functions+=("test_curl")
}

function test_curl()
{
  (
    # xbb_activate_installed_bin

    echo
    echo "Checking the curl shared libraries..."

    show_libs "${TEST_PATH}/bin/curl"

    echo
    echo "Testing if curl binaries start properly..."

    run_app "${TEST_PATH}/bin/curl" --version

    run_app "${TEST_PATH}/bin/curl" \
      -L https://github.com/xpack-dev-tools/content/raw/master/README.md \
      --output test-output.md
  )
}

# -----------------------------------------------------------------------------

function build_tar()
{
  # https://www.gnu.org/software/tar/
  # https://ftp.gnu.org/gnu/tar/

  # https://archlinuxarm.org/packages/aarch64/tar/files/PKGBUILD
  # https://aur.archlinux.org/cgit/aur.git/tree/PKGBUILD?h=tar-git

  # 2016-05-16 "1.29"
  # 2017-12-17 "1.30"
  # 2019-02-23 "1.32"
  # 2021-02-13, "1.34"

  local tar_version="$1"

  local tar_src_folder_name="tar-${tar_version}"

  local tar_archive="${tar_src_folder_name}.tar.xz"
  local tar_url="https://ftp.gnu.org/gnu/tar/${tar_archive}"

  local tar_folder_name="${tar_src_folder_name}"

  local tar_stamp_file_path="${STAMPS_FOLDER_PATH}/stamp-${tar_folder_name}-installed"
  if [ ! -f "${tar_stamp_file_path}" ]
  then

    # In-source build, to patch out tests.

    if [ ! -d "${BUILD_FOLDER_PATH}/${tar_folder_name}" ]
    then
      cd "${BUILD_FOLDER_PATH}"

      download_and_extract "${tar_url}" "${tar_archive}" \
        "${tar_src_folder_name}"

      if [ "${tar_src_folder_name}" != "${tar_folder_name}" ]
      then
        mv -v "${tar_src_folder_name}" "${tar_folder_name}"
      fi
    fi

    mkdir -pv "${LOGS_FOLDER_PATH}/${tar_folder_name}"

    (
      mkdir -pv "${BUILD_FOLDER_PATH}/${tar_folder_name}"
      cd "${BUILD_FOLDER_PATH}/${tar_folder_name}"

      xbb_activate_installed_dev

      CPPFLAGS="${XBB_CPPFLAGS}"
      CFLAGS="${XBB_CFLAGS_NO_W}"
      CXXFLAGS="${XBB_CXXFLAGS_NO_W}"

      LDFLAGS="${XBB_LDFLAGS_APP_STATIC_GCC}"
      if [ "${TARGET_PLATFORM}" == "linux" ]
      then
        LDFLAGS+=" -Wl,-rpath,${LD_LIBRARY_PATH}"
      fi

      export CPPFLAGS
      export CFLAGS
      export CXXFLAGS
      export LDFLAGS

      # Avoid 'configure: error: you should not run configure as root'.
      # export FORCE_UNSAFE_CONFIGURE=1

      if [ ! -f "config.status" ]
      then
        (
          if [ "${IS_DEVELOP}" == "y" ]
          then
            env | sort
          fi

          echo
          echo "Running tar configure..."

          if [ "${IS_DEVELOP}" == "y" ]
          then
          run_verbose bash "configure" --help
          fi

          config_options=()

          config_options+=("--prefix=${BINS_INSTALL_FOLDER_PATH}")
          config_options+=("--libdir=${LIBS_INSTALL_FOLDER_PATH}/lib")
          config_options+=("--includedir=${LIBS_INSTALL_FOLDER_PATH}/include")
          # config_options+=("--datarootdir=${LIBS_INSTALL_FOLDER_PATH}/share")
          config_options+=("--mandir=${LIBS_INSTALL_FOLDER_PATH}/share/man")

          config_options+=("--build=${BUILD}")
          config_options+=("--host=${HOST}")
          config_options+=("--target=${TARGET}")

          run_verbose bash ${DEBUG} "configure" \
            "${config_options[@]}"

          cp "config.log" "${LOGS_FOLDER_PATH}/${tar_folder_name}/config-log-$(ndate).txt"
        ) 2>&1 | tee "${LOGS_FOLDER_PATH}/${tar_folder_name}/configure-output-$(ndate).txt"
      fi

      (
        echo
        echo "Running tar make..."

        # Build.
        run_verbose make -j ${JOBS}

        # make install-strip
        run_verbose make install-exec

        (
          echo
          echo "Linking gnutar..."
          cd "${BINS_INSTALL_FOLDER_PATH}/bin"
          rm -fv gnutar
          ln -sv tar gnutar
        )

        # It takes very long (220 tests).
        # arm64: 118: explicitly named directory removed before reading FAILED (dirrem02.at:34)
        # amd64: 92: link mismatch FAILED (difflink.at:19)
        # 10.15
        # darwin: 92: link mismatch FAILED (difflink.at:19)
        # darwin: 175: remove-files with compression FAILED (remfiles01.at:32)
        # darwin: 176: remove-files with compression: grand-child FAILED (remfiles02.at:32)
        # 10.10
        # darwin: 172: sparse file truncated while archiving           FAILED (sptrcreat.at:36)
        # darwin: 173: file truncated in sparse region while comparing FAILED (sptrdiff00.at:30)
        # darwin: 174: file truncated in data region while comparing   FAILED (sptrdiff01.at:30)

        if [ "${WITH_TESTS}" == "y" ]
        then
          # TODO: remove tests on darwin
          if false # is_linux && [ "${RUN_LONG_TESTS}" == "y" ]
          then
            # WARN-TEST
            run_verbose make -j1 check # || true
          fi
        fi

      ) 2>&1 | tee "${LOGS_FOLDER_PATH}/${tar_folder_name}/make-output-$(ndate).txt"

      copy_license \
        "${BUILD_FOLDER_PATH}/${tar_folder_name}" \
        "${tar_folder_name}"
    )

    (
      test_tar
    ) 2>&1 | tee "${LOGS_FOLDER_PATH}/${tar_folder_name}/test-output-$(ndate).txt"

    hash -r

    touch "${tar_stamp_file_path}"

  else
    echo "Component tar already installed."
  fi

  test_functions+=("test_tar")
}

function test_tar()
{
  (
    # xbb_activate_installed_bin

    echo
    echo "Checking the tar shared libraries..."

    show_libs "${TEST_PATH}/bin/tar"

    echo
    echo "Testing if tar binaries start properly..."

    run_app "${TEST_PATH}/bin/tar" --version
  )
}

# -----------------------------------------------------------------------------


function build_libtool()
{
  # https://www.gnu.org/software/libtool/
  # http://ftpmirror.gnu.org/libtool/
  # http://ftpmirror.gnu.org/libtool/libtool-2.4.6.tar.xz

  # https://archlinuxarm.org/packages/aarch64/libtool/files/PKGBUILD
  # https://aur.archlinux.org/cgit/aur.git/tree/PKGBUILD?h=libtool-git

  # https://github.com/Homebrew/homebrew-core/blob/master/Formula/libtool.rb

  # 15-Feb-2015, "2.4.6", latest

  local libtool_version="$1"

  local step
  if [ $# -ge 2 ]
  then
    step="$2"
  else
    step=""
  fi

  local libtool_src_folder_name="libtool-${libtool_version}"

  local libtool_archive="${libtool_src_folder_name}.tar.xz"
  local libtool_url="http://ftp.hosteurope.de/mirror/ftp.gnu.org/gnu/libtool/${libtool_archive}"

  local libtool_folder_name="libtool${step}-${libtool_version}"

  local libtool_patch_file_path="${helper_folder_path}/patches/${libtool_folder_name}.patch"

  local libtool_stamp_file_path="${STAMPS_FOLDER_PATH}/stamp-${libtool_folder_name}-installed"
  if [ ! -f "${libtool_stamp_file_path}" ]
  then

    cd "${SOURCES_FOLDER_PATH}"

    download_and_extract "${libtool_url}" "${libtool_archive}" \
      "${libtool_src_folder_name}" "${libtool_patch_file_path}"

    mkdir -pv "${LOGS_FOLDER_PATH}/${libtool_folder_name}"

    (
      mkdir -pv "${BUILD_FOLDER_PATH}/${libtool_folder_name}"
      cd "${BUILD_FOLDER_PATH}/${libtool_folder_name}"

      xbb_activate_installed_bin
      # The new CC was set before the call.
      xbb_activate_installed_dev

      CPPFLAGS="${XBB_CPPFLAGS}"
      CFLAGS="${XBB_CFLAGS_NO_W}"
      CXXFLAGS="${XBB_CXXFLAGS_NO_W}"

      LDFLAGS="${XBB_LDFLAGS_APP_STATIC_GCC}"
      if [ "${TARGET_PLATFORM}" == "linux" ]
      then
        LDFLAGS+=" -Wl,-rpath,${LD_LIBRARY_PATH}"
      fi

      export CPPFLAGS
      export CFLAGS
      export CXXFLAGS
      export LDFLAGS

      if [ ! -f "config.status" ]
      then
        (
          if [ "${IS_DEVELOP}" == "y" ]
          then
            env | sort
          fi

          echo
          echo "Running libtool configure..."

          if [ "${IS_DEVELOP}" == "y" ]
          then
            run_verbose bash "${SOURCES_FOLDER_PATH}/${libtool_src_folder_name}/configure" --help
          fi

          # From HomeBrew: Ensure configure is happy with the patched files
          for f in aclocal.m4 libltdl/aclocal.m4 Makefile.in libltdl/Makefile.in config-h.in libltdl/config-h.in configure libltdl/configure
          do
            touch "${SOURCES_FOLDER_PATH}/${libtool_src_folder_name}/$f"
          done

          config_options=()

          config_options+=("--prefix=${BINS_INSTALL_FOLDER_PATH}")
          config_options+=("--libdir=${LIBS_INSTALL_FOLDER_PATH}/lib")
          config_options+=("--includedir=${LIBS_INSTALL_FOLDER_PATH}/include")
          # config_options+=("--datarootdir=${LIBS_INSTALL_FOLDER_PATH}/share")
          config_options+=("--mandir=${LIBS_INSTALL_FOLDER_PATH}/share/man")

          config_options+=("--build=${BUILD}")
          config_options+=("--host=${HOST}")
          config_options+=("--target=${TARGET}")

          config_options+=("--enable-ltdl-install")

          run_verbose bash ${DEBUG} "${SOURCES_FOLDER_PATH}/${libtool_src_folder_name}/configure" \
            "${config_options[@]}"

          cp "config.log" "${LOGS_FOLDER_PATH}/${libtool_folder_name}/config-log-$(ndate).txt"
        ) 2>&1 | tee "${LOGS_FOLDER_PATH}/${libtool_folder_name}/configure-output-$(ndate).txt"
      fi

      (
        echo
        echo "Running libtool make..."

        # Build.
        run_verbose make -j ${JOBS}

        # make install-strip
        run_verbose make install

        (
          echo
          echo "Linking glibtool..."
          cd "${BINS_INSTALL_FOLDER_PATH}/bin"
          rm -fv glibtool glibtoolize
          ln -sv libtool glibtool
          ln -sv libtoolize glibtoolize
        )

        # amd64: ERROR: 139 tests were run,
        # 11 failed (5 expected failures).
        # 31 tests were skipped.
        # It takes too long (170 tests).
        if false # [ "${RUN_LONG_TESTS}" == "y" ]
        then
          make -j1 check gl_public_submodule_commit=
        fi

      ) 2>&1 | tee "${LOGS_FOLDER_PATH}/${libtool_folder_name}/make-output-$(ndate).txt"

      copy_license \
        "${SOURCES_FOLDER_PATH}/${libtool_src_folder_name}" \
        "${libtool_folder_name}"
    )

    (
      test_libtool
    ) 2>&1 | tee "${LOGS_FOLDER_PATH}/${libtool_folder_name}/test-output-$(ndate).txt"

    hash -r

    touch "${libtool_stamp_file_path}"

  else
    echo "Component libtool already installed."
  fi

  if [ -z "${step}" ]
  then
    test_functions+=("test_libtool")
  fi
}

function test_libtool()
{
  (
    # xbb_activate_installed_bin

    echo
    echo "Checking the libtool shared libraries..."

    show_libs "$(realpath ${LIBS_INSTALL_FOLDER_PATH}/lib/libltdl.${SHLIB_EXT})"

    echo
    echo "Testing if libtool binaries start properly..."

    run_app "${TEST_PATH}/bin/libtool" --version

    echo
    echo "Testing if libtool binaries display help..."

    run_app "${TEST_PATH}/bin/libtool" --help
  )
}

# -----------------------------------------------------------------------------

function build_guile()
{
  # https://www.gnu.org/software/guile/
  # https://ftp.gnu.org/gnu/guile/

  # https://archlinuxarm.org/packages/aarch64/guile/files/PKGBUILD
  # https://github.com/Homebrew/homebrew-core/blob/master/Formula/guile.rb
  # https://github.com/Homebrew/homebrew-core/blob/master/Formula/guile@2.rb

  # 2020-03-07, "2.2.7"
  # Note: for non 2.2, update the tests!
  # 2020-03-08, "3.0.1"
  # 2021-05-10, "3.0.7"

  local guile_version="$1"

  local guile_src_folder_name="guile-${guile_version}"

  local guile_archive="${guile_src_folder_name}.tar.xz"
  local guile_url="https://ftp.gnu.org/gnu/guile/${guile_archive}"

  local guile_folder_name="${guile_src_folder_name}"

  local guile_stamp_file_path="${STAMPS_FOLDER_PATH}/stamp-${guile_folder_name}-installed"
  if [ ! -f "${guile_stamp_file_path}" ]
  then

    cd "${SOURCES_FOLDER_PATH}"

    download_and_extract "${guile_url}" "${guile_archive}" \
      "${guile_src_folder_name}"

    mkdir -pv "${LOGS_FOLDER_PATH}/${guile_folder_name}"

    (
      mkdir -pv "${BUILD_FOLDER_PATH}/${guile_folder_name}"
      cd "${BUILD_FOLDER_PATH}/${guile_folder_name}"

      xbb_activate_installed_dev

      CPPFLAGS="${XBB_CPPFLAGS}"
      CFLAGS="${XBB_CFLAGS_NO_W}"
      CXXFLAGS="${XBB_CXXFLAGS_NO_W}"

      LDFLAGS="${XBB_LDFLAGS_APP_STATIC_GCC}"
      if [ "${TARGET_PLATFORM}" == "linux" ]
      then
        LDFLAGS+=" -Wl,-rpath,${LD_LIBRARY_PATH}"
      fi

      # Otherwise guile-config displays the verbosity.
      unset PKG_CONFIG

      if [ "${TARGET_PLATFORM}" == "linux" ]
      then
        export LD_LIBRARY_PATH="${XBB_LIBRARY_PATH}:${BUILD_FOLDER_PATH}/${guile_folder_name}/libguile/.libs"
      fi

      export CPPFLAGS
      export CFLAGS
      export CXXFLAGS
      export LDFLAGS

      if [ ! -f "config.status" ]
      then
        (
          if [ "${IS_DEVELOP}" == "y" ]
          then
            env | sort
          fi

          echo
          echo "Running guile configure..."

          if [ "${IS_DEVELOP}" == "y" ]
          then
          run_verbose bash "${SOURCES_FOLDER_PATH}/${guile_src_folder_name}/configure" --help
          fi

          config_options=()

          config_options+=("--prefix=${BINS_INSTALL_FOLDER_PATH}")
          config_options+=("--libdir=${LIBS_INSTALL_FOLDER_PATH}/lib")
          config_options+=("--includedir=${LIBS_INSTALL_FOLDER_PATH}/include")
          # config_options+=("--datarootdir=${LIBS_INSTALL_FOLDER_PATH}/share")
          config_options+=("--mandir=${LIBS_INSTALL_FOLDER_PATH}/share/man")

          config_options+=("--build=${BUILD}")
          config_options+=("--host=${HOST}")
          config_options+=("--target=${TARGET}")

          config_options+=("--disable-error-on-warning")

          run_verbose bash ${DEBUG} "${SOURCES_FOLDER_PATH}/${guile_src_folder_name}/configure" \
            "${config_options[@]}"

if false
then
          # FAIL: test-out-of-memory
          # https://lists.gnu.org/archive/html/guile-user/2017-11/msg00062.html
          # Remove the failing test.
          run_verbose sed -i.bak \
            -e 's|test-out-of-memory||g' \
            "test-suite/standalone/Makefile"

          if is_darwin
          then
            # ERROR: posix.test: utime: AT_SYMLINK_NOFOLLOW - arguments: ((out-of-range "utime" "Value out of range: ~S" (32) (32)))
            # Not effective, tests disabled.
            run_verbose sed -i.bak \
              -e 's|tests/posix.test||' \
              "test-suite/Makefile"
          fi
fi

          cp "config.log" "${LOGS_FOLDER_PATH}/${guile_folder_name}/config-log-$(ndate).txt"
        ) 2>&1 | tee "${LOGS_FOLDER_PATH}/${guile_folder_name}/configure-output-$(ndate).txt"
      fi

      (
        echo
        echo "Running guile make..."

        # Build.
        # Requires GC with dynamic load support.
        run_verbose make -j ${JOBS}

        # make install-strip
        run_verbose make install

        if false # [ "${RUN_TESTS}" == "y" ]
        then
          if is_darwin
          then
            # WARN-TEST
            run_verbose make -j1 check || true
          else
            # WARN-TEST
            run_verbose make -j1 check || true
          fi
        fi

      ) 2>&1 | tee "${LOGS_FOLDER_PATH}/${guile_folder_name}/make-output-$(ndate).txt"

      copy_license \
        "${SOURCES_FOLDER_PATH}/${guile_src_folder_name}" \
        "${guile_folder_name}"
    )

    (
      test_guile
    ) 2>&1 | tee "${LOGS_FOLDER_PATH}/${guile_folder_name}/test-output-$(ndate).txt"

    hash -r

    touch "${guile_stamp_file_path}"

  else
    echo "Component guile already installed."
  fi

  test_functions+=("test_guile")
}

function test_guile()
{
  (
    # xbb_activate_installed_bin

    echo
    echo "Checking the guile shared libraries..."

    show_libs "${BINS_INSTALL_FOLDER_PATH}/bin/guile"
    show_libs "$(realpath ${LIBS_INSTALL_FOLDER_PATH}/lib/libguile-2.2.${SHLIB_EXT})"
    show_libs "$(realpath ${LIBS_INSTALL_FOLDER_PATH}/lib/guile/2.2/extensions/guile-readline.so)"

    echo
    echo "Testing if guile binaries start properly..."

    run_app "${BINS_INSTALL_FOLDER_PATH}/bin/guile" --version
    run_app "${BINS_INSTALL_FOLDER_PATH}/bin/guile-config" --version
  )
}

# -----------------------------------------------------------------------------


function build_autogen()
{
  # https://www.gnu.org/software/autogen/
  # https://ftp.gnu.org/gnu/autogen/
  # https://ftp.gnu.org/gnu/autogen/rel5.18.16/autogen-5.18.16.tar.xz

  # https://archlinuxarm.org/packages/aarch64/autogen/files/PKGBUILD
  # https://github.com/Homebrew/homebrew-core/blob/master/Formula/autogen.rb

  # 2018-08-26, "5.18.16"

  local autogen_version="$1"

  local autogen_src_folder_name="autogen-${autogen_version}"

  local autogen_archive="${autogen_src_folder_name}.tar.xz"
  local autogen_url="https://ftp.gnu.org/gnu/autogen/rel${autogen_version}/${autogen_archive}"

  local autogen_folder_name="${autogen_src_folder_name}"

  local autogen_stamp_file_path="${STAMPS_FOLDER_PATH}/stamp-${autogen_folder_name}-installed"
  if [ ! -f "${autogen_stamp_file_path}" ]
  then

    cd "${SOURCES_FOLDER_PATH}"

    download_and_extract "${autogen_url}" "${autogen_archive}" \
      "${autogen_src_folder_name}"

    mkdir -pv "${LOGS_FOLDER_PATH}/${autogen_folder_name}"

    (
      mkdir -pv "${BUILD_FOLDER_PATH}/${autogen_folder_name}"
      cd "${BUILD_FOLDER_PATH}/${autogen_folder_name}"

      xbb_activate_installed_bin
      xbb_activate_installed_dev

      CPPFLAGS="${XBB_CPPFLAGS} -D_POSIX_C_SOURCE"
      CFLAGS="${XBB_CFLAGS_NO_W}"
      CXXFLAGS="${XBB_CXXFLAGS_NO_W}"

      LDFLAGS="${XBB_LDFLAGS_APP_STATIC_GCC}"
      if [ "${TARGET_PLATFORM}" == "linux" ]
      then
        LDFLAGS+=" -Wl,-rpath,${LD_LIBRARY_PATH}"
      fi

      if [ "${TARGET_PLATFORM}" == "linux" ]
      then
        # To find libopts.so during build.
        export LD_LIBRARY_PATH="${XBB_LIBRARY_PATH}:${BUILD_FOLDER_PATH}/${autogen_folder_name}/autoopts/.libs"
      fi

      export CPPFLAGS
      export CFLAGS
      export CXXFLAGS
      export LDFLAGS

      if [ ! -f "config.status" ]
      then
        (
          if [ "${IS_DEVELOP}" == "y" ]
          then
            env | sort
          fi

          echo
          echo "Running autogen configure..."

          if [ "${IS_DEVELOP}" == "y" ]
          then
            run_verbose bash "${SOURCES_FOLDER_PATH}/${autogen_src_folder_name}/configure" --help
          fi

          # config.status: error: in `/root/Work/xbb-3.2-ubuntu-12.04-x86_64/build/autogen-5.18.16':
          # config.status: error: Something went wrong bootstrapping makefile fragments
          #   for automatic dependency tracking.  Try re-running configure with the
          #   '--disable-dependency-tracking' option to at least be able to build
          #   the package (albeit without support for automatic dependency tracking).

          # Without ac_cv_func_utimensat=no it fails on macOS.

          config_options=()

          config_options+=("--prefix=${BINS_INSTALL_FOLDER_PATH}")
          config_options+=("--libdir=${LIBS_INSTALL_FOLDER_PATH}/lib")
          config_options+=("--includedir=${LIBS_INSTALL_FOLDER_PATH}/include")
          # config_options+=("--datarootdir=${LIBS_INSTALL_FOLDER_PATH}/share")
          config_options+=("--mandir=${LIBS_INSTALL_FOLDER_PATH}/share/man")

          config_options+=("--build=${BUILD}")
          config_options+=("--host=${HOST}")
          config_options+=("--target=${TARGET}")

          config_options+=("--disable-dependency-tracking")
          config_options+=("--program-prefix=")
          config_options+=("ac_cv_func_utimensat=no")

          run_verbose bash ${DEBUG} "${SOURCES_FOLDER_PATH}/${autogen_src_folder_name}/configure" \
            "${config_options[@]}"

if false
then
          # FAIL: cond.test
          # FAILURE: warning diffs:  'undefining SECOND' not found
          run_verbose sed -i.bak \
            -e 's|cond.test||g' \
            "autoopts/test/Makefile"

          if is_linux
          then
            patch_all_libtool_rpath

            run_verbose find . \
              -name Makefile \
              -print \
              -exec sed -i.bak -e "s|-Wl,-rpath -Wl,${INSTALL_FOLDER_PATH}/lib||" {} \;
          fi
fi
          cp "config.log" "${LOGS_FOLDER_PATH}/${autogen_folder_name}/config-log-$(ndate).txt"
        ) 2>&1 | tee "${LOGS_FOLDER_PATH}/${autogen_folder_name}/configure-output-$(ndate).txt"
      fi

      (
        echo
        echo "Running autogen make..."

        # Build.
        run_verbose make -j ${JOBS}

        run_verbose make install

        if false # [ "${WITH_TESTS}" == "y" ]
        then
          # WARN-TEST
          run_verbose make -j1 check
        fi

      ) 2>&1 | tee "${LOGS_FOLDER_PATH}/${autogen_folder_name}/make-output-$(ndate).txt"

      copy_license \
        "${SOURCES_FOLDER_PATH}/${autogen_src_folder_name}" \
        "${autogen_folder_name}"
    )

    (
      test_autogen
    ) 2>&1 | tee "${LOGS_FOLDER_PATH}/${autogen_folder_name}/test-output-$(ndate).txt"

    touch "${autogen_stamp_file_path}"

  else
    echo "Component autogen already installed."
  fi

  test_functions+=("test_autogen")
}

function test_autogen()
{
  (
    # xbb_activate_installed_bin

    echo
    echo "Checking the autogen shared libraries..."

    show_libs "${TEST_PATH}/bin/autogen"
    show_libs "${TEST_PATH}/bin/columns"
    show_libs "${TEST_PATH}/bin/getdefs"

    show_libs "$(realpath ${LIBS_INSTALL_FOLDER_PATH}/lib/libopts.${SHLIB_EXT})"

    echo
    echo "Testing if autogen binaries start properly..."

    run_app "${TEST_PATH}/bin/autogen" --version
    run_app "${TEST_PATH}/bin/autoopts-config" --version
    run_app "${TEST_PATH}/bin/columns" --version
    run_app "${TEST_PATH}/bin/getdefs" --version

    echo
    echo "Testing if autogen binaries display help..."

    run_app "${TEST_PATH}/bin/autogen" --help

    # getdefs error:  invalid option descriptor for version
    run_app "${TEST_PATH}/bin/getdefs" --help || true
  )
}

# -----------------------------------------------------------------------------





function build_coreutils()
{
  # https://www.gnu.org/software/coreutils/
  # https://ftp.gnu.org/gnu/coreutils/

  # https://archlinuxarm.org/packages/aarch64/coreutils/files/PKGBUILD

  # 2018-07-01, "8.30"
  # 2019-03-10 "8.31"
  # 2020-03-05, "8.32"
  # 2021-09-24, "9.0"

  local coreutils_version="$1"

  local coreutils_src_folder_name="coreutils-${coreutils_version}"

  local coreutils_archive="${coreutils_src_folder_name}.tar.xz"
  local coreutils_url="https://ftp.gnu.org/gnu/coreutils/${coreutils_archive}"

  local coreutils_folder_name="${coreutils_src_folder_name}"

  local coreutils_stamp_file_path="${STAMPS_FOLDER_PATH}/stamp-${coreutils_folder_name}-installed"
  if [ ! -f "${coreutils_stamp_file_path}" ]
  then

    cd "${SOURCES_FOLDER_PATH}"

    download_and_extract "${coreutils_url}" "${coreutils_archive}" \
      "${coreutils_src_folder_name}"

    mkdir -pv "${LOGS_FOLDER_PATH}/${coreutils_folder_name}"

    (
      mkdir -pv "${BUILD_FOLDER_PATH}/${coreutils_folder_name}"
      cd "${BUILD_FOLDER_PATH}/${coreutils_folder_name}"

      xbb_activate_installed_dev

      CPPFLAGS="${XBB_CPPFLAGS}"
      CFLAGS="${XBB_CFLAGS_NO_W}"
      CXXFLAGS="${XBB_CXXFLAGS_NO_W}"

      LDFLAGS="${XBB_LDFLAGS_APP_STATIC_GCC}"
      if [ "${TARGET_PLATFORM}" == "linux" ]
      then
        LDFLAGS+=" -Wl,-rpath,${LD_LIBRARY_PATH}"
      fi

      export CPPFLAGS
      export CFLAGS
      export CXXFLAGS
      export LDFLAGS

      if [ ! -f "config.status" ]
      then
        (
          if [ "${IS_DEVELOP}" == "y" ]
          then
            env | sort
          fi

          echo
          echo "Running coreutils configure..."

          if [ "${IS_DEVELOP}" == "y" ]
          then
            run_verbose bash "${SOURCES_FOLDER_PATH}/${coreutils_src_folder_name}/configure" --help
          fi

          if false # [ -f "/.dockerenv" ]
          then
            # configure: error: you should not run configure as root
            # (set FORCE_UNSAFE_CONFIGURE=1 in environment to bypass this check)
            export FORCE_UNSAFE_CONFIGURE=1
          fi

          config_options=()

          config_options+=("--prefix=${BINS_INSTALL_FOLDER_PATH}")
          config_options+=("--libdir=${LIBS_INSTALL_FOLDER_PATH}/lib")
          config_options+=("--includedir=${LIBS_INSTALL_FOLDER_PATH}/include")
          # config_options+=("--datarootdir=${LIBS_INSTALL_FOLDER_PATH}/share")
          config_options+=("--mandir=${LIBS_INSTALL_FOLDER_PATH}/share/man")

          config_options+=("--build=${BUILD}")
          config_options+=("--host=${HOST}")
          config_options+=("--target=${TARGET}")

          config_options+=("--with-universal-archs=${TARGET_BITS}-bit")
          config_options+=("--with-computed-gotos")
          config_options+=("--with-dbmliborder=gdbm:ndbm")

          config_options+=("--with-openssl")

          if [ "${TARGET_PLATFORM}" == "darwin" ]
          then
            config_options+=("--enable-no-install-program=ar")
          fi

          # set +u

          # `ar` must be excluded, it interferes with Apple similar program.
          run_verbose bash ${DEBUG} "${SOURCES_FOLDER_PATH}/${coreutils_src_folder_name}/configure" \
            "${config_options[@]}"

          # set -u

          cp "config.log" "${LOGS_FOLDER_PATH}/${coreutils_folder_name}/config-log-$(ndate).txt"
        ) 2>&1 | tee "${LOGS_FOLDER_PATH}/${coreutils_folder_name}/configure-output-$(ndate).txt"
      fi

      (
        echo
        echo "Running coreutils make..."

        # Build.
        run_verbose make -j ${JOBS}

        # make install-strip
        run_verbose make install-exec

        # Takes very long and fails.
        # x86_64: FAIL: tests/misc/chroot-credentials.sh
        # x86_64: ERROR: tests/du/long-from-unreadable.sh
        # WARN-TEST
        # make -j1 check

      ) 2>&1 | tee "${LOGS_FOLDER_PATH}/${coreutils_folder_name}/make-output-$(ndate).txt"

      copy_license \
        "${SOURCES_FOLDER_PATH}/${coreutils_src_folder_name}" \
        "${coreutils_folder_name}"
    )

    (
      test_coreutils
    ) 2>&1 | tee "${LOGS_FOLDER_PATH}/${coreutils_folder_name}/test-output-$(ndate).txt"

    hash -r

    touch "${coreutils_stamp_file_path}"

  else
    echo "Component coreutils already installed."
  fi

  test_functions+=("test_coreutils")
}

function test_coreutils()
{
  (
    # xbb_activate_installed_bin

    echo
    echo "Checking the coreutils binaries shared libraries..."

    show_libs "${TEST_PATH}/bin/basename"
    show_libs "${TEST_PATH}/bin/cat"
    show_libs "${TEST_PATH}/bin/chmod"
    show_libs "${TEST_PATH}/bin/chown"
    show_libs "${TEST_PATH}/bin/cp"
    show_libs "${TEST_PATH}/bin/dirname"
    show_libs "${TEST_PATH}/bin/ln"
    show_libs "${TEST_PATH}/bin/ls"
    show_libs "${TEST_PATH}/bin/mkdir"
    show_libs "${TEST_PATH}/bin/mv"
    show_libs "${TEST_PATH}/bin/printf"
    show_libs "${TEST_PATH}/bin/realpath"
    show_libs "${TEST_PATH}/bin/rm"
    show_libs "${TEST_PATH}/bin/rmdir"
    show_libs "${TEST_PATH}/bin/sha256sum"
    show_libs "${TEST_PATH}/bin/sort"
    show_libs "${TEST_PATH}/bin/touch"
    show_libs "${TEST_PATH}/bin/tr"
    show_libs "${TEST_PATH}/bin/wc"

    echo
    echo "Testing if coreutils binaries start properly..."

    echo
    run_app "${TEST_PATH}/bin/basename" --version
    run_app "${TEST_PATH}/bin/cat" --version
    run_app "${TEST_PATH}/bin/chmod" --version
    run_app "${TEST_PATH}/bin/chown" --version
    run_app "${TEST_PATH}/bin/cp" --version
    run_app "${TEST_PATH}/bin/dirname" --version
    run_app "${TEST_PATH}/bin/ln" --version
    run_app "${TEST_PATH}/bin/ls" --version
    run_app "${TEST_PATH}/bin/mkdir" --version
    run_app "${TEST_PATH}/bin/mv" --version
    run_app "${TEST_PATH}/bin/printf" --version
    run_app "${TEST_PATH}/bin/realpath" --version
    run_app "${TEST_PATH}/bin/rm" --version
    run_app "${TEST_PATH}/bin/rmdir" --version
    run_app "${TEST_PATH}/bin/sha256sum" --version
    run_app "${TEST_PATH}/bin/sort" --version
    run_app "${TEST_PATH}/bin/touch" --version
    run_app "${TEST_PATH}/bin/tr" --version
    run_app "${TEST_PATH}/bin/wc" --version
  )
}

# -----------------------------------------------------------------------------

function build_m4()
{
  # https://www.gnu.org/software/m4/
  # https://ftp.gnu.org/gnu/m4/

  # https://archlinuxarm.org/packages/aarch64/m4/files/PKGBUILD
  # https://aur.archlinux.org/cgit/aur.git/tree/PKGBUILD?h=m4-git

  # https://github.com/Homebrew/homebrew-core/blob/master/Formula/m4.rb

  # 2016-12-31, "1.4.18"
  # 2021-05-28, "1.4.19"

  local m4_version="$1"

  local m4_src_folder_name="m4-${m4_version}"

  local m4_archive="${m4_src_folder_name}.tar.xz"
  local m4_url="https://ftp.gnu.org/gnu/m4/${m4_archive}"

  local m4_folder_name="${m4_src_folder_name}"

  local m4_patch_file_path="${helper_folder_path}/patches/${m4_folder_name}.patch"
  local m4_stamp_file_path="${STAMPS_FOLDER_PATH}/stamp-${m4_folder_name}-installed"
  if [ ! -f "${m4_stamp_file_path}" ]
  then

    cd "${SOURCES_FOLDER_PATH}"

    download_and_extract "${m4_url}" "${m4_archive}" \
      "${m4_src_folder_name}" \
      "${m4_patch_file_path}"

    mkdir -pv "${LOGS_FOLDER_PATH}/${m4_folder_name}"

    (
      mkdir -pv "${BUILD_FOLDER_PATH}/${m4_folder_name}"
      cd "${BUILD_FOLDER_PATH}/${m4_folder_name}"

      xbb_activate_installed_dev

      CPPFLAGS="${XBB_CPPFLAGS}"
      CFLAGS="${XBB_CFLAGS_NO_W}"
      CXXFLAGS="${XBB_CXXFLAGS_NO_W}"

      LDFLAGS="${XBB_LDFLAGS_APP_STATIC_GCC}"
      if [ "${TARGET_PLATFORM}" == "linux" ]
      then
        LDFLAGS+=" -Wl,-rpath,${LD_LIBRARY_PATH}"
      fi

      export CPPFLAGS
      export CFLAGS
      export CXXFLAGS
      export LDFLAGS

      if [ ! -f "config.status" ]
      then
        (
          if [ "${IS_DEVELOP}" == "y" ]
          then
            env | sort
          fi

          echo
          echo "Running m4 configure..."

          if [ "${IS_DEVELOP}" == "y" ]
          then
            run_verbose bash "${SOURCES_FOLDER_PATH}/${m4_src_folder_name}/configure" --help
          fi

          config_options=()

          config_options+=("--prefix=${BINS_INSTALL_FOLDER_PATH}")
          config_options+=("--libdir=${LIBS_INSTALL_FOLDER_PATH}/lib")
          config_options+=("--includedir=${LIBS_INSTALL_FOLDER_PATH}/include")
          # config_options+=("--datarootdir=${LIBS_INSTALL_FOLDER_PATH}/share")
          config_options+=("--mandir=${LIBS_INSTALL_FOLDER_PATH}/share/man")

          config_options+=("--build=${BUILD}")
          config_options+=("--host=${HOST}")
          config_options+=("--target=${TARGET}")

          run_verbose bash ${DEBUG} "${SOURCES_FOLDER_PATH}/${m4_src_folder_name}/configure" \
            "${config_options[@]}"

          cp "config.log" "${LOGS_FOLDER_PATH}/${m4_folder_name}/config-log-$(ndate).txt"
        ) 2>&1 | tee "${LOGS_FOLDER_PATH}/${m4_folder_name}/configure-output-$(ndate).txt"
      fi

      (
        echo
        echo "Running m4 make..."

        # Build.
        run_verbose make -j ${JOBS}

        # make install-strip
        run_verbose make install-exec

        (
          echo
          echo "Linking gm4..."
          cd "${BINS_INSTALL_FOLDER_PATH}/bin"
          rm -fv gm4
          ln -sv m4 gm4
        )

        # Fails on Ubuntu 18
        # checks/198.sysval:err
        if false # [ "${RUN_TESTS}" == "y" ]
        then
          if is_darwin
          then
            # On macOS 10.15
            # FAIL: test-fflush2.sh
            # FAIL: test-fpurge
            # FAIL: test-ftell.sh
            # FAIL: test-ftello2.sh
            run_verbose make -j1 check || true
          else
            run_verbose make -j1 check
          fi
        fi

      ) 2>&1 | tee "${LOGS_FOLDER_PATH}/${m4_folder_name}/make-output-$(ndate).txt"

      copy_license \
        "${SOURCES_FOLDER_PATH}/${m4_src_folder_name}" \
        "${m4_folder_name}"
    )

    (
      test_m4
    ) 2>&1 | tee "${LOGS_FOLDER_PATH}/${m4_folder_name}/test-output-$(ndate).txt"

    hash -r

    touch "${m4_stamp_file_path}"

  else
    echo "Component m4 already installed."
  fi

  test_functions+=("test_m4")
}

function test_m4()
{
  (
    # xbb_activate_installed_bin

    echo
    echo "Checking the m4 binaries shared libraries..."

    show_libs "${TEST_PATH}/bin/m4"

    echo
    echo "Testing if m4 binaries start properly..."

    run_app "${TEST_PATH}/bin/m4" --version
  )
}

# -----------------------------------------------------------------------------

function build_gawk()
{
  # https://www.gnu.org/software/gawk/
  # https://ftp.gnu.org/gnu/gawk/

  # https://archlinuxarm.org/packages/aarch64/gawk/files/PKGBUILD
  # https://aur.archlinux.org/cgit/aur.git/tree/PKGBUILD?h=gawk-git

  # 2017-10-19, "4.2.0"
  # 2018-02-25, "4.2.1"
  # 2019-06-18, "5.0.1"
  # 2020-04-14, "5.1.0"
  # 2021-10-28, "5.1.1"

  local gawk_version="$1"

  local gawk_src_folder_name="gawk-${gawk_version}"

  local gawk_archive="${gawk_src_folder_name}.tar.xz"
  local gawk_url="https://ftp.gnu.org/gnu/gawk/${gawk_archive}"

  local gawk_folder_name="${gawk_src_folder_name}"

  local gawk_stamp_file_path="${STAMPS_FOLDER_PATH}/stamp-${gawk_folder_name}-installed"
  if [ ! -f "${gawk_stamp_file_path}" ]
  then

    cd "${SOURCES_FOLDER_PATH}"

    download_and_extract "${gawk_url}" "${gawk_archive}" \
      "${gawk_src_folder_name}"

    mkdir -pv "${LOGS_FOLDER_PATH}/${gawk_folder_name}"

    (
      mkdir -pv "${BUILD_FOLDER_PATH}/${gawk_folder_name}"
      cd "${BUILD_FOLDER_PATH}/${gawk_folder_name}"

      xbb_activate_installed_dev

      CPPFLAGS="${XBB_CPPFLAGS}"
      CFLAGS="${XBB_CFLAGS_NO_W}"
      CXXFLAGS="${XBB_CXXFLAGS_NO_W}"

      LDFLAGS="${XBB_LDFLAGS_APP_STATIC_GCC}"
      if [ "${TARGET_PLATFORM}" == "linux" ]
      then
        LDFLAGS+=" -Wl,-rpath,${LD_LIBRARY_PATH}"
      fi

      export CPPFLAGS
      export CFLAGS
      export CXXFLAGS
      export LDFLAGS

      if [ ! -f "config.status" ]
      then
        (
          if [ "${IS_DEVELOP}" == "y" ]
          then
            env | sort
          fi

          echo
          echo "Running gawk configure..."

          if [ "${IS_DEVELOP}" == "y" ]
          then
            run_verbose bash "${SOURCES_FOLDER_PATH}/${gawk_src_folder_name}/configure" --help
          fi

          # --disable-extensions
          # Extension tests fail:
          # apiterm
          # /root/Work/xbb-bootstrap-3.2-ubuntu-12.04-i686/sources/gawk-4.2.1/test/apiterm.ok _apiterm differ: byte 1, line 1
          # filefuncs
          # cmp: EOF on /root/Work/xbb-bootstrap-3.2-ubuntu-12.04-i686/sources/gawk-4.2.1/test/filefuncs.ok
          # fnmatch
          # /root/Work/xbb-bootstrap-3.2-ubuntu-12.04-i686/sources/gawk-4.2.1/test/fnmatch.ok _fnmatch differ: byte 1, line 1
          # fork
          # cmp: EOF on /root/Work/xbb-bootstrap-3.2-ubuntu-12.04-i686/sources/gawk-4.2.1/test/fork.ok
          # fork2
          # cmp: EOF on /root/Work/xbb-bootstrap-3.2-ubuntu-12.04-i686/sources/gawk-4.2.1/test/fork2.ok
          # fts
          # gawk: /root/Work/xbb-bootstrap-3.2-ubuntu-12.04-i686/sources/gawk-4.2.1/test/fts.awk:2: fatal: load_ext: library `../extension/.libs/filefuncs.so': does not define `plugin_is_GPL_compatible' (../extension/.libs/filefuncs.so: undefined symbol: plugin_is_GPL_compatible)

          # --enable-builtin-intdiv0
          # ! gawk: mpfrsqrt.awk:13: error: can't open shared library `intdiv' for reading (No such file or directory)
          # ! EXIT CODE: 1

          config_options=()

          config_options+=("--prefix=${BINS_INSTALL_FOLDER_PATH}")
          config_options+=("--libdir=${LIBS_INSTALL_FOLDER_PATH}/lib")
          config_options+=("--includedir=${LIBS_INSTALL_FOLDER_PATH}/include")
          # config_options+=("--datarootdir=${LIBS_INSTALL_FOLDER_PATH}/share")
          config_options+=("--mandir=${LIBS_INSTALL_FOLDER_PATH}/share/man")

          config_options+=("--build=${BUILD}")
          config_options+=("--host=${HOST}")
          config_options+=("--target=${TARGET}")

          config_options+=("--without-libsigsegv")
          config_options+=("--disable-extensions")
          config_options+=("--enable-builtin-intdiv0")

          run_verbose bash ${DEBUG} "${SOURCES_FOLDER_PATH}/${gawk_src_folder_name}/configure" \
            "${config_options[@]}"

          cp "config.log" "${LOGS_FOLDER_PATH}/${gawk_folder_name}/config-log-$(ndate).txt"
        ) 2>&1 | tee "${LOGS_FOLDER_PATH}/${gawk_folder_name}/configure-output-$(ndate).txt"
      fi

      (
        echo
        echo "Running gawk make..."

        # Build.
        run_verbose make -j ${JOBS}

        # make install-strip
        run_verbose make install-exec

        # Multiple failures, no time to investigate.
        # WARN-TEST
        if false # [ "${RUN_LONG_TESTS}" == "y" ]
        then
          make -j1 check
        fi

      ) 2>&1 | tee "${LOGS_FOLDER_PATH}/${gawk_folder_name}/make-output-$(ndate).txt"

      copy_license \
        "${SOURCES_FOLDER_PATH}/${gawk_src_folder_name}" \
        "${gawk_folder_name}"
    )

    (
      test_gawk
    ) 2>&1 | tee "${LOGS_FOLDER_PATH}/${gawk_folder_name}/test-output-$(ndate).txt"

    hash -r

    touch "${gawk_stamp_file_path}"

  else
    echo "Component gawk already installed."
  fi

  test_functions+=("test_gawk")
}

function test_gawk()
{
  (
    # xbb_activate_installed_bin

    echo
    echo "Checking the gawk binaries shared libraries..."

    show_libs "${TEST_PATH}/bin/gawk"

    echo
    echo "Testing if gawk binaries start properly..."

    run_app "${TEST_PATH}/bin/gawk" --version
  )
}

# -----------------------------------------------------------------------------

function build_sed()
{
  # https://www.gnu.org/software/sed/
  # https://ftp.gnu.org/gnu/sed/

  # https://archlinuxarm.org/packages/aarch64/sed/files/PKGBUILD

  # 2018-12-21, "4.7"
  # 2020-01-14, "4.8"

  local sed_version="$1"

  local sed_src_folder_name="sed-${sed_version}"

  local sed_archive="${sed_src_folder_name}.tar.xz"
  local sed_url="https://ftp.gnu.org/gnu/sed/${sed_archive}"

  local sed_folder_name="${sed_src_folder_name}"

  local sed_stamp_file_path="${STAMPS_FOLDER_PATH}/stamp-${sed_folder_name}-installed"
  if [ ! -f "${sed_stamp_file_path}" ]
  then

    cd "${SOURCES_FOLDER_PATH}"

    download_and_extract "${sed_url}" "${sed_archive}" \
      "${sed_src_folder_name}"

    mkdir -pv "${LOGS_FOLDER_PATH}/${sed_folder_name}"

    (
      mkdir -pv "${BUILD_FOLDER_PATH}/${sed_folder_name}"
      cd "${BUILD_FOLDER_PATH}/${sed_folder_name}"

      xbb_activate_installed_dev

      CPPFLAGS="${XBB_CPPFLAGS}"
      if [ "${TARGET_PLATFORM}" == "darwin" ]
      then
        # Configure expects a warning for clang.
        CFLAGS="${XBB_CFLAGS}"
        CXXFLAGS="${XBB_CXXFLAGS}"
      else
        CFLAGS="${XBB_CFLAGS_NO_W}"
        CXXFLAGS="${XBB_CXXFLAGS_NO_W}"
      fi

      LDFLAGS="${XBB_LDFLAGS_APP_STATIC_GCC}"
      if [ "${TARGET_PLATFORM}" == "linux" ]
      then
        LDFLAGS+=" -Wl,-rpath,${LD_LIBRARY_PATH}"
      fi

      export CPPFLAGS
      export CFLAGS
      export CXXFLAGS
      export LDFLAGS

      if [ ! -f "config.status" ]
      then
        (
          if [ "${IS_DEVELOP}" == "y" ]
          then
            env | sort
          fi

          echo
          echo "Running sed configure..."

          if [ "${IS_DEVELOP}" == "y" ]
          then
            run_verbose bash "${SOURCES_FOLDER_PATH}/${sed_src_folder_name}/configure" --help
          fi

          config_options=()

          config_options+=("--prefix=${BINS_INSTALL_FOLDER_PATH}")
          config_options+=("--libdir=${LIBS_INSTALL_FOLDER_PATH}/lib")
          config_options+=("--includedir=${LIBS_INSTALL_FOLDER_PATH}/include")
          # config_options+=("--datarootdir=${LIBS_INSTALL_FOLDER_PATH}/share")
          config_options+=("--mandir=${LIBS_INSTALL_FOLDER_PATH}/share/man")

          config_options+=("--build=${BUILD}")
          config_options+=("--host=${HOST}")
          config_options+=("--target=${TARGET}")

          run_verbose bash ${DEBUG} "${SOURCES_FOLDER_PATH}/${sed_src_folder_name}/configure" \
            "${config_options[@]}"

if false
then
          # Fails on Intel and Arm, better disable it completely.
          run_verbose sed -i.bak \
            -e 's|testsuite/panic-tests.sh||g' \
            "Makefile"

          # Some tests fail due to missing locales.
          # darwin: FAIL: testsuite/subst-mb-incomplete.sh
fi

          cp "config.log" "${LOGS_FOLDER_PATH}/${sed_folder_name}/config-log-$(ndate).txt"
        ) 2>&1 | tee "${LOGS_FOLDER_PATH}/${sed_folder_name}/configure-output-$(ndate).txt"
      fi

      (
        echo
        echo "Running sed make..."

        # Build.
        run_verbose make -j ${JOBS}

        # make install-strip
        run_verbose make install-exec

        (
          echo
          echo "Linking gsed..."
          cd "${BINS_INSTALL_FOLDER_PATH}/bin"
          rm -fv gsed
          ln -sv sed gsed
        )

        if [ "${WITH_TESTS}" == "y" ]
        then
          # WARN-TEST
          if [ "${TARGET_PLATFORM}" == "darwin" ]
          then
            # FAIL:  6
            : run_verbose make -j1 check || true
          else
            run_verbose make -j1 check
          fi
        fi

      ) 2>&1 | tee "${LOGS_FOLDER_PATH}/${sed_folder_name}/make-output-$(ndate).txt"

      copy_license \
        "${BUILD_FOLDER_PATH}/${sed_folder_name}" \
        "${sed_folder_name}"
    )

    (
      test_sed
    ) 2>&1 | tee "${LOGS_FOLDER_PATH}/${sed_folder_name}/test-output-$(ndate).txt"

    hash -r

    touch "${sed_stamp_file_path}"

  else
    echo "Component sed already installed."
  fi

  test_functions+=("test_sed")
}

function test_sed()
{
  (
    # xbb_activate_installed_bin

    echo
    echo "Checking the sed binaries shared libraries..."

    show_libs "${TEST_PATH}/bin/sed"

    echo
    echo "Testing if sed binaries start properly..."

    run_app "${TEST_PATH}/bin/sed" --version
  )
}

# -----------------------------------------------------------------------------

function build_autoconf()
{
  # https://www.gnu.org/software/autoconf/
  # https://ftp.gnu.org/gnu/autoconf/

  # https://archlinuxarm.org/packages/any/autoconf2.13/files/PKGBUILD
  # https://aur.archlinux.org/cgit/aur.git/tree/PKGBUILD?h=autoconf-git

  # https://github.com/Homebrew/homebrew-core/blob/master/Formula/autoconf.rb

  # 2012-04-24, "2.69"
  # 2021-01-28, "2.71"

  local autoconf_version="$1"

  local autoconf_src_folder_name="autoconf-${autoconf_version}"

  local autoconf_archive="${autoconf_src_folder_name}.tar.xz"
  local autoconf_url="https://ftp.gnu.org/gnu/autoconf/${autoconf_archive}"

  local autoconf_folder_name="${autoconf_src_folder_name}"

  local autoconf_stamp_file_path="${STAMPS_FOLDER_PATH}/stamp-${autoconf_folder_name}-installed"
  if [ ! -f "${autoconf_stamp_file_path}" ]
  then

    cd "${SOURCES_FOLDER_PATH}"

    download_and_extract "${autoconf_url}" "${autoconf_archive}" \
      "${autoconf_src_folder_name}"

    mkdir -pv "${LOGS_FOLDER_PATH}/${autoconf_folder_name}"

    (
      mkdir -pv "${BUILD_FOLDER_PATH}/${autoconf_folder_name}"
      cd "${BUILD_FOLDER_PATH}/${autoconf_folder_name}"

      xbb_activate_installed_dev

      CPPFLAGS="${XBB_CPPFLAGS}"
      CFLAGS="${XBB_CFLAGS_NO_W}"
      CXXFLAGS="${XBB_CXXFLAGS_NO_W}"

      LDFLAGS="${XBB_LDFLAGS_APP_STATIC_GCC}"
      if [ "${TARGET_PLATFORM}" == "linux" ]
      then
        LDFLAGS+=" -Wl,-rpath,${LD_LIBRARY_PATH}"
      fi

      export CPPFLAGS
      export CFLAGS
      export CXXFLAGS
      export LDFLAGS

      if [ ! -f "config.status" ]
      then
        (
          if [ "${IS_DEVELOP}" == "y" ]
          then
            env | sort
          fi

          echo
          echo "Running autoconf configure..."

          if [ "${IS_DEVELOP}" == "y" ]
          then
            run_verbose bash "${SOURCES_FOLDER_PATH}/${autoconf_src_folder_name}/configure" --help
          fi

          config_options=()

          config_options+=("--prefix=${BINS_INSTALL_FOLDER_PATH}")
          config_options+=("--libdir=${LIBS_INSTALL_FOLDER_PATH}/lib")
          config_options+=("--includedir=${LIBS_INSTALL_FOLDER_PATH}/include")
          # config_options+=("--datarootdir=${LIBS_INSTALL_FOLDER_PATH}/share")
          config_options+=("--mandir=${LIBS_INSTALL_FOLDER_PATH}/share/man")

          config_options+=("--build=${BUILD}")
          config_options+=("--host=${HOST}")
          config_options+=("--target=${TARGET}")

          config_options+=("--with-universal-archs=${TARGET_BITS}-bit")
          config_options+=("--with-computed-gotos")
          config_options+=("--with-dbmliborder=gdbm:ndbm")

          run_verbose bash ${DEBUG} "${SOURCES_FOLDER_PATH}/${autoconf_src_folder_name}/configure" \
            "${config_options[@]}"

          cp "config.log" "${LOGS_FOLDER_PATH}/${autoconf_folder_name}/config-log-$(ndate).txt"
        ) 2>&1 | tee "${LOGS_FOLDER_PATH}/${autoconf_folder_name}/configure-output-$(ndate).txt"
      fi

      (
        echo
        echo "Running autoconf make..."

        # Build.
        run_verbose make -j ${JOBS}

        # make install-strip
        run_verbose make install

        if false # [ "${RUN_LONG_TESTS}" == "y" ]
        then
          # 500 tests, 7 fail.
          make -j1 check
        fi

      ) 2>&1 | tee "${LOGS_FOLDER_PATH}/${autoconf_folder_name}/make-output-$(ndate).txt"

      copy_license \
        "${SOURCES_FOLDER_PATH}/${autoconf_src_folder_name}" \
        "${autoconf_folder_name}"
    )

    (
      test_autoconf
    ) 2>&1 | tee "${LOGS_FOLDER_PATH}/${autoconf_folder_name}/test-output-$(ndate).txt"

    hash -r

    touch "${autoconf_stamp_file_path}"

  else
    echo "Component autoconf already installed."
  fi

  test_functions+=("test_autoconf")
}

function test_autoconf()
{
  (
    # xbb_activate_installed_bin

    echo
    echo "Testing if autoconf scripts start properly..."

    run_app "${TEST_PATH}/bin/autoconf" --version

    # Can't locate Autom4te/ChannelDefs.pm in @INC (you may need to install the Autom4te::ChannelDefs module) (@INC contains: /Users/ilg/Work/xbb-bootstrap-4.0.0/darwin-x64/install/libs/share/autoconf /Users/ilg/.local/xbb/lib/perl5/site_perl/5.34.0/darwin-thread-multi-2level /Users/ilg/.local/xbb/lib/perl5/site_perl/5.34.0 /Users/ilg/.local/xbb/lib/perl5/5.34.0/darwin-thread-multi-2level /Users/ilg/.local/xbb/lib/perl5/5.34.0) at /Users/ilg/Work/xbb-bootstrap-4.0.0/darwin-x64/install/xbb-bootstrap/bin/autoheader line 45.
    # BEGIN failed--compilation aborted at /Users/ilg/Work/xbb-bootstrap-4.0.0/darwin-x64/install/xbb-bootstrap/bin/autoheader line 45.
    # run_app "${TEST_PATH}/bin/autoheader" --version

    # run_app "${TEST_PATH}/bin/autoscan" --version
    # run_app "${TEST_PATH}/bin/autoupdate" --version

    # No ELFs, only scripts.
  )
}

# -----------------------------------------------------------------------------

function build_automake()
{
  # https://www.gnu.org/software/automake/
  # https://ftp.gnu.org/gnu/automake/

  # https://archlinuxarm.org/packages/any/automake/files/PKGBUILD
  # https://aur.archlinux.org/cgit/aur.git/tree/PKGBUILD?h=automake-git

  # 2015-01-05, "1.15"
  # 2018-02-25, "1.16"
  # 2020-03-21, "1.16.2"
  # 2020-11-18, "1.16.3"
  # 2021-07-26, "1.16.4"
  # 2021-10-03, "1.16.5"

  local automake_version="$1"

  local automake_src_folder_name="automake-${automake_version}"

  local automake_archive="${automake_src_folder_name}.tar.xz"
  local automake_url="https://ftp.gnu.org/gnu/automake/${automake_archive}"

  local automake_folder_name="${automake_src_folder_name}"

  # help2man: can't get `--help' info from automake-1.16
  # Try `--no-discard-stderr' if option outputs to stderr

  local automake_patch_file_path="${helper_folder_path}/patches/${automake_folder_name}.patch"
  local automake_stamp_file_path="${STAMPS_FOLDER_PATH}/stamp-${automake_folder_name}-installed"
  if [ ! -f "${automake_stamp_file_path}" ]
  then

    cd "${SOURCES_FOLDER_PATH}"

    download_and_extract "${automake_url}" "${automake_archive}" \
      "${automake_src_folder_name}" \
      "${automake_patch_file_path}"

    mkdir -pv "${LOGS_FOLDER_PATH}/${automake_folder_name}"

    (
      mkdir -pv "${BUILD_FOLDER_PATH}/${automake_folder_name}"
      cd "${BUILD_FOLDER_PATH}/${automake_folder_name}"

      xbb_activate_installed_dev

      CPPFLAGS="${XBB_CPPFLAGS}"
      CFLAGS="${XBB_CFLAGS_NO_W}"
      CXXFLAGS="${XBB_CXXFLAGS_NO_W}"

      LDFLAGS="${XBB_LDFLAGS_APP_STATIC_GCC}"
      if [ "${TARGET_PLATFORM}" == "linux" ]
      then
        LDFLAGS+=" -Wl,-rpath,${LD_LIBRARY_PATH}"
      fi

      export CPPFLAGS
      export CFLAGS
      export CXXFLAGS
      export LDFLAGS

      if [ ! -f "config.status" ]
      then
        (
          if [ "${IS_DEVELOP}" == "y" ]
          then
            env | sort
          fi

          echo
          echo "Running automake configure..."

          if [ "${IS_DEVELOP}" == "y" ]
          then
            run_verbose bash "${SOURCES_FOLDER_PATH}/${automake_src_folder_name}/configure" --help
          fi

          config_options=()

          config_options+=("--prefix=${BINS_INSTALL_FOLDER_PATH}")
          config_options+=("--libdir=${LIBS_INSTALL_FOLDER_PATH}/lib")
          config_options+=("--includedir=${LIBS_INSTALL_FOLDER_PATH}/include")
          # config_options+=("--datarootdir=${LIBS_INSTALL_FOLDER_PATH}/share")
          config_options+=("--mandir=${LIBS_INSTALL_FOLDER_PATH}/share/man")

          config_options+=("--build=${BUILD}")
          config_options+=("--host=${HOST}")
          config_options+=("--target=${TARGET}")

          run_verbose bash ${DEBUG} "${SOURCES_FOLDER_PATH}/${automake_src_folder_name}/configure" \
            "${config_options[@]}"

          cp "config.log" "${LOGS_FOLDER_PATH}/${automake_folder_name}/config-log-$(ndate).txt"
        ) 2>&1 | tee "${LOGS_FOLDER_PATH}/${automake_folder_name}/configure-output-$(ndate).txt"
      fi

      (
        echo
        echo "Running automake make..."

        # Build.
        run_verbose make -j ${JOBS}

        # make install-strip
        run_verbose make install

        # Takes too long and some tests fail.
        # XFAIL: t/pm/Cond2.pl
        # XFAIL: t/pm/Cond3.pl
        # ...
        if false # [ "${RUN_LONG_TESTS}" == "y" ]
        then
          make -j1 check
        fi

      ) 2>&1 | tee "${LOGS_FOLDER_PATH}/${automake_folder_name}/make-output-$(ndate).txt"

      copy_license \
        "${SOURCES_FOLDER_PATH}/${automake_src_folder_name}" \
        "${automake_folder_name}"
    )

    (
      test_automake
    ) 2>&1 | tee "${LOGS_FOLDER_PATH}/${automake_folder_name}/test-output-$(ndate).txt"

    hash -r

    touch "${automake_stamp_file_path}"

  else
    echo "Component automake already installed."
  fi

  test_functions+=("test_automake")
}

function test_automake()
{
  (
    # xbb_activate_installed_bin

    echo
    echo "Testing if automake scripts start properly..."

    run_app "${TEST_PATH}/bin/automake" --version
  )
}

# -----------------------------------------------------------------------------

function build_patch()
{
  # https://www.gnu.org/software/patch/
  # https://ftp.gnu.org/gnu/patch/

  # https://archlinuxarm.org/packages/aarch64/patch/files/PKGBUILD
  # https://aur.archlinux.org/cgit/aur.git/tree/PKGBUILD?h=patch-git

  # 2015-03-06, "2.7.5"
  # 2018-02-06, "2.7.6" (latest)

  local patch_version="$1"

  local patch_src_folder_name="patch-${patch_version}"

  local patch_archive="${patch_src_folder_name}.tar.xz"
  local patch_url="https://ftp.gnu.org/gnu/patch/${patch_archive}"

  local patch_folder_name="${patch_src_folder_name}"

  local patch_stamp_file_path="${STAMPS_FOLDER_PATH}/stamp-${patch_folder_name}-installed"
  if [ ! -f "${patch_stamp_file_path}" ]
  then

    cd "${SOURCES_FOLDER_PATH}"

    download_and_extract "${patch_url}" "${patch_archive}" \
      "${patch_src_folder_name}"

    mkdir -pv "${LOGS_FOLDER_PATH}/${patch_folder_name}"

    (
      mkdir -pv "${BUILD_FOLDER_PATH}/${patch_folder_name}"
      cd "${BUILD_FOLDER_PATH}/${patch_folder_name}"

      xbb_activate_installed_dev

      CPPFLAGS="${XBB_CPPFLAGS}"
      CFLAGS="${XBB_CFLAGS_NO_W}"
      CXXFLAGS="${XBB_CXXFLAGS_NO_W}"

      LDFLAGS="${XBB_LDFLAGS_APP_STATIC_GCC}"
      if [ "${TARGET_PLATFORM}" == "linux" ]
      then
        LDFLAGS+=" -Wl,-rpath,${LD_LIBRARY_PATH}"
      fi

      export CPPFLAGS
      export CFLAGS
      export CXXFLAGS
      export LDFLAGS

      if [ ! -f "config.status" ]
      then
        (
          if [ "${IS_DEVELOP}" == "y" ]
          then
            env | sort
          fi

          echo
          echo "Running patch configure..."

          if [ "${IS_DEVELOP}" == "y" ]
          then
            run_verbose bash "${SOURCES_FOLDER_PATH}/${patch_src_folder_name}/configure" --help
          fi

          config_options=()

          config_options+=("--prefix=${BINS_INSTALL_FOLDER_PATH}")
          config_options+=("--libdir=${LIBS_INSTALL_FOLDER_PATH}/lib")
          config_options+=("--includedir=${LIBS_INSTALL_FOLDER_PATH}/include")
          # config_options+=("--datarootdir=${LIBS_INSTALL_FOLDER_PATH}/share")
          config_options+=("--mandir=${LIBS_INSTALL_FOLDER_PATH}/share/man")

          config_options+=("--build=${BUILD}")
          config_options+=("--host=${HOST}")
          config_options+=("--target=${TARGET}")

          run_verbose bash ${DEBUG} "${SOURCES_FOLDER_PATH}/${patch_src_folder_name}/configure" \
            "${config_options[@]}"

          cp "config.log" "${LOGS_FOLDER_PATH}/${patch_folder_name}/config-log-$(ndate).txt"
        ) 2>&1 | tee "${LOGS_FOLDER_PATH}/${patch_folder_name}/configure-output-$(ndate).txt"
      fi

      (
        echo
        echo "Running patch make..."

        # Build.
        run_verbose make -j ${JOBS}

        # make install-strip
        run_verbose make install-exec

        if [ "${WITH_TESTS}" == "y" ]
        then
          run_verbose make -j1 check
        fi

      ) 2>&1 | tee "${LOGS_FOLDER_PATH}/${patch_folder_name}/make-output-$(ndate).txt"

      copy_license \
        "${SOURCES_FOLDER_PATH}/${patch_src_folder_name}" \
        "${patch_folder_name}"
    )

    (
      test_patch
    ) 2>&1 | tee "${LOGS_FOLDER_PATH}/${patch_folder_name}/test-output-$(ndate).txt"

    hash -r

    touch "${patch_stamp_file_path}"

  else
    echo "Component patch already installed."
  fi

  test_functions+=("test_patch")
}

function test_patch()
{
  (
    # xbb_activate_installed_bin

    echo
    echo "Checking the patch binaries shared libraries..."

    show_libs "${TEST_PATH}/bin/patch"

    echo
    echo "Testing if patch binaries start properly..."

    run_app "${TEST_PATH}/bin/patch" --version
  )
}

# -----------------------------------------------------------------------------

function build_diffutils()
{
  # https://www.gnu.org/software/diffutils/
  # https://ftp.gnu.org/gnu/diffutils/

  # https://archlinuxarm.org/packages/aarch64/diffutils/files/PKGBUILD
  # https://aur.archlinux.org/cgit/aur.git/tree/PKGBUILD?h=diffutils-git

  # 2017-05-21, "3.6"
  # 2018-12-31, "3.7"
  # 2021-08-01, "3.8"

  local diffutils_version="$1"

  local diffutils_src_folder_name="diffutils-${diffutils_version}"

  local diffutils_archive="${diffutils_src_folder_name}.tar.xz"
  local diffutils_url="https://ftp.gnu.org/gnu/diffutils/${diffutils_archive}"

  local diffutils_folder_name="${diffutils_src_folder_name}"

  local diffutils_stamp_file_path="${STAMPS_FOLDER_PATH}/stamp-${diffutils_folder_name}-installed"
  if [ ! -f "${diffutils_stamp_file_path}" ]
  then

    cd "${SOURCES_FOLDER_PATH}"

    download_and_extract "${diffutils_url}" "${diffutils_archive}" \
      "${diffutils_src_folder_name}"

    mkdir -pv "${LOGS_FOLDER_PATH}/${diffutils_folder_name}"

    (
      mkdir -pv "${BUILD_FOLDER_PATH}/${diffutils_folder_name}"
      cd "${BUILD_FOLDER_PATH}/${diffutils_folder_name}"

      xbb_activate_installed_dev

      CPPFLAGS="${XBB_CPPFLAGS}"
      if [ "${TARGET_PLATFORM}" == "darwin" ]
      then
        # Configure expects a warning for clang.
        CFLAGS="${XBB_CFLAGS}"
        CXXFLAGS="${XBB_CXXFLAGS}"
      else
        CFLAGS="${XBB_CFLAGS_NO_W}"
        CXXFLAGS="${XBB_CXXFLAGS_NO_W}"
      fi

      LDFLAGS="${XBB_LDFLAGS_APP_STATIC_GCC}"
      if [ "${TARGET_PLATFORM}" == "linux" ]
      then
        LDFLAGS+=" -Wl,-rpath,${LD_LIBRARY_PATH}"
      fi

      export CPPFLAGS
      export CFLAGS
      export CXXFLAGS
      export LDFLAGS

      if [ ! -f "config.status" ]
      then
        (
          if [ "${IS_DEVELOP}" == "y" ]
          then
            env | sort
          fi

          echo
          echo "Running diffutils configure..."

          if [ "${IS_DEVELOP}" == "y" ]
          then
            run_verbose bash "${SOURCES_FOLDER_PATH}/${diffutils_src_folder_name}/configure" --help
          fi

          config_options=()

          config_options+=("--prefix=${BINS_INSTALL_FOLDER_PATH}")
          config_options+=("--libdir=${LIBS_INSTALL_FOLDER_PATH}/lib")
          config_options+=("--includedir=${LIBS_INSTALL_FOLDER_PATH}/include")
          # config_options+=("--datarootdir=${LIBS_INSTALL_FOLDER_PATH}/share")
          config_options+=("--mandir=${LIBS_INSTALL_FOLDER_PATH}/share/man")

          config_options+=("--build=${BUILD}")
          config_options+=("--host=${HOST}")
          config_options+=("--target=${TARGET}")

          run_verbose bash ${DEBUG} "${SOURCES_FOLDER_PATH}/${diffutils_src_folder_name}/configure" \
            "${config_options[@]}"

          cp "config.log" "${LOGS_FOLDER_PATH}/${diffutils_folder_name}/config-log-$(ndate).txt"
        ) 2>&1 | tee "${LOGS_FOLDER_PATH}/${diffutils_folder_name}/configure-output-$(ndate).txt"
      fi

      (
        echo
        echo "Running diffutils make..."

        # Build.
        run_verbose make -j ${JOBS}

        # make install-strip
        run_verbose make install-exec

        if [ "${WITH_TESTS}" == "y" ]
        then
          # WARN-TEST
          run_verbose make -j1 check
        fi

      ) 2>&1 | tee "${LOGS_FOLDER_PATH}/${diffutils_folder_name}/make-output-$(ndate).txt"

      copy_license \
        "${SOURCES_FOLDER_PATH}/${diffutils_src_folder_name}" \
        "${diffutils_folder_name}"
    )

    (
      test_diffutils
    ) 2>&1 | tee "${LOGS_FOLDER_PATH}/${diffutils_folder_name}/test-output-$(ndate).txt"

    hash -r

    touch "${diffutils_stamp_file_path}"

  else
    echo "Component diffutils already installed."
  fi

  test_functions+=("test_diffutils")
}

function test_diffutils()
{
  (
    # xbb_activate_installed_bin

    echo
    echo "Checking the diffutils binaries shared libraries..."

    show_libs "${TEST_PATH}/bin/diff"
    show_libs "${TEST_PATH}/bin/cmp"
    show_libs "${TEST_PATH}/bin/diff3"
    show_libs "${TEST_PATH}/bin/sdiff"

    echo
    echo "Testing if diffutils binaries start properly..."

    run_app "${TEST_PATH}/bin/diff" --version
    run_app "${TEST_PATH}/bin/cmp" --version
    run_app "${TEST_PATH}/bin/diff3" --version
    run_app "${TEST_PATH}/bin/sdiff" --version
  )
}

# -----------------------------------------------------------------------------

function build_bison()
{
  # https://www.gnu.org/software/bison/
  # https://ftp.gnu.org/gnu/bison/

  # https://archlinuxarm.org/packages/aarch64/bison/files/PKGBUILD
  # https://aur.archlinux.org/cgit/aur.git/tree/PKGBUILD?h=bison-git

  # 2015-01-23, "3.0.4"
  # 2019-02-03, "3.3.2", Crashes with Abort trap 6.
  # 2019-09-12, "3.4.2"
  # 2019-12-11, "3.5"
  # 2020-07-23, "3.7"
  # 2021-09-25, "3.8.2"

  local bison_version="$1"

  local bison_src_folder_name="bison-${bison_version}"

  local bison_archive="${bison_src_folder_name}.tar.xz"
  local bison_url="https://ftp.gnu.org/gnu/bison/${bison_archive}"

  local bison_folder_name="${bison_src_folder_name}"

  local bison_stamp_file_path="${STAMPS_FOLDER_PATH}/stamp-${bison_folder_name}-installed"
  if [ ! -f "${bison_stamp_file_path}" ]
  then

    cd "${SOURCES_FOLDER_PATH}"

    download_and_extract "${bison_url}" "${bison_archive}" \
      "${bison_src_folder_name}"

    mkdir -pv "${LOGS_FOLDER_PATH}/${bison_folder_name}"

    (
      mkdir -pv "${BUILD_FOLDER_PATH}/${bison_folder_name}"
      cd "${BUILD_FOLDER_PATH}/${bison_folder_name}"

      xbb_activate_installed_dev

      CPPFLAGS="${XBB_CPPFLAGS}"
      CFLAGS="${XBB_CFLAGS_NO_W}"
      CXXFLAGS="${XBB_CXXFLAGS_NO_W}"

      LDFLAGS="${XBB_LDFLAGS_APP_STATIC_GCC}"
      if [ "${TARGET_PLATFORM}" == "linux" ]
      then
        LDFLAGS+=" -Wl,-rpath,${LD_LIBRARY_PATH}"
      fi

      if [ "${TARGET_PLATFORM}" == "linux" ]
      then
        # undefined reference to `clock_gettime' on docker
        export LIBS="-lrt"
      fi

      export CPPFLAGS
      export CFLAGS
      export CXXFLAGS
      export LDFLAGS

      if [ ! -f "config.status" ]
      then
        (
          if [ "${IS_DEVELOP}" == "y" ]
          then
            env | sort
          fi

          echo
          echo "Running bison configure..."

          if [ "${IS_DEVELOP}" == "y" ]
          then
            run_verbose bash "${SOURCES_FOLDER_PATH}/${bison_src_folder_name}/configure" --help
          fi

          config_options=()

          config_options+=("--prefix=${BINS_INSTALL_FOLDER_PATH}")
          config_options+=("--libdir=${LIBS_INSTALL_FOLDER_PATH}/lib")
          config_options+=("--includedir=${LIBS_INSTALL_FOLDER_PATH}/include")
          # config_options+=("--datarootdir=${LIBS_INSTALL_FOLDER_PATH}/share")
          config_options+=("--mandir=${LIBS_INSTALL_FOLDER_PATH}/share/man")

          config_options+=("--build=${BUILD}")
          config_options+=("--host=${HOST}")
          config_options+=("--target=${TARGET}")

          run_verbose bash ${DEBUG} "${SOURCES_FOLDER_PATH}/${bison_src_folder_name}/configure" \
            "${config_options[@]}"

          cp "config.log" "${LOGS_FOLDER_PATH}/${bison_folder_name}/config-log-$(ndate).txt"
        ) 2>&1 | tee "${LOGS_FOLDER_PATH}/${bison_folder_name}/configure-output-$(ndate).txt"
      fi

      (
        echo
        echo "Running bison make..."

        # Build.
        run_verbose make -j ${JOBS}

        # make install-strip
        run_verbose make install-exec

        # Takes too long.
        if false # [ "${RUN_LONG_TESTS}" == "y" ]
        then
          # 596, 7 failed
          make -j1 check
        fi

      ) 2>&1 | tee "${LOGS_FOLDER_PATH}/${bison_folder_name}/make-output-$(ndate).txt"

      copy_license \
        "${SOURCES_FOLDER_PATH}/${bison_src_folder_name}" \
        "${bison_folder_name}"
    )

    (
      test_bison
    ) 2>&1 | tee "${LOGS_FOLDER_PATH}/${bison_folder_name}/test-output-$(ndate).txt"

    hash -r

    touch "${bison_stamp_file_path}"

  else
    echo "Component bison already installed."
  fi

  test_functions+=("test_bison")
}

function test_bison()
{
  (
    # xbb_activate_installed_bin

    echo
    echo "Checking the bison binaries shared libraries..."

    show_libs "${TEST_PATH}/bin/bison"
    # yacc is a script.

    echo
    echo "Testing if bison binaries start properly..."

    run_app "${TEST_PATH}/bin/bison" --version
    run_app "${TEST_PATH}/bin/yacc" --version
  )
}

# -----------------------------------------------------------------------------

function build_make()
{
  # https://www.gnu.org/software/make/
  # https://ftp.gnu.org/gnu/make/

  # https://archlinuxarm.org/packages/aarch64/make/files/PKGBUILD
  # https://aur.archlinux.org/cgit/aur.git/tree/PKGBUILD?h=make-git

  # https://github.com/Homebrew/homebrew-core/blob/master/Formula/make.rb

  # 2016-06-10, "4.2.1"
  # 2020-01-19, "4.3"

  local make_version="$1"

  local make_src_folder_name="make-${make_version}"

  # bz2 available up to 4.2.1, gz available on all.
  local make_archive="${make_src_folder_name}.tar.gz"
  local make_url="https://ftp.gnu.org/gnu/make/${make_archive}"

  local make_folder_name="${make_src_folder_name}"

  # Patch to fix the alloca bug.
  # glob/libglob.a(glob.o): In function `glob_in_dir':
  # glob.c:(.text.glob_in_dir+0x90): undefined reference to `__alloca'

  local make_patch_file_path="${helper_folder_path}/patches/${make_folder_name}.patch"
  local make_stamp_file_path="${STAMPS_FOLDER_PATH}/stamp-${make_folder_name}-installed"
  if [ ! -f "${make_stamp_file_path}" ]
  then

    cd "${SOURCES_FOLDER_PATH}"

    download_and_extract "${make_url}" "${make_archive}" \
      "${make_src_folder_name}" \
      "${make_patch_file_path}"

    mkdir -pv "${LOGS_FOLDER_PATH}/${make_folder_name}"

    (
      mkdir -pv "${BUILD_FOLDER_PATH}/${make_folder_name}"
      cd "${BUILD_FOLDER_PATH}/${make_folder_name}"

      xbb_activate_installed_dev

      CPPFLAGS="${XBB_CPPFLAGS}"
      CFLAGS="${XBB_CFLAGS_NO_W}"
      CXXFLAGS="${XBB_CXXFLAGS_NO_W}"

      LDFLAGS="${XBB_LDFLAGS_APP_STATIC_GCC}"
      if [ "${TARGET_PLATFORM}" == "linux" ]
      then
        LDFLAGS+=" -Wl,-rpath,${LD_LIBRARY_PATH}"
      fi

      export CPPFLAGS
      export CFLAGS
      export CXXFLAGS
      export LDFLAGS

      if [ ! -f "config.status" ]
      then
        (
          if [ "${IS_DEVELOP}" == "y" ]
          then
            env | sort
          fi

          echo
          echo "Running make configure..."

          if [ "${IS_DEVELOP}" == "y" ]
          then
            run_verbose bash "${SOURCES_FOLDER_PATH}/${make_src_folder_name}/configure" --help
          fi

          config_options=()

          config_options+=("--prefix=${BINS_INSTALL_FOLDER_PATH}")
          config_options+=("--libdir=${LIBS_INSTALL_FOLDER_PATH}/lib")
          config_options+=("--includedir=${LIBS_INSTALL_FOLDER_PATH}/include")
          # config_options+=("--datarootdir=${LIBS_INSTALL_FOLDER_PATH}/share")
          config_options+=("--mandir=${LIBS_INSTALL_FOLDER_PATH}/share/man")

          config_options+=("--build=${BUILD}")
          config_options+=("--host=${HOST}")
          config_options+=("--target=${TARGET}")

          config_options+=("--program-prefix=g")

          run_verbose bash ${DEBUG} "${SOURCES_FOLDER_PATH}/${make_src_folder_name}/configure" \
            "${config_options[@]}"

          cp "config.log" "${LOGS_FOLDER_PATH}/${make_folder_name}/config-log-$(ndate).txt"
        ) 2>&1 | tee "${LOGS_FOLDER_PATH}/${make_folder_name}/configure-output-$(ndate).txt"
      fi

      (
        echo
        echo "Running make make..."

        # Build.
        run_verbose make -j ${JOBS}

        # make install-strip
        run_verbose make install-exec

        (
          echo
          echo "Linking gmake -> make..."
          cd "${BINS_INSTALL_FOLDER_PATH}/bin"
          rm -fv make
          ln -sv gmake make
        )

        # Takes too long.
        if false # [ "${RUN_LONG_TESTS}" == "y" ]
        then
          # 2 wildcard tests fail
          # WARN-TEST
          make -k check
        fi

      ) 2>&1 | tee "${LOGS_FOLDER_PATH}/${make_folder_name}/make-output-$(ndate).txt"

      copy_license \
        "${SOURCES_FOLDER_PATH}/${make_src_folder_name}" \
        "${make_folder_name}"
    )

    (
      test_make
    ) 2>&1 | tee "${LOGS_FOLDER_PATH}/${make_folder_name}/test-output-$(ndate).txt"

    hash -r

    touch "${make_stamp_file_path}"

  else
    echo "Component make already installed."
  fi

  test_functions+=("test_make")
}

function test_make()
{
  (
    # xbb_activate_installed_bin

    echo
    echo "Checking the make binaries shared libraries..."

    show_libs "${TEST_PATH}/bin/gmake"

    echo
    echo "Testing if make binaries start properly..."

    run_app "${TEST_PATH}/bin/gmake" --version
  )
}

# -----------------------------------------------------------------------------

function build_bash()
{
  # https://www.gnu.org/software/bash/
  # https://ftp.gnu.org/gnu/bash/
  # https://ftp.gnu.org/gnu/bash/bash-5.0.tar.gz

  # https://archlinuxarm.org/packages/aarch64/bash/files/PKGBUILD

  # 2018-01-30, "4.4.18"
  # 2019-01-07, "5.0"
  # 2020-12-06, "5.1"
  # 2021-06-15, "5.1.8"

  local bash_version="$1"

  local bash_src_folder_name="bash-${bash_version}"

  local bash_archive="${bash_src_folder_name}.tar.gz"
  local bash_url="https://ftp.gnu.org/gnu/bash/${bash_archive}"

  local bash_folder_name="${bash_src_folder_name}"

  local bash_stamp_file_path="${STAMPS_FOLDER_PATH}/stamp-${bash_folder_name}-installed"
  if [ ! -f "${bash_stamp_file_path}" ]
  then

    cd "${SOURCES_FOLDER_PATH}"

    download_and_extract "${bash_url}" "${bash_archive}" \
      "${bash_src_folder_name}"

    mkdir -pv "${LOGS_FOLDER_PATH}/${bash_folder_name}"

    (
      mkdir -pv "${BUILD_FOLDER_PATH}/${bash_folder_name}"
      cd "${BUILD_FOLDER_PATH}/${bash_folder_name}"

      xbb_activate_installed_dev

      CPPFLAGS="${XBB_CPPFLAGS}"
      CFLAGS="${XBB_CFLAGS_NO_W}"
      CXXFLAGS="${XBB_CXXFLAGS_NO_W}"

      LDFLAGS="${XBB_LDFLAGS_APP_STATIC_GCC}"
      if [ "${TARGET_PLATFORM}" == "linux" ]
      then
        LDFLAGS+=" -Wl,-rpath,${LD_LIBRARY_PATH}"
      fi

      export CPPFLAGS
      export CFLAGS
      export CXXFLAGS
      export LDFLAGS

      if [ ! -f "config.status" ]
      then
        (
          if [ "${IS_DEVELOP}" == "y" ]
          then
            env | sort
          fi

          echo
          echo "Running bash configure..."

          if [ "${IS_DEVELOP}" == "y" ]
          then
            run_verbose bash "${SOURCES_FOLDER_PATH}/${bash_src_folder_name}/configure" --help
          fi

          config_options=()

          config_options+=("--prefix=${BINS_INSTALL_FOLDER_PATH}")
          # config_options+=("--libdir=${LIBS_INSTALL_FOLDER_PATH}/lib")
          config_options+=("--includedir=${LIBS_INSTALL_FOLDER_PATH}/include")
          # config_options+=("--datarootdir=${LIBS_INSTALL_FOLDER_PATH}/share")
          config_options+=("--mandir=${LIBS_INSTALL_FOLDER_PATH}/share/man")

          config_options+=("--build=${BUILD}")
          config_options+=("--host=${HOST}")
          config_options+=("--target=${TARGET}")

          config_options+=("--with-curses")
          config_options+=("--with-installed-readline")
          config_options+=("--enable-readline")
          config_options+=("--disable-rpath")

          run_verbose bash ${DEBUG} "${SOURCES_FOLDER_PATH}/${bash_src_folder_name}/configure" \
            "${config_options[@]}"

          cp "config.log" "${LOGS_FOLDER_PATH}/${bash_folder_name}/config-log-$(ndate).txt"
        ) 2>&1 | tee "${LOGS_FOLDER_PATH}/${bash_folder_name}/configure-output-$(ndate).txt"
      fi

      (
        echo
        echo "Running bash make..."

        # Build.
        run_verbose make -j ${JOBS}

        # make install-strip
        run_verbose make install

        if false # [ "${RUN_LONG_TESTS}" == "y" ]
        then
          run_verbose make -j1 check
        fi

      ) 2>&1 | tee "${LOGS_FOLDER_PATH}/${bash_folder_name}/make-output-$(ndate).txt"

      copy_license \
        "${SOURCES_FOLDER_PATH}/${bash_src_folder_name}" \
        "${bash_folder_name}"
    )

    (
      test_bash
    ) 2>&1 | tee "${LOGS_FOLDER_PATH}/${bash_folder_name}/test-output-$(ndate).txt"

    hash -r

    touch "${bash_stamp_file_path}"

  else
    echo "Component bash already installed."
  fi

  test_functions+=("test_bash")
}

function test_bash()
{
  (
    # xbb_activate_installed_bin

    echo
    echo "Checking the bash binaries shared libraries..."

    show_libs "${TEST_PATH}/bin/bash"

    echo
    echo "Testing if bash binaries start properly..."

    run_app "${TEST_PATH}/bin/bash" --version

    echo
    echo "Testing if bash binaries display help..."

    run_app "${TEST_PATH}/bin/bash" --help
  )
}

# -----------------------------------------------------------------------------

function build_wget()
{
  # https://www.gnu.org/software/wget/
  # https://ftp.gnu.org/gnu/wget/

  # https://archlinuxarm.org/packages/aarch64/wget/files/PKGBUILD
  # https://git.archlinux.org/svntogit/packages.git/tree/trunk/PKGBUILD?h=packages/wget
  # https://aur.archlinux.org/cgit/aur.git/tree/PKGBUILD?h=wget-git

  # 2016-06-10, "1.19"
  # 2018-12-26, "1.20.1"
  # 2019-04-05, "1.20.3"

  # fails on macOS with
  # lib/malloc/dynarray-skeleton.c:195:13: error: expected identifier or '(' before numeric constant
  # 195 | __nonnull ((1))
  # 2021-01-09, "1.21.1"
  # 2021-09-07, "1.21.2"

  local wget_version="$1"

  local wget_src_folder_name="wget-${wget_version}"

  local wget_archive="${wget_src_folder_name}.tar.gz"
  local wget_url="https://ftp.gnu.org/gnu/wget/${wget_archive}"

  local wget_folder_name="${wget_src_folder_name}"

  local wget_stamp_file_path="${STAMPS_FOLDER_PATH}/stamp-${wget_folder_name}-installed"
  if [ ! -f "${wget_stamp_file_path}" ]
  then

    cd "${SOURCES_FOLDER_PATH}"

    download_and_extract "${wget_url}" "${wget_archive}" \
      "${wget_src_folder_name}"

    mkdir -pv "${LOGS_FOLDER_PATH}/${wget_folder_name}"

    (
      mkdir -pv "${BUILD_FOLDER_PATH}/${wget_folder_name}"
      cd "${BUILD_FOLDER_PATH}/${wget_folder_name}"

      xbb_activate_installed_dev

      CPPFLAGS="${XBB_CPPFLAGS}"
      CFLAGS="${XBB_CFLAGS_NO_W}"
      CXXFLAGS="${XBB_CXXFLAGS_NO_W}"

      LDFLAGS="${XBB_LDFLAGS_APP_STATIC_GCC}"
      if [ "${TARGET_PLATFORM}" == "linux" ]
      then
        LDFLAGS+=" -Wl,-rpath,${LD_LIBRARY_PATH}"
      fi

      # Might be needed on Mac
      # export LIBS="-liconv"

      export CPPFLAGS
      export CFLAGS
      export CXXFLAGS
      export LDFLAGS

      if [ ! -f "config.status" ]
      then
        (
          if [ "${IS_DEVELOP}" == "y" ]
          then
            env | sort
          fi

          echo
          echo "Running wget configure..."

          if [ "${IS_DEVELOP}" == "y" ]
          then
            run_verbose bash "${SOURCES_FOLDER_PATH}/${wget_src_folder_name}/configure" --help
          fi

          config_options=()

          config_options+=("--prefix=${BINS_INSTALL_FOLDER_PATH}")
          config_options+=("--libdir=${LIBS_INSTALL_FOLDER_PATH}/lib")
          config_options+=("--includedir=${LIBS_INSTALL_FOLDER_PATH}/include")
          # config_options+=("--datarootdir=${LIBS_INSTALL_FOLDER_PATH}/share")
          config_options+=("--mandir=${LIBS_INSTALL_FOLDER_PATH}/share/man")

          config_options+=("--build=${BUILD}")
          config_options+=("--host=${HOST}")
          config_options+=("--target=${TARGET}")

          config_options+=("--with-ssl=gnutls")
          config_options+=("--with-metalink")
          config_options+=("--without-libpsl")

          config_options+=("--enable-nls")
          config_options+=("--disable-debug")
          config_options+=("--disable-pcre")
          config_options+=("--disable-pcre2")

          # libpsl is not available anyway.
          run_verbose bash ${DEBUG} "${SOURCES_FOLDER_PATH}/${wget_src_folder_name}/configure" \
            "${config_options[@]}"

          cp "config.log" "${LOGS_FOLDER_PATH}/${wget_folder_name}/config-log-$(ndate).txt"
        ) 2>&1 | tee "${LOGS_FOLDER_PATH}/${wget_folder_name}/configure-output-$(ndate).txt"
      fi

      (
        echo
        echo "Running wget make..."

        # Build.
        run_verbose make -j ${JOBS}

        # make install-strip
        run_verbose make install-exec

        # Fails
        # x86_64: FAIL:  65
        # WARN-TEST
        # make -j1 check

      ) 2>&1 | tee "${LOGS_FOLDER_PATH}/${wget_folder_name}/make-output-$(ndate).txt"

      copy_license \
        "${SOURCES_FOLDER_PATH}/${wget_src_folder_name}" \
        "${wget_folder_name}"
    )

    (
      test_wget
    ) 2>&1 | tee "${LOGS_FOLDER_PATH}/${wget_folder_name}/test-output-$(ndate).txt"

    hash -r

    touch "${wget_stamp_file_path}"

  else
    echo "Component wget already installed."
  fi

  test_functions+=("test_wget")
}

function test_wget()
{
  (
    # xbb_activate_installed_bin

    echo
    echo "Checking the wget binaries shared libraries..."

    show_libs "${TEST_PATH}/bin/wget"

    echo
    echo "Testing if wget binaries start properly..."

    run_app "${TEST_PATH}/bin/wget" --version
  )
}

# -----------------------------------------------------------------------------

function build_texinfo()
{
  # https://www.gnu.org/software/texinfo/
  # https://ftp.gnu.org/gnu/texinfo/

  # https://archlinuxarm.org/packages/aarch64/texinfo/files/PKGBUILD
  # https://aur.archlinux.org/cgit/aur.git/tree/PKGBUILD?h=texinfo-svn

  # 2017-09-12, "6.5"
  # 2019-02-16, "6.6"
  # 2019-09-23, "6.7"
  # 2021-07-03, "6.8"

  local texinfo_version="$1"

  local texinfo_src_folder_name="texinfo-${texinfo_version}"

  local texinfo_archive="${texinfo_src_folder_name}.tar.gz"
  local texinfo_url="https://ftp.gnu.org/gnu/texinfo/${texinfo_archive}"

  local texinfo_folder_name="${texinfo_src_folder_name}"

  local texinfo_stamp_file_path="${STAMPS_FOLDER_PATH}/stamp-${texinfo_folder_name}-installed"
  if [ ! -f "${texinfo_stamp_file_path}" ]
  then

    cd "${SOURCES_FOLDER_PATH}"

    download_and_extract "${texinfo_url}" "${texinfo_archive}" \
      "${texinfo_src_folder_name}"

    mkdir -pv "${LOGS_FOLDER_PATH}/${texinfo_folder_name}"

    (
      mkdir -pv "${BUILD_FOLDER_PATH}/${texinfo_folder_name}"
      cd "${BUILD_FOLDER_PATH}/${texinfo_folder_name}"

      xbb_activate_installed_dev

      CPPFLAGS="${XBB_CPPFLAGS}"
      CFLAGS="${XBB_CFLAGS_NO_W}"
      CXXFLAGS="${XBB_CXXFLAGS_NO_W}"

      LDFLAGS="${XBB_LDFLAGS_APP_STATIC_GCC}"
      if [ "${TARGET_PLATFORM}" == "linux" ]
      then
        LDFLAGS+=" -Wl,-rpath,${LD_LIBRARY_PATH}"
      fi

      export CPPFLAGS
      export CFLAGS
      export CXXFLAGS
      export LDFLAGS

      if [ ! -f "config.status" ]
      then
        (
          if [ "${IS_DEVELOP}" == "y" ]
          then
            env | sort
          fi

          echo
          echo "Running texinfo configure..."

          if [ "${IS_DEVELOP}" == "y" ]
          then
            run_verbose bash "${SOURCES_FOLDER_PATH}/${texinfo_src_folder_name}/configure" --help
          fi

          config_options=()

          config_options+=("--prefix=${BINS_INSTALL_FOLDER_PATH}")
          config_options+=("--libdir=${LIBS_INSTALL_FOLDER_PATH}/lib")
          config_options+=("--includedir=${LIBS_INSTALL_FOLDER_PATH}/include")
          # config_options+=("--datarootdir=${LIBS_INSTALL_FOLDER_PATH}/share")
          config_options+=("--mandir=${LIBS_INSTALL_FOLDER_PATH}/share/man")

          config_options+=("--build=${BUILD}")
          config_options+=("--host=${HOST}")
          config_options+=("--target=${TARGET}")

          run_verbose bash ${DEBUG} "${SOURCES_FOLDER_PATH}/${texinfo_src_folder_name}/configure" \
            "${config_options[@]}"

          cp "config.log" "${LOGS_FOLDER_PATH}/${texinfo_folder_name}/config-log-$(ndate).txt"
        ) 2>&1 | tee "${LOGS_FOLDER_PATH}/${texinfo_folder_name}/configure-output-$(ndate).txt"
      fi

      (
        echo
        echo "Running texinfo make..."

        # Build.
        run_verbose make -j ${JOBS}

        # make install-strip
        run_verbose make install

        # Darwin: FAIL: t/94htmlxref.t 11 - htmlxref errors file_html
        # Darwin: ERROR: t/94htmlxref.t - exited with status 2

        if [ "${WITH_TESTS}" == "y" ]
        then
          if false # is_darwin
          then
            run_verbose make -j1 check || true
          else
            run_verbose make -j1 check
          fi
        fi

      ) 2>&1 | tee "${LOGS_FOLDER_PATH}/${texinfo_folder_name}/make-output-$(ndate).txt"

      copy_license \
        "${SOURCES_FOLDER_PATH}/${texinfo_src_folder_name}" \
        "${texinfo_folder_name}"
    )

    (
      test_texinfo
    ) 2>&1 | tee "${LOGS_FOLDER_PATH}/${texinfo_folder_name}/test-output-$(ndate).txt"

    hash -r

    touch "${texinfo_stamp_file_path}"

  else
    echo "Component texinfo already installed."
  fi

  test_functions+=("test_texinfo")
}

function test_texinfo()
{
  (
    # xbb_activate_installed_bin

    echo
    echo "Testing if texinfo scripts start properly..."

    run_app "${TEST_PATH}/bin/texi2pdf" --version

    # No ELFs, it is a script.
  )
}

# -----------------------------------------------------------------------------

function build_dos2unix()
{
  # https://waterlan.home.xs4all.nl/dos2unix.html
  # http://dos2unix.sourceforge.net
  # https://waterlan.home.xs4all.nl/dos2unix/dos2unix-7.4.0.tar.

  # https://archlinuxarm.org/packages/aarch64/dos2unix/files/PKGBUILD

  # 30-Oct-2017, "7.4.0"
  # 2019-09-24, "7.4.1"
  # 2020-10-12, "7.4.2"

  local dos2unix_version="$1"

  local dos2unix_src_folder_name="dos2unix-${dos2unix_version}"

  local dos2unix_archive="${dos2unix_src_folder_name}.tar.gz"
  local dos2unix_url="https://waterlan.home.xs4all.nl/dos2unix/${dos2unix_archive}"

  local dos2unix_folder_name="${dos2unix_src_folder_name}"

  local dos2unix_stamp_file_path="${STAMPS_FOLDER_PATH}/stamp-${dos2unix_folder_name}-installed"
  if [ ! -f "${dos2unix_stamp_file_path}" ]
  then

    echo
    echo "dos2unix in-source building"

    if [ ! -d "${BUILD_FOLDER_PATH}/${dos2unix_folder_name}" ]
    then
      cd "${BUILD_FOLDER_PATH}"

      download_and_extract "${dos2unix_url}" "${dos2unix_archive}" \
        "${dos2unix_src_folder_name}"

      if [ "${dos2unix_src_folder_name}" != "${dos2unix_folder_name}" ]
      then
        mv -v "${dos2unix_src_folder_name}" "${dos2unix_folder_name}"
      fi
    fi

    mkdir -pv "${LOGS_FOLDER_PATH}/${dos2unix_folder_name}"

    (
      mkdir -pv "${BUILD_FOLDER_PATH}/${dos2unix_folder_name}"
      cd "${BUILD_FOLDER_PATH}/${dos2unix_folder_name}"

      xbb_activate_installed_dev

      CPPFLAGS="${XBB_CPPFLAGS}"
      CFLAGS="${XBB_CFLAGS_NO_W}"
      CXXFLAGS="${XBB_CXXFLAGS_NO_W}"

      LDFLAGS="${XBB_LDFLAGS_APP_STATIC_GCC}"
      if [ "${TARGET_PLATFORM}" == "linux" ]
      then
        LDFLAGS+=" -Wl,-rpath,${LD_LIBRARY_PATH}"
      fi

      export CPPFLAGS
      export CFLAGS
      export CXXFLAGS
      export LDFLAGS

      (
        if [ "${IS_DEVELOP}" == "y" ]
        then
          env | sort
        fi

        echo
        echo "Running dos2unix make..."

        # Build.
        run_verbose make -j ${JOBS} prefix="${BINS_INSTALL_FOLDER_PATH}" ENABLE_NLS=

        run_verbose make prefix="${BINS_INSTALL_FOLDER_PATH}" install

        if [ "${WITH_TESTS}" == "y" ]
        then
          if [ "${TARGET_PLATFORM}" == "darwin" ]
          then
            #   Failed test 'dos2unix convert DOS UTF-16LE to Unix GB18030'
            #   at utf16_gb.t line 27.
            #   Failed test 'dos2unix convert DOS UTF-16LE to Unix GB18030, keep BOM'
            #   at utf16_gb.t line 30.
            #   Failed test 'unix2dos convert DOS UTF-16BE to DOS GB18030, keep BOM'
            #   at utf16_gb.t line 33.
            : # run_verbose make -j1 check || true
          else
            run_verbose make -j1 check
          fi
        fi

      ) 2>&1 | tee "${LOGS_FOLDER_PATH}/${dos2unix_folder_name}/make-output-$(ndate).txt"

      copy_license \
        "${BUILD_FOLDER_PATH}/${dos2unix_folder_name}" \
        "${dos2unix_folder_name}"
    )

    (
      test_dos2unix
    ) 2>&1 | tee "${LOGS_FOLDER_PATH}/${dos2unix_folder_name}/test-output-$(ndate).txt"

    hash -r

    touch "${dos2unix_stamp_file_path}"

  else
    echo "Component dos2unix already installed."
  fi

  test_functions+=("test_dos2unix")
}

function test_dos2unix()
{
  (
    # xbb_activate_installed_bin

    echo
    echo "Checking the dos2unix binaries shared libraries..."

    show_libs "${TEST_PATH}/bin/unix2dos"
    show_libs "${TEST_PATH}/bin/dos2unix"

    echo
    echo "Testing if dos2unix binaries start properly..."

    run_app "${TEST_PATH}/bin/unix2dos" --version
    run_app "${TEST_PATH}/bin/dos2unix" --version
  )
}

# -----------------------------------------------------------------------------

function build_flex()
{
  # https://www.gnu.org/software/flex/
  # https://github.com/westes/flex/releases
  # https://github.com/westes/flex/releases/download/v2.6.4/flex-2.6.4.tar.gz

  # https://archlinuxarm.org/packages/aarch64/flex/files/PKGBUILD
  # https://aur.archlinux.org/cgit/aur.git/tree/PKGBUILD?h=flex-git

  # https://github.com/Homebrew/homebrew-core/blob/master/Formula/flex.rb

  # Apple uses 2.5.3
  # Ubuntu 12 uses 2.5.35

  # 30 Dec 2016, "2.6.3"
  # On Ubuntu 18, it fails while building wine with
  # /opt/xbb/lib/gcc/x86_64-w64-mingw32/9.2.0/../../../../x86_64-w64-mingw32/bin/ld: macro.lex.yy.cross.o: in function `yylex':
  # /root/Work/xbb-3.1-ubuntu-18.04-x86_64/build/wine-5.1/programs/winhlp32/macro.lex.yy.c:1031: undefined reference to `yywrap'
  # collect2: error: ld returned 1 exit status

  # May 6, 2017, "2.6.4" (latest)
  # On Ubuntu 18 it crashes (due to an autotool issue) with
  # ./stage1flex   -o stage1scan.c /home/ilg/Work/xbb-bootstrap/sources/flex-2.6.4/src/scan.l
  # make[2]: *** [Makefile:1696: stage1scan.c] Segmentation fault (core dumped)
  # The patch from Arch should fix it.
  # https://archlinuxarm.org/packages/aarch64/flex/files/flex-pie.patch

  local flex_version="$1"

  local flex_src_folder_name="flex-${flex_version}"

  local flex_archive="${flex_src_folder_name}.tar.gz"
  local flex_url="https://github.com/westes/flex/releases/download/v${flex_version}/${flex_archive}"

  local flex_folder_name="${flex_src_folder_name}"

  local flex_patch_file_path="${helper_folder_path}/patches/${flex_folder_name}.patch"
  local flex_stamp_file_path="${STAMPS_FOLDER_PATH}/stamp-${flex_folder_name}-installed"
  if [ ! -f "${flex_stamp_file_path}" ]
  then

    cd "${SOURCES_FOLDER_PATH}"

    download_and_extract "${flex_url}" "${flex_archive}" \
      "${flex_src_folder_name}" \
      "${flex_patch_file_path}"

    mkdir -pv "${LOGS_FOLDER_PATH}/${flex_folder_name}"

    (
      cd "${SOURCES_FOLDER_PATH}/${flex_src_folder_name}"
      if [ ! -f "stamp-autogen" ]
      then

        xbb_activate_installed_dev

        run_verbose bash ${DEBUG} "autogen.sh"

        # No longer needed, done in libtool.
        # patch -p0 <"${helper_folder_path}/patches/flex-2.4.6-libtool.patch"

        touch "stamp-autogen"

      fi
    ) 2>&1 | tee "${LOGS_FOLDER_PATH}/${flex_folder_name}/autogen-output-$(ndate).txt"

    (
      mkdir -pv "${BUILD_FOLDER_PATH}/${flex_folder_name}"
      cd "${BUILD_FOLDER_PATH}/${flex_folder_name}"

      xbb_activate_installed_dev

      CPPFLAGS="${XBB_CPPFLAGS}"
      CFLAGS="${XBB_CFLAGS_NO_W}"
      CXXFLAGS="${XBB_CXXFLAGS_NO_W}"

      LDFLAGS="${XBB_LDFLAGS_APP_STATIC_GCC}"
      if [ "${TARGET_PLATFORM}" == "linux" ]
      then
        LDFLAGS+=" -Wl,-rpath,${LD_LIBRARY_PATH}"
      fi

      export CPPFLAGS
      export CFLAGS
      export CXXFLAGS
      export LDFLAGS

      if [ ! -f "config.status" ]
      then
        (
          if [ "${IS_DEVELOP}" == "y" ]
          then
            env | sort
          fi

          echo
          echo "Running flex configure..."

          if [ "${IS_DEVELOP}" == "y" ]
          then
            run_verbose bash "${SOURCES_FOLDER_PATH}/${flex_src_folder_name}/configure" --help
          fi

          config_options=()

          config_options+=("--prefix=${BINS_INSTALL_FOLDER_PATH}")
          config_options+=("--libdir=${LIBS_INSTALL_FOLDER_PATH}/lib")
          config_options+=("--includedir=${LIBS_INSTALL_FOLDER_PATH}/include")
          # config_options+=("--datarootdir=${LIBS_INSTALL_FOLDER_PATH}/share")
          config_options+=("--mandir=${LIBS_INSTALL_FOLDER_PATH}/share/man")

          config_options+=("--build=${BUILD}")
          config_options+=("--host=${HOST}")
          config_options+=("--target=${TARGET}")

          run_verbose bash ${DEBUG} "${SOURCES_FOLDER_PATH}/${flex_src_folder_name}/configure" \
            "${config_options[@]}"

          cp "config.log" "${LOGS_FOLDER_PATH}/${flex_folder_name}/config-log-$(ndate).txt"
        ) 2>&1 | tee "${LOGS_FOLDER_PATH}/${flex_folder_name}/configure-output-$(ndate).txt"
      fi

      (
        echo
        echo "Running flex make..."

        # Build.
        run_verbose make -j ${JOBS}

        # make install-strip
        run_verbose make install

        if [ "${WITH_TESTS}" == "y" ]
        then
          # cxx_restart fails - https://github.com/westes/flex/issues/98
          # make -k check || true
          if [ "${TARGET_PLATFORM}" == "darwin" ] && [ "${TARGET_ARCH}" == "arm64" ]
          then
            : # Fails with internal error, caused by gm4
          else
            run_verbose make -k check
          fi
        fi

      ) 2>&1 | tee "${LOGS_FOLDER_PATH}/${flex_folder_name}/make-output-$(ndate).txt"

      copy_license \
        "${SOURCES_FOLDER_PATH}/${flex_src_folder_name}" \
        "${flex_folder_name}"
    )

    (
      test_flex
    ) 2>&1 | tee "${LOGS_FOLDER_PATH}/${flex_folder_name}/test-output-$(ndate).txt"

    hash -r

    touch "${flex_stamp_file_path}"

  else
    echo "Component flex already installed."
  fi

  test_functions+=("test_flex")
}

function test_flex()
{
  (
    # xbb_activate_installed_bin

    echo
    echo "Checking the flex shared libraries..."

    show_libs "${TEST_PATH}/bin/flex"
    show_libs "$(realpath ${LIBS_INSTALL_FOLDER_PATH}/lib/libfl.${SHLIB_EXT})"

    echo
    echo "Testing if flex binaries start properly..."

    run_app "${TEST_PATH}/bin/flex" --version
  )
}

# -----------------------------------------------------------------------------

function build_perl()
{
  # https://www.cpan.org
  # http://www.cpan.org/src/

  # https://archlinuxarm.org/packages/aarch64/perl/files/PKGBUILD
  # https://git.archlinux.org/svntogit/packages.git/tree/trunk/PKGBUILD?h=packages/perl

  # https://github.com/Homebrew/homebrew-core/blob/master/Formula/perl.rb

  # Fails to build on macOS

  # 2014-10-02, "5.18.4" (10.10 uses 5.18.2)
  # 2015-09-12, "5.20.3"
  # 2017-07-15, "5.22.4"
  # 2018-04-14, "5.24.4" # Fails in bootstrap on mac.
  # 2018-11-29, "5.26.3" # Fails in bootstrap on mac.
  # 2019-04-19, "5.28.2" # Fails in bootstrap on mac.
  # 2019-11-10, "5.30.1"
  # 2021-05-20, "5.34.0"

  PERL_VERSION="$1"
  local perl_version_major="$(echo "${PERL_VERSION}" | sed -e 's/\([0-9]*\)\..*/\1.0/')"

  local perl_src_folder_name="perl-${PERL_VERSION}"

  local perl_archive="${perl_src_folder_name}.tar.gz"
  local perl_url="http://www.cpan.org/src/${perl_version_major}/${perl_archive}"

  local perl_folder_name="${perl_src_folder_name}"

  # Fix an incompatibility with libxcrypt and glibc.
  # https://groups.google.com/forum/#!topic/perl.perl5.porters/BTMp2fQg8q4
  local perl_patch_file_path="${helper_folder_path}/patches/${perl_folder_name}.patch"
  local perl_stamp_file_path="${STAMPS_FOLDER_PATH}/stamp-${perl_folder_name}-installed"
  if [ ! -f "${perl_stamp_file_path}" ]
  then

    # In-source build.

    if [ ! -d "${BUILD_FOLDER_PATH}/${perl_folder_name}" ]
    then
      cd "${BUILD_FOLDER_PATH}"

      download_and_extract "${perl_url}" "${perl_archive}" \
        "${perl_src_folder_name}" \
        "${perl_patch_file_path}"

      if [ "${perl_src_folder_name}" != "${perl_folder_name}" ]
      then
        mv -v "${perl_src_folder_name}" "${perl_folder_name}"
      fi
    fi

    mkdir -pv "${LOGS_FOLDER_PATH}/${perl_folder_name}"

    (
      cd "${BUILD_FOLDER_PATH}/${perl_folder_name}"

      xbb_activate_installed_dev

      CPPFLAGS="${XBB_CPPFLAGS}"
      # -Wno-null-pointer-arithmetic
      CFLAGS="${XBB_CPPFLAGS} ${XBB_CFLAGS_NO_W}"
      CXXFLAGS="${XBB_CPPFLAGS} ${XBB_CXXFLAGS_NO_W}"

      LDFLAGS="${XBB_LDFLAGS_APP_STATIC_GCC}"
      if [ "${TARGET_PLATFORM}" == "linux" ]
      then
        LDFLAGS+=" -Wl,-rpath,${LD_LIBRARY_PATH}"
      fi

      if [ "${TARGET_PLATFORM}" == "linux" ]
      then
        # Required to pick libcrypt and libssp from bootstrap.
        export LD_LIBRARY_PATH="${XBB_LIBRARY_PATH}"
      fi

      export CPPFLAGS
      export CFLAGS
      export CXXFLAGS
      export LDFLAGS

      if [ ! -f "config.h" ]
      then
        (
          if [ "${IS_DEVELOP}" == "y" ]
          then
            env | sort
          fi

          echo
          echo "Running perl configure..."

          if [ "${IS_DEVELOP}" == "y" ]
          then
          run_verbose bash "./Configure" --help || true
          fi

          # -Uusedl prevents building libperl.so and so there is no need
          # worry about the weird rpath.

          run_verbose bash ${DEBUG} "./Configure" -d -e -s \
            -Dprefix="${BINS_INSTALL_FOLDER_PATH}" \
            \
            -Dcc="${CC}" \
            -Dccflags="${CFLAGS}" \
            -Dcppflags="${CPPFLAGS}" \
            -Dlddlflags="-shared ${LDFLAGS}" \
            -Dldflags="${LDFLAGS}" \
            -Duseshrplib \
            -Duselargefiles \
            -Dusethreads \
            -Uusedl \

        ) 2>&1 | tee "${LOGS_FOLDER_PATH}/${perl_folder_name}/configure-output-$(ndate).txt"
      fi

      (
        echo
        echo "Running perl make..."

        # Build.
        run_verbose make -j ${JOBS}

        # make install-strip
        run_verbose make install

        # Takes very, very long, and some fail.
        if false # [ "${RUN_LONG_TESTS}" == "y" ]
        then
          # re/regexp_nonull.t                                               (Wstat: 512 Tests: 0 Failed: 0)
          # Non-zero exit status: 2
          # Parse errors: No plan found in TAP output
          # op/sub.t                                                         (Wstat: 512 Tests: 61 Failed: 0)
          # Non-zero exit status: 2
          # Parse errors: Bad plan.  You planned 62 tests but ran 61.
          # porting/manifest.t                                               (Wstat: 0 Tests: 10399 Failed: 2)
          # Failed tests:  9648, 9930
          # porting/test_bootstrap.t                                         (Wstat: 512 Tests: 407 Failed: 0)
          # Non-zero exit status: 2

          # WARN-TEST
          rm -rf t/re/regexp_nonull.t
          rm -rf t/op/sub.t

          run_verbose make -j1 test_harness
          run_verbose make -j1 test
        fi

        (
          xbb_activate_installed_bin

          if [ "${TARGET_PLATFORM}" == "darwin" ]
          then
            # Remove any existing .cpan
            rm -rf ${HOME}/.cpan
          fi

          # https://www.cpan.org/modules/INSTALL.html
          # Convince cpan not to ask confirmations.
          export PERL_MM_USE_DEFAULT=true
          # cpanminus is a quiet version of cpan.
          run_verbose cpan App::cpanminus
        )

      ) 2>&1 | tee "${LOGS_FOLDER_PATH}/${perl_folder_name}/make-output-$(ndate).txt"

      copy_license \
        "${BUILD_FOLDER_PATH}/${perl_folder_name}" \
        "${perl_folder_name}"
    )

    (
      test_perl
    ) 2>&1 | tee "${LOGS_FOLDER_PATH}/${perl_folder_name}/test-output-$(ndate).txt"

    hash -r

    touch "${perl_stamp_file_path}"

  else
    echo "Component perl already installed."
  fi

  test_functions+=("test_perl")
}

function test_perl()
{
  (
    # xbb_activate_installed_bin

    echo
    echo "Checking the perl binaries shared libraries..."

    show_libs "${TEST_PATH}/bin/perl"

    echo
    echo "Testing if perl binaries start properly..."

    (
      # To find libssp.so.0.
      # /opt/xbb/bin/perl: error while loading shared libraries: libssp.so.0: cannot open shared object file: No such file or directory
      if [ "${TARGET_PLATFORM}" == "linux" ]
      then
        export LD_LIBRARY_PATH="${XBB_LIBRARY_PATH}"
      fi

      run_app "${TEST_PATH}/bin/perl" --version
    )
  )
}

# -----------------------------------------------------------------------------

function build_tcl()
{
  # https://www.tcl.tk/
  # https://www.tcl.tk/software/tcltk/download.html
  # https://www.tcl.tk/doc/howto/compile.html

  # https://prdownloads.sourceforge.net/tcl/tcl8.6.10-src.tar.gz
  # https://sourceforge.net/projects/tcl/files/Tcl/8.6.10/tcl8.6.10-src.tar.gz/download
  # https://archlinuxarm.org/packages/aarch64/tcl/files/PKGBUILD

  # https://github.com/Homebrew/homebrew-core/blob/master/Formula/tcl-tk.rb

  # 2019-11-21, "8.6.10"
  # ? "8.6.11"
  # ? "8.6.12"

  local tcl_version="$1"

  TCL_VERSION_MAJOR="$(echo ${tcl_version} | sed -e 's|\([0-9][0-9]*\)\.\([0-9][0-9]*\)\..*|\1|')"
  TCL_VERSION_MINOR="$(echo ${tcl_version} | sed -e 's|\([0-9][0-9]*\)\.\([0-9][0-9]*\)\..*|\2|')"

  local tcl_src_folder_name="tcl${tcl_version}"

  local tcl_archive="tcl${tcl_version}-src.tar.gz"
  local tcl_url="https://sourceforge.net/projects/tcl/files/Tcl/${tcl_version}/${tcl_archive}"

  local tcl_folder_name="${tcl_src_folder_name}"

  local tcl_stamp_file_path="${STAMPS_FOLDER_PATH}/stamp-${tcl_folder_name}-installed"
  if [ ! -f "${tcl_stamp_file_path}" ]
  then

    cd "${SOURCES_FOLDER_PATH}"

    download_and_extract "${tcl_url}" "${tcl_archive}" \
      "${tcl_src_folder_name}"

    mkdir -pv "${LOGS_FOLDER_PATH}/${tcl_folder_name}"

    (
      mkdir -pv "${BUILD_FOLDER_PATH}/${tcl_folder_name}"
      cd "${BUILD_FOLDER_PATH}/${tcl_folder_name}"

      xbb_activate_installed_dev

      CPPFLAGS="${XBB_CPPFLAGS}"
      CFLAGS="${XBB_CFLAGS_NO_W}"
      CXXFLAGS="${XBB_CXXFLAGS_NO_W}"

      LDFLAGS="${XBB_LDFLAGS_APP_STATIC_GCC}"
      if [ "${TARGET_PLATFORM}" == "linux" ]
      then
        LDFLAGS+=" -Wl,-rpath,${LD_LIBRARY_PATH}"
      fi

      export CPPFLAGS
      export CFLAGS
      export CXXFLAGS
      export LDFLAGS

      if [ ! -f "config.status" ]
      then
        (
          if [ "${IS_DEVELOP}" == "y" ]
          then
            env | sort
          fi

          echo
          echo "Running tcl configure..."

          config_options=()

          config_options+=("--prefix=${BINS_INSTALL_FOLDER_PATH}")
          config_options+=("--libdir=${LIBS_INSTALL_FOLDER_PATH}/lib")
          config_options+=("--includedir=${LIBS_INSTALL_FOLDER_PATH}/include")
          # config_options+=("--datarootdir=${LIBS_INSTALL_FOLDER_PATH}/share")
          config_options+=("--mandir=${LIBS_INSTALL_FOLDER_PATH}/share/man")

          config_options+=("--build=${BUILD}")
          config_options+=("--host=${HOST}")
          config_options+=("--target=${TARGET}")

          if [ "${TARGET_PLATFORM}" == "linux" ]
          then
            if [ "${IS_DEVELOP}" == "y" ]
            then
              run_verbose bash "${SOURCES_FOLDER_PATH}/${tcl_src_folder_name}/unix/configure" --help
            fi

            config_options+=("--enable-threads")
            config_options+=("--enable-64bit")

            run_verbose bash ${DEBUG} "${SOURCES_FOLDER_PATH}/${tcl_src_folder_name}/unix/configure" \
              "${config_options[@]}"

if false
then
            run_verbose find . \
              \( -name Makefile -o -name tclConfig.sh \) \
              -print \
              -exec sed -i.bak -e 's|-Wl,-rpath,${LIB_RUNTIME_DIR}||' {} \;
fi
          elif [ "${TARGET_PLATFORM}" == "darwin" ]
          then

            if [ "${IS_DEVELOP}" == "y" ]
            then
              run_verbose bash "${SOURCES_FOLDER_PATH}/${tcl_src_folder_name}/macosx/configure" --help
            fi

            if [ "${TARGET_ARCH}" == "arm64" ]
            then
              # The current GCC 11.2 generates wrong code for this illegal option.
              run_verbose sed -i.bak \
                -e 's|EXTRA_APP_CC_SWITCHES=.-mdynamic-no-pic.|EXTRA_APP_CC_SWITCHES=""|' \
                "${SOURCES_FOLDER_PATH}/${tcl_src_folder_name}/macosx/configure"
            fi

            config_options+=("--enable-threads")
            config_options+=("--enable-64bit")

            run_verbose bash ${DEBUG} "${SOURCES_FOLDER_PATH}/${tcl_src_folder_name}/macosx/configure" \
              "${config_options[@]}"

          fi

          cp "config.log" "${LOGS_FOLDER_PATH}/${tcl_folder_name}/config-log-$(ndate).txt"
        ) 2>&1 | tee "${LOGS_FOLDER_PATH}/${tcl_folder_name}/configure-output-$(ndate).txt"
      fi

      (
        echo
        echo "Running tcl make..."

        # Build.
        run_verbose make -j 1 # ${JOBS}

        # make install-strip
        run_verbose make install

        if false # [ "${RUN_LONG_TESTS}" == "y" ]
        then
          run_verbose make -j1 test
        fi

      ) 2>&1 | tee "${LOGS_FOLDER_PATH}/${tcl_folder_name}/make-output-$(ndate).txt"

      copy_license \
        "${SOURCES_FOLDER_PATH}/${tcl_src_folder_name}" \
        "${tcl_folder_name}"
    )

    (
      test_tcl
    ) 2>&1 | tee "${LOGS_FOLDER_PATH}/${tcl_folder_name}/test-output-$(ndate).txt"

    hash -r

    touch "${tcl_stamp_file_path}"

  else
    echo "Component tcl already installed."
  fi

  test_functions+=("test_tcl")
}

function test_tcl()
{
  (
    # xbb_activate_installed_bin

    echo
    echo "Checking the tcl binaries shared libraries..."

    show_libs "${TEST_PATH}/bin/tclsh${TCL_VERSION_MAJOR}.${TCL_VERSION_MINOR}"
    if [ "${TARGET_PLATFORM}" == "linux" ]
    then
      show_libs "$(find ${LIBS_INSTALL_FOLDER_PATH}/lib/thread* -name 'libthread*.so')"
      for lib in $(find ${LIBS_INSTALL_FOLDER_PATH}/lib/tdb* -name 'libtdb*.so')
      do
        show_libs "${lib}"
      done
      show_libs "$(find ${LIBS_INSTALL_FOLDER_PATH}/lib/itcl* -name 'libitcl*.so')"
      show_libs "$(find ${LIBS_INSTALL_FOLDER_PATH}/lib/sqlite* -name 'libsqlite*.so')"
    elif [ "${TARGET_PLATFORM}" == "darwin" ]
    then
      show_libs "$(find ${LIBS_INSTALL_FOLDER_PATH}/lib/thread* -name 'libthread*.dylib')"
      for lib in $(find ${LIBS_INSTALL_FOLDER_PATH}/lib/tdb* -name 'libtdb*.dylib')
      do
        show_libs "${lib}"
      done
      show_libs "$(find ${LIBS_INSTALL_FOLDER_PATH}/lib/itcl* -name 'libitcl*.dylib')"
      show_libs "$(find ${LIBS_INSTALL_FOLDER_PATH}/lib/sqlite* -name 'libsqlite*.dylib')"
    else
      echo "Unknown platform."
      exit 1
    fi

    echo
    echo "Testing if tcl binaries start properly..."

    run_app "${TEST_PATH}/bin/tclsh${TCL_VERSION_MAJOR}.${TCL_VERSION_MINOR}" <<< 'puts [info patchlevel]'
  )
}

# -----------------------------------------------------------------------------

function build_git()
{
  # https://git-scm.com/
  # https://www.kernel.org/pub/software/scm/git/

  # https://git.archlinux.org/svntogit/packages.git/tree/trunk/PKGBUILD?h=packages/git

  # https://github.com/Homebrew/homebrew-core/blob/master/Formula/git.rb

  # 30-Oct-2017, "2.15.0"
  # 24-Feb-2019, "2.21.0"
  # 13-Jan-2020, "2.25.0"
  # 06-Jun-2021, "2.32.0"
  # 12-Oct-2021, "2.33.1"
  # 24-Nov-2021, "2.34.1"

  local git_version="$1"

  local git_src_folder_name="git-${git_version}"

  local git_archive="${git_src_folder_name}.tar.xz"
  local git_url="https://www.kernel.org/pub/software/scm/git/${git_archive}"

  local git_folder_name="${git_src_folder_name}"

  local git_stamp_file_path="${STAMPS_FOLDER_PATH}/stamp-${git_folder_name}-installed"
  if [ ! -f "${git_stamp_file_path}" ]
  then

    # In-source build.

    if [ ! -d "${BUILD_FOLDER_PATH}/${git_folder_name}" ]
    then
      cd "${BUILD_FOLDER_PATH}"

      download_and_extract "${git_url}" "${git_archive}" \
        "${git_src_folder_name}"

      if [ "${git_src_folder_name}" != "${git_folder_name}" ]
      then
        mv -v "${git_src_folder_name}" "${git_folder_name}"
      fi
    fi

    mkdir -pv "${LOGS_FOLDER_PATH}/${git_folder_name}"

    (
      cd "${BUILD_FOLDER_PATH}/${git_folder_name}"

      if [ "${TARGET_PLATFORM}" == "darwin" ] && [[ ${CC} =~ .*gcc.* ]]
      then
        # The requested URL returned error: 405
        prepare_clang_env ""
      fi

      xbb_activate_installed_dev

      CPPFLAGS="${XBB_CPPFLAGS}"
      CFLAGS="${XBB_CFLAGS_NO_W}"
      CXXFLAGS="${XBB_CXXFLAGS_NO_W}"

      LDFLAGS="${XBB_LDFLAGS_APP_STATIC_GCC}"
      if [ "${TARGET_PLATFORM}" == "linux" ]
      then
        LDFLAGS+=" -Wl,-rpath,${LD_LIBRARY_PATH}"
      fi

      # export LIBS="-ldl"

      export CPPFLAGS
      export CFLAGS
      export CXXFLAGS
      export LDFLAGS

      if [ "${TARGET_PLATFORM}" == "darwin" ]
      then
        export NO_OPENSSL=1
        export APPLE_COMMON_CRYPTO=1
      fi

      if [ ! -f "config.status" ]
      then
        (
          if [ "${IS_DEVELOP}" == "y" ]
          then
            env | sort
          fi

          echo
          echo "Running git configure..."

          if [ "${IS_DEVELOP}" == "y" ]
          then
            run_verbose bash "./configure" --help
          fi

          config_options=()

          config_options+=("--prefix=${BINS_INSTALL_FOLDER_PATH}")
          config_options+=("--libdir=${LIBS_INSTALL_FOLDER_PATH}/lib")
          config_options+=("--includedir=${LIBS_INSTALL_FOLDER_PATH}/include")
          # config_options+=("--datarootdir=${LIBS_INSTALL_FOLDER_PATH}/share")
          config_options+=("--mandir=${LIBS_INSTALL_FOLDER_PATH}/share/man")

          config_options+=("--build=${BUILD}")
          config_options+=("--host=${HOST}")
          config_options+=("--target=${TARGET}")

          run_verbose bash ${DEBUG} "./configure" \
            "${config_options[@]}"

          cp "config.log" "${LOGS_FOLDER_PATH}/${git_folder_name}/config-log-$(ndate).txt"
        ) 2>&1 | tee "${LOGS_FOLDER_PATH}/${git_folder_name}/configure-output-$(ndate).txt"
      fi

      (
        echo
        echo "Running git make..."

        # Build.
        run_verbose make -j ${JOBS}

        # make install-strip
        run_verbose make install

        # Tests are quite complicated

      ) 2>&1 | tee "${LOGS_FOLDER_PATH}/${git_folder_name}/make-output-$(ndate).txt"

      copy_license \
        "${BUILD_FOLDER_PATH}/${git_folder_name}" \
        "${git_folder_name}"
    )

    (
      test_git
    ) 2>&1 | tee "${LOGS_FOLDER_PATH}/${git_folder_name}/test-output-$(ndate).txt"

    hash -r

    touch "${git_stamp_file_path}"

  else
    echo "Component git already installed."
  fi

  test_functions+=("test_git")
}

function test_git()
{
  (
    # xbb_activate_installed_bin

    echo
    echo "Checking the git binaries shared libraries..."

    show_libs "${TEST_PATH}/bin/git"

    echo
    echo "Testing if git binaries start properly..."

    run_app "${TEST_PATH}/bin/git" --version

    rm -rf content.git
    run_app "${TEST_PATH}/bin/git" clone \
      https://github.com/xpack-dev-tools/.github.git \
      .github.git
  )
}

# -----------------------------------------------------------------------------

function build_p7zip()
{
  # https://sourceforge.net/projects/p7zip/files/p7zip
  # https://sourceforge.net/projects/p7zip/files/p7zip/16.02/p7zip_16.02_src_all.tar.bz2/download

  # https://archlinuxarm.org/packages/aarch64/p7zip/files/PKGBUILD

  # 2016-07-14, "16.02" (latest)

  local p7zip_version="$1"

  local p7zip_src_folder_name="p7zip_${p7zip_version}"

  local p7zip_archive="${p7zip_src_folder_name}_src_all.tar.bz2"
  local p7zip_url="https://sourceforge.net/projects/p7zip/files/p7zip/${p7zip_version}/${p7zip_archive}"

  local p7zip_folder_name="p7zip-${p7zip_version}"

  local p7zip_patch_file_name="${helper_folder_path}/patches/p7zip-${p7zip_version}.patch"
  local p7zip_stamp_file_path="${STAMPS_FOLDER_PATH}/stamp-${p7zip_folder_name}-installed"
  if [ ! -f "${p7zip_stamp_file_path}" ]
  then

    echo
    echo "p7zip in-source building"

    if [ ! -d "${BUILD_FOLDER_PATH}/${p7zip_folder_name}" ]
    then
      cd "${BUILD_FOLDER_PATH}"

      download_and_extract "${p7zip_url}" "${p7zip_archive}" \
        "${p7zip_src_folder_name}" "${p7zip_patch_file_name}"

      if [ "${p7zip_src_folder_name}" != "${p7zip_folder_name}" ]
      then
        mv -v "${p7zip_src_folder_name}" "${p7zip_folder_name}"
      fi
    fi

    mkdir -pv "${LOGS_FOLDER_PATH}/${p7zip_folder_name}"

    (
      cd "${BUILD_FOLDER_PATH}/${p7zip_folder_name}"

      xbb_activate_installed_dev

      CPPFLAGS="${XBB_CPPFLAGS}"
      if [ "${TARGET_PLATFORM}" == "darwin" ]
      then
        CPPFLAGS+=" -DENV_MACOSX"
      fi
      CFLAGS="${XBB_CFLAGS_NO_W} -std=c99"
      CXXFLAGS="${XBB_CXXFLAGS_NO_W} -std=c++11"

      LDFLAGS="${XBB_LDFLAGS_APP_STATIC_GCC}"
      if [ "${TARGET_PLATFORM}" == "linux" ]
      then
        LDFLAGS+=" -Wl,-rpath,${LD_LIBRARY_PATH}"
      fi

      export CPPFLAGS
      export CFLAGS
      export CXXFLAGS
      export LDFLAGS

      if [ "${IS_DEVELOP}" == "y" ]
      then
        env | sort
      fi

      echo
      echo "Running p7zip make..."

      # Override the hard-coded gcc & g++.
      sed -i.bak -e "s|CXX=g++.*|CXX=${CXX}|" "makefile.machine"
      sed -i.bak -e "s|CC=gcc.*|CC=${CC}|" "makefile.machine"

      # Do not override the environment variables, append to them.
      sed -i.bak -e "s|CFLAGS=|CFLAGS+=|" "makefile.glb"
      sed -i.bak -e "s|CXXFLAGS=|CXXFLAGS+=|" "makefile.glb"

      # Build.
      run_verbose make -j ${JOBS} 7za 7zr

      run_verbose ls -lL "bin"

      # Override the hard-coded '/usr/local'.
      run_verbose sed -i.bak \
        -e "s|DEST_HOME=/usr/local|DEST_HOME=${BINS_INSTALL_FOLDER_PATH}|" \
        -e "s|DEST_SHARE=.*|DEST_SHARE=${LIBS_INSTALL_FOLDER_PATH}/lib|" \
        -e "s|DEST_MAN=.*|DEST_MAN=${LIBS_INSTALL_FOLDER_PATH}/share/man|" \
        "install.sh"

      run_verbose bash "install.sh"

      if [ "${WITH_TESTS}" == "y" ]
      then
        if [ "${TARGET_PLATFORM}" == "darwin" ]
        then
          # 7z cannot load library on macOS.
          run_verbose make -j1 test
        else
          # make -j1 test test_7z
          run_verbose make -j1 all_test
        fi
      fi

    ) 2>&1 | tee "${LOGS_FOLDER_PATH}/${p7zip_folder_name}/install-output-$(ndate).txt"

    copy_license \
      "${BUILD_FOLDER_PATH}/${p7zip_folder_name}" \
      "${p7zip_folder_name}"

    (
      test_p7zip
    ) 2>&1 | tee "${LOGS_FOLDER_PATH}/${p7zip_folder_name}/test-output-$(ndate).txt"

    hash -r

    touch "${p7zip_stamp_file_path}"

  else
    echo "Component p7zip already installed."
  fi

  test_functions+=("test_p7zip")
}

function test_p7zip()
{
  (
    # xbb_activate_installed_bin

    echo
    echo "Checking the 7za shared libraries..."

    if [ -f "${TEST_PATH}/bin/7za" ]
    then
      show_libs "${TEST_PATH}/bin/7za"
    fi

    if [ -f "${TEST_PATH}/bin/7z" ]
    then
      show_libs "${TEST_PATH}/lib/p7zip/7z"
    fi

    if [ -f "${TEST_PATH}/lib/p7zip/7z" ]
    then
      show_libs "${TEST_PATH}/lib/p7zip/7z"
    fi
    if [ -f "${TEST_PATH}/lib/p7zip/7za" ]
    then
      show_libs "${TEST_PATH}/lib/p7zip/7za"
    fi
    if [ -f "${TEST_PATH}/lib/p7zip/7zr" ]
    then
      show_libs "${TEST_PATH}/lib/p7zip/7zr"
    fi

    if [ -f "${LIBS_INSTALL_FOLDER_PATH}/lib/p7zip/7z.${SHLIB_EXT}" ]
    then
      show_libs "${LIBS_INSTALL_FOLDER_PATH}/lib/p7zip/7z.${SHLIB_EXT}"
    fi

    echo
    echo "Testing if 7za binaries start properly..."

    run_app "${TEST_PATH}/bin/7za" --help

    if [ -f "${TEST_PATH}/bin/7z" ]
    then
      run_app "${TEST_PATH}/bin/7z" --help
    fi
  )
}

# -----------------------------------------------------------------------------

function build_rhash()
{
  # https://github.com/rhash/RHash
  # https://github.com/rhash/RHash/releases
  # https://github.com/rhash/RHash/archive/v1.3.9.tar.gz

  # https://archlinuxarm.org/packages/aarch64/rhash/files/PKGBUILD

  # 14 Dec 2019, "1.3.9"
  # Jan 7, 2021, "1.4.1"
  # Jul 15, 2021, "1.4.2"

  local rhash_version="$1"

  local rhash_src_folder_name="RHash-${rhash_version}"

  local rhash_archive="${rhash_src_folder_name}.tar.gz"
  local rhash_url="https://github.com/rhash/RHash/archive/v${rhash_version}.tar.gz"

  local rhash_folder_name="rhash-${rhash_version}"

  local rhash_stamp_file_path="${STAMPS_FOLDER_PATH}/stamp-${rhash_folder_name}-installed"
  if [ ! -f "${rhash_stamp_file_path}" ]
  then

    # In-source build.

    if [ ! -d "${BUILD_FOLDER_PATH}/${rhash_folder_name}" ]
    then
      cd "${BUILD_FOLDER_PATH}"

      download_and_extract "${rhash_url}" "${rhash_archive}" \
        "${rhash_src_folder_name}"

      if [ "${rhash_src_folder_name}" != "${rhash_folder_name}" ]
      then
        # mv: cannot move 'RHash-1.4.2' to a subdirectory of itself, 'rhash-1.4.2/RHash-1.4.2'
        mv -v "${rhash_src_folder_name}" "${rhash_folder_name}-tmp"
        mv -v "${rhash_folder_name}-tmp" "${rhash_folder_name}"
      fi
    fi

    mkdir -pv "${LOGS_FOLDER_PATH}/${rhash_folder_name}"

    (
      cd "${BUILD_FOLDER_PATH}/${rhash_folder_name}"

      xbb_activate_installed_dev

      CPPFLAGS="${XBB_CPPFLAGS}"
      CFLAGS="${XBB_CFLAGS_NO_W}"
      CXXFLAGS="${XBB_CXXFLAGS_NO_W}"

      LDFLAGS="${XBB_LDFLAGS_APP_STATIC_GCC}"
      if [ "${TARGET_PLATFORM}" == "linux" ]
      then
        LDFLAGS+=" -Wl,-rpath,${LD_LIBRARY_PATH}"
      fi

      export CPPFLAGS
      export CFLAGS
      export CXXFLAGS
      export LDFLAGS

      if [ ! -f "stamp-configure" ]
      then
        (
          if [ "${IS_DEVELOP}" == "y" ]
          then
            env | sort
          fi

          echo
          echo "Running rhash configure..."

          if [ "${IS_DEVELOP}" == "y" ]
          then
            run_verbose bash configure --help
          fi

          config_options=()

          config_options+=("--prefix=${BINS_INSTALL_FOLDER_PATH}")
          config_options+=("--libdir=${LIBS_INSTALL_FOLDER_PATH}/lib")
          # Does not support these options.
          # config_options+=("--includedir=${LIBS_INSTALL_FOLDER_PATH}/include")
          # config_options+=("--datarootdir=${LIBS_INSTALL_FOLDER_PATH}/share")
          config_options+=("--mandir=${LIBS_INSTALL_FOLDER_PATH}/share/man")

          # config_options+=("--build=${BUILD}")
          # config_options+=("--host=${HOST}")
          config_options+=("--target=${TARGET}")

          config_options+=("--cc=${CC}")
          config_options+=("--extra-cflags=${CFLAGS} ${CPPFLAGS}")
          config_options+=("--extra-ldflags=${LDFLAGS}")

          run_verbose bash ${DEBUG} configure \
            "${config_options[@]}"

          cp "config.log" "${LOGS_FOLDER_PATH}/${rhash_folder_name}/config-log-$(ndate).txt"

          touch "stamp-configure"
        ) 2>&1 | tee "${LOGS_FOLDER_PATH}/${rhash_folder_name}/configure-output-$(ndate).txt"
      fi

      (
        echo
        echo "Running rhash make..."

        # Build.
        run_verbose make -j ${JOBS}

        run_verbose make install

        if [ "${WITH_TESTS}" == "y" ]
        then
          run_verbose make -j1 test test-lib
        fi

      ) 2>&1 | tee "${LOGS_FOLDER_PATH}/${rhash_folder_name}/make-output-$(ndate).txt"

      copy_license \
        "${BUILD_FOLDER_PATH}/${rhash_folder_name}" \
        "${rhash_folder_name}"
    )

    (
      test_rhash
    ) 2>&1 | tee "${LOGS_FOLDER_PATH}/${rhash_folder_name}/test-output-$(ndate).txt"

    hash -r

    touch "${rhash_stamp_file_path}"

  else
    echo "Component rhash already installed."
  fi

  test_functions+=("test_rhash")
}

function test_rhash()
{
  (
    # xbb_activate_installed_bin

    echo
    echo "Checking the flex shared libraries..."

    show_libs "${BINS_INSTALL_FOLDER_PATH}/bin/rhash"
    if [ "${TARGET_PLATFORM}" == "darwin" ]
    then
      show_libs "$(realpath ${LIBS_INSTALL_FOLDER_PATH}/lib/librhash.0.dylib)"
    else
      show_libs "$(realpath ${LIBS_INSTALL_FOLDER_PATH}/lib/librhash.so.0)"
    fi

    echo
    echo "Testing if rhash binaries start properly..."

    run_app "${BINS_INSTALL_FOLDER_PATH}/bin/rhash" --version
  )
}

# -----------------------------------------------------------------------------

function build_re2c()
{
  # https://github.com/skvadrik/re2c
  # https://github.com/skvadrik/re2c/releases
  # https://github.com/skvadrik/re2c/releases/download/1.3/re2c-1.3.tar.xz

  # https://archlinuxarm.org/packages/aarch64/re2c/files/PKGBUILD

  # 14 Dec 2019, "1.3"
  # Mar 27, 2021, "2.1.1"
  # 01 Aug 2021, "2.2"

  local re2c_version="$1"

  local re2c_src_folder_name="re2c-${re2c_version}"

  local re2c_archive="${re2c_src_folder_name}.tar.xz"
  local re2c_url="https://github.com/skvadrik/re2c/releases/download/${re2c_version}/${re2c_archive}"

  local re2c_folder_name="${re2c_src_folder_name}"

  local re2c_stamp_file_path="${STAMPS_FOLDER_PATH}/stamp-${re2c_folder_name}-installed"
  if [ ! -f "${re2c_stamp_file_path}" ]
  then

    # In-source build.

    if [ ! -d "${BUILD_FOLDER_PATH}/${re2c_folder_name}" ]
    then
      cd "${BUILD_FOLDER_PATH}"

      download_and_extract "${re2c_url}" "${re2c_archive}" \
        "${re2c_src_folder_name}"

      if [ "${re2c_src_folder_name}" != "${re2c_folder_name}" ]
      then
        mv -v "${re2c_src_folder_name}" "${re2c_folder_name}"
      fi
    fi

    mkdir -pv "${LOGS_FOLDER_PATH}/${re2c_folder_name}"

    (
      cd "${BUILD_FOLDER_PATH}/${re2c_folder_name}"
      if false # [ ! -f "stamp-autogen" ]
      then

        xbb_activate_installed_dev

        run_verbose bash ${DEBUG} "autogen.sh"

        touch "stamp-autogen"

      fi
    ) 2>&1 | tee "${LOGS_FOLDER_PATH}/${re2c_folder_name}/autogen-output-$(ndate).txt"

    (
      cd "${BUILD_FOLDER_PATH}/${re2c_folder_name}"

      xbb_activate_installed_dev

      CPPFLAGS="${XBB_CPPFLAGS}"
      CFLAGS="${XBB_CFLAGS_NO_W}"
      CXXFLAGS="${XBB_CXXFLAGS_NO_W}"

      LDFLAGS="${XBB_LDFLAGS_APP_STATIC_GCC}"
      if [ "${TARGET_PLATFORM}" == "linux" ]
      then
        LDFLAGS+=" -Wl,-rpath,${LD_LIBRARY_PATH}"
      fi

      export CPPFLAGS
      export CFLAGS
      export CXXFLAGS
      export LDFLAGS

      if [ ! -f "config.status" ]
      then
        (
          if [ "${IS_DEVELOP}" == "y" ]
          then
            env | sort
          fi

          echo
          echo "Running re2c configure..."

          if [ "${IS_DEVELOP}" == "y" ]
          then
            run_verbose bash configure --help
          fi

          config_options=()

          config_options+=("--prefix=${BINS_INSTALL_FOLDER_PATH}")
          config_options+=("--libdir=${LIBS_INSTALL_FOLDER_PATH}/lib")
          config_options+=("--includedir=${LIBS_INSTALL_FOLDER_PATH}/include")
          # config_options+=("--datarootdir=${LIBS_INSTALL_FOLDER_PATH}/share")
          config_options+=("--mandir=${LIBS_INSTALL_FOLDER_PATH}/share/man")

          config_options+=("--build=${BUILD}")
          config_options+=("--host=${HOST}")
          config_options+=("--target=${TARGET}")

          run_verbose bash ${DEBUG} configure \
            "${config_options[@]}"

          cp "config.log" "${LOGS_FOLDER_PATH}/${re2c_folder_name}/config-log-$(ndate).txt"
        ) 2>&1 | tee "${LOGS_FOLDER_PATH}/${re2c_folder_name}/configure-output-$(ndate).txt"
      fi

      (
        echo
        echo "Running re2c make..."

        # Build.
        run_verbose make -j ${JOBS}

        # make install-strip
        run_verbose make install

        if [ "${WITH_TESTS}" == "y" ]
        then
          run_verbose make -j1 tests
        fi

      ) 2>&1 | tee "${LOGS_FOLDER_PATH}/${re2c_folder_name}/make-output-$(ndate).txt"

      copy_license \
        "${BUILD_FOLDER_PATH}/${re2c_folder_name}" \
        "${re2c_folder_name}"
    )

    (
      test_re2c
    ) 2>&1 | tee "${LOGS_FOLDER_PATH}/${re2c_folder_name}/test-output-$(ndate).txt"

    hash -r

    touch "${re2c_stamp_file_path}"

  else
    echo "Component re2c already installed."
  fi

  test_functions+=("test_re2c")
}

function test_re2c()
{
  (
    # xbb_activate_installed_bin

    echo
    echo "Checking the flex shared libraries..."

    show_libs "${TEST_PATH}/bin/re2c"

    echo
    echo "Testing if re2c binaries start properly..."

    run_app "${TEST_PATH}/bin/re2c" --version
  )
}

# -----------------------------------------------------------------------------


function build_gnupg()
{
  # https://www.gnupg.org
  # https://www.gnupg.org/ftp/gcrypt/gnupg/gnupg-2.2.19.tar.bz2

  # https://archlinuxarm.org/packages/aarch64/gnupg/files/PKGBUILD

  # 2021-06-10, "2.2.28"
  # 2021-04-20, "2.3.1" fails on macOS
  # 2021-10-12, "2.3.3"

  local gnupg_version="$1"

  local gnupg_src_folder_name="gnupg-${gnupg_version}"

  local gnupg_archive="${gnupg_src_folder_name}.tar.bz2"
  local gnupg_url="https://www.gnupg.org/ftp/gcrypt/gnupg/${gnupg_archive}"

  local gnupg_folder_name="${gnupg_src_folder_name}"

  local gnupg_stamp_file_path="${STAMPS_FOLDER_PATH}/stamp-${gnupg_folder_name}-installed"
  if [ ! -f "${gnupg_stamp_file_path}" ]
  then

    cd "${SOURCES_FOLDER_PATH}"

    download_and_extract "${gnupg_url}" "${gnupg_archive}" \
      "${gnupg_src_folder_name}"

    mkdir -pv "${LOGS_FOLDER_PATH}/${gnupg_folder_name}"

    (
      mkdir -pv "${BUILD_FOLDER_PATH}/${gnupg_folder_name}"
      cd "${BUILD_FOLDER_PATH}/${gnupg_folder_name}"

      xbb_activate_installed_dev

      CPPFLAGS="${XBB_CPPFLAGS}"
      CFLAGS="${XBB_CFLAGS_NO_W}"
      CXXFLAGS="${XBB_CXXFLAGS_NO_W}"

      LDFLAGS="${XBB_LDFLAGS_APP_STATIC_GCC}"
      if [ "${TARGET_PLATFORM}" == "linux" ]
      then
        LDFLAGS+=" -Wl,-rpath,${LD_LIBRARY_PATH}"
        export LIBS="-lrt"
      fi

      export CPPFLAGS
      export CFLAGS
      export CXXFLAGS
      export LDFLAGS

      if [ ! -f "config.status" ]
      then
        (
          if [ "${IS_DEVELOP}" == "y" ]
          then
            env | sort
          fi

          echo
          echo "Running gnupg configure..."

          if [ "${IS_DEVELOP}" == "y" ]
          then
            run_verbose bash "${SOURCES_FOLDER_PATH}/${gnupg_src_folder_name}/configure" --help
          fi

          config_options=()

          config_options+=("--prefix=${BINS_INSTALL_FOLDER_PATH}")
          config_options+=("--libdir=${LIBS_INSTALL_FOLDER_PATH}/lib")
          config_options+=("--includedir=${LIBS_INSTALL_FOLDER_PATH}/include")
          # config_options+=("--datarootdir=${LIBS_INSTALL_FOLDER_PATH}/share")
          config_options+=("--mandir=${LIBS_INSTALL_FOLDER_PATH}/share/man")

          config_options+=("--build=${BUILD}")
          config_options+=("--host=${HOST}")
          config_options+=("--target=${TARGET}")

          config_options+=("--with-libgpg-error-prefix=${LIBS_INSTALL_FOLDER_PATH}")
          config_options+=("--with-libgcrypt-prefix=${LIBS_INSTALL_FOLDER_PATH}")
          config_options+=("--with-libassuan-prefix=${LIBS_INSTALL_FOLDER_PATH}")
          config_options+=("--with-ksba-prefix=${LIBS_INSTALL_FOLDER_PATH}")
          config_options+=("--with-npth-prefix=${LIBS_INSTALL_FOLDER_PATH}")

          # On macOS Arm, it fails to load libbz2.1.0.8.dylib
          config_options+=("--disable-bzip2")

          config_options+=("--enable-maintainer-mode")
          config_options+=("--enable-symcryptrun")

          run_verbose bash ${DEBUG} "${SOURCES_FOLDER_PATH}/${gnupg_src_folder_name}/configure" \
            "${config_options[@]}"

          cp "config.log" "${LOGS_FOLDER_PATH}/${gnupg_folder_name}/config-log-$(ndate).txt"
        ) 2>&1 | tee "${LOGS_FOLDER_PATH}/${gnupg_folder_name}/configure-output-$(ndate).txt"
      fi

      (
        echo
        echo "Running gnupg make..."

        # Build.
        run_verbose make -j ${JOBS}

        # make install-strip
        run_verbose make install

        if [ "${WITH_TESTS}" == "y" ]
        then
          if false # [ "${TARGET_PLATFORM}" == "darwin" ] && [ "${TARGET_ARCH}" == "arm64" ]
          then
            : # Fails with:
            # dyld: Library not loaded: libbz2.1.0.8.dylib
            # Referenced from: /Users/ilg/Work/xbb-bootstrap-4.0.0/darwin-arm64/build/gnupg-2.3.3/g10/./t-keydb
            # Reason: image not found
            # /bin/bash: line 5: 67557 Abort trap: 6           abs_top_srcdir=/Users/ilg/Work/xbb-bootstrap-4.0.0/darwin-arm64/sources/gnupg-2.3.3 ${dir}$tst
          else
            run_verbose make -j1 check
          fi
        fi

      ) 2>&1 | tee "${LOGS_FOLDER_PATH}/${gnupg_folder_name}/make-output-$(ndate).txt"

      copy_license \
        "${BUILD_FOLDER_PATH}/${gnupg_folder_name}" \
        "${gnupg_folder_name}"
    )

    (
      test_gpg
    ) 2>&1 | tee "${LOGS_FOLDER_PATH}/${gnupg_folder_name}/test-output-$(ndate).txt"

    hash -r

    touch "${gnupg_stamp_file_path}"

  else
    echo "Component gnupg already installed."
  fi

  test_functions+=("test_gpg")
}

function test_gpg()
{
  (
    # xbb_activate_installed_bin

    echo
    echo "Checking the gpg binaries shared libraries..."

    show_libs "${BINS_INSTALL_FOLDER_PATH}/bin/gpg"

    echo
    echo "Testing if gpg binaries start properly..."

    run_app "${BINS_INSTALL_FOLDER_PATH}/bin/gpg" --version
    run_app "${BINS_INSTALL_FOLDER_PATH}/bin/gpgv" --version
    run_app "${BINS_INSTALL_FOLDER_PATH}/bin/gpgsm" --version
    run_app "${BINS_INSTALL_FOLDER_PATH}/bin/gpg-agent" --version

    run_app "${BINS_INSTALL_FOLDER_PATH}/bin/kbxutil" --version

    run_app "${BINS_INSTALL_FOLDER_PATH}/bin/gpgconf" --version
    run_app "${BINS_INSTALL_FOLDER_PATH}/bin/gpg-connect-agent" --version
    if [ -f "${BINS_INSTALL_FOLDER_PATH}/bin/symcryptrun" ]
    then
      # clang did not create it.
      run_app "${BINS_INSTALL_FOLDER_PATH}/bin/symcryptrun" --version
    fi
    run_app "${BINS_INSTALL_FOLDER_PATH}/bin/watchgnupg" --version
    # run_app "${INSTALL_FOLDER_PATH}/bin/gpgparsemail" --version
    run_app "${BINS_INSTALL_FOLDER_PATH}/bin/gpg-wks-server" --version
    run_app "${BINS_INSTALL_FOLDER_PATH}/bin/gpgtar" --version

    # run_app "${INSTALL_FOLDER_PATH}/sbin/addgnupghome" --version
    # run_app "${INSTALL_FOLDER_PATH}/sbin/applygnupgdefaults" --version
  )
}

# -----------------------------------------------------------------------------

function build_makedepend()
{
  # http://www.linuxfromscratch.org/blfs/view/7.4/x/makedepend.html
  # http://xorg.freedesktop.org/archive/individual/util
  # http://xorg.freedesktop.org/archive/individual/util/makedepend-1.0.5.tar.bz2

  # https://aur.archlinux.org/cgit/aur.git/tree/PKGBUILD?h=makedepend

  # 2013-07-23, 1.0.5
  # 2019-03-16, 1.0.6

  local makedepend_version="$1"

  local makedepend_src_folder_name="makedepend-${makedepend_version}"

  local makedepend_archive="${makedepend_src_folder_name}.tar.bz2"
  local makedepend_url="http://xorg.freedesktop.org/archive/individual/util/${makedepend_archive}"

  local makedepend_folder_name="${makedepend_src_folder_name}"

  local makedepend_stamp_file_path="${STAMPS_FOLDER_PATH}/stamp-${makedepend_folder_name}-installed"
  if [ ! -f "${makedepend_stamp_file_path}" ]
  then

    cd "${SOURCES_FOLDER_PATH}"

    download_and_extract "${makedepend_url}" "${makedepend_archive}" \
      "${makedepend_src_folder_name}"

    mkdir -pv "${LOGS_FOLDER_PATH}/${makedepend_folder_name}"

    (
      mkdir -pv "${BUILD_FOLDER_PATH}/${makedepend_folder_name}"
      cd "${BUILD_FOLDER_PATH}/${makedepend_folder_name}"

      xbb_activate_installed_dev

      CPPFLAGS="${XBB_CPPFLAGS}"
      CFLAGS="${XBB_CFLAGS_NO_W}"
      CXXFLAGS="${XBB_CXXFLAGS_NO_W}"

      LDFLAGS="${XBB_LDFLAGS_APP_STATIC_GCC}"
      if [ "${TARGET_PLATFORM}" == "linux" ]
      then
        LDFLAGS+=" -Wl,-rpath,${LD_LIBRARY_PATH}"
        export LIBS="-lrt"
      fi

      # export PKG_CONFIG_PATH="${INSTALL_FOLDER_PATH}/share/pkgconfig:${PKG_CONFIG_PATH}"

      export CPPFLAGS
      export CFLAGS
      export CXXFLAGS
      export LDFLAGS

      if [ ! -f "config.status" ]
      then
        (
          if [ "${IS_DEVELOP}" == "y" ]
          then
            env | sort
          fi

          echo
          echo "Running makedepend configure..."

          if [ "${IS_DEVELOP}" == "y" ]
          then
            run_verbose bash "${SOURCES_FOLDER_PATH}/${makedepend_src_folder_name}/configure" --help
          fi

          config_options=()

          config_options+=("--prefix=${BINS_INSTALL_FOLDER_PATH}")
          config_options+=("--libdir=${LIBS_INSTALL_FOLDER_PATH}/lib")
          config_options+=("--includedir=${LIBS_INSTALL_FOLDER_PATH}/include")
          # config_options+=("--datarootdir=${LIBS_INSTALL_FOLDER_PATH}/share")
          config_options+=("--mandir=${LIBS_INSTALL_FOLDER_PATH}/share/man")

          config_options+=("--build=${BUILD}")
          config_options+=("--host=${HOST}")
          config_options+=("--target=${TARGET}")

          run_verbose bash ${DEBUG} "${SOURCES_FOLDER_PATH}/${makedepend_src_folder_name}/configure" \
            "${config_options[@]}"

          cp "config.log" "${LOGS_FOLDER_PATH}/${makedepend_folder_name}/config-log-$(ndate).txt"
        ) 2>&1 | tee "${LOGS_FOLDER_PATH}/${makedepend_folder_name}/configure-output-$(ndate).txt"
      fi

      (
        echo
        echo "Running makedepend make..."

        # Build.
        run_verbose make -j ${JOBS}

        # make install-strip
        run_verbose make install

        if [ "${WITH_TESTS}" == "y" ]
        then
          run_verbose make -j1 check
        fi

      ) 2>&1 | tee "${LOGS_FOLDER_PATH}/${makedepend_folder_name}/make-output-$(ndate).txt"

      copy_license \
        "${BUILD_FOLDER_PATH}/${makedepend_folder_name}" \
        "${makedepend_folder_name}"
    )

    (
      test_makedepend
    ) 2>&1 | tee "${LOGS_FOLDER_PATH}/${makedepend_folder_name}/test-output-$(ndate).txt"

    hash -r

    touch "${makedepend_stamp_file_path}"

  else
    echo "Component makedepend already installed."
  fi

  test_functions+=("test_makedepend")
}

function test_makedepend()
{
  (
    # xbb_activate_installed_bin

    echo
    echo "Testing if makedepend binaries start properly..."

    run_app "${BINS_INSTALL_FOLDER_PATH}/bin/makedepend" || true
  )
}

# -----------------------------------------------------------------------------
