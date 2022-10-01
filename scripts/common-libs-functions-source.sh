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

function build_libtasn1()
{
  # https://www.gnu.org/software/libtasn1/
  # http://ftp.gnu.org/gnu/libtasn1/
  # https://ftp.gnu.org/gnu/libtasn1/libtasn1-4.12.tar.gz

  # https://github.com/archlinux/svntogit-packages/blob/packages/libtasn1/trunk/PKGBUILD
  # https://archlinuxarm.org/packages/aarch64/libtasn1/files/PKGBUILD
  # https://aur.archlinux.org/cgit/aur.git/tree/PKGBUILD?h=libtasn1-git

  # https://github.com/Homebrew/homebrew-core/blob/master/Formula/libtasn1.rb

  # 2017-11-19, "4.12"
  # 2018-01-16, "4.13"
  # 2019-11-21, "4.15.0"
  # 2021-05-13, "4.17.0"
  # 2021-11-09, "4.18.0"

  local libtasn1_version="$1"

  local libtasn1_src_folder_name="libtasn1-${libtasn1_version}"

  local libtasn1_archive="${libtasn1_src_folder_name}.tar.gz"
  local libtasn1_url="ftp://ftp.gnu.org/gnu/liblibtasn1/${libtasn1_archive}"

  local libtasn1_folder_name="${libtasn1_src_folder_name}"

  local libtasn1_stamp_file_path="${STAMPS_FOLDER_PATH}/stamp-${libtasn1_folder_name}-installed"
  if [ ! -f "${libtasn1_stamp_file_path}" ]
  then

    cd "${SOURCES_FOLDER_PATH}"

    download_and_extract "${libtasn1_url}" "${libtasn1_archive}" \
      "${libtasn1_src_folder_name}"

    mkdir -pv "${LOGS_FOLDER_PATH}/${libtasn1_folder_name}"

    (
      mkdir -pv "${LIBS_BUILD_FOLDER_PATH}/${libtasn1_folder_name}"
      cd "${LIBS_BUILD_FOLDER_PATH}/${libtasn1_folder_name}"

      xbb_activate_installed_dev

      CPPFLAGS="${XBB_CPPFLAGS}"
      CFLAGS="${XBB_CFLAGS_NO_W}"
      CXXFLAGS="${XBB_CXXFLAGS_NO_W}"

      LDFLAGS="${XBB_LDFLAGS_LIB}"
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
          echo "Running libtasn1 configure..."

          if [ "${IS_DEVELOP}" == "y" ]
          then
            run_verbose bash "${SOURCES_FOLDER_PATH}/${libtasn1_src_folder_name}/configure" --help
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

          run_verbose bash ${DEBUG} "${SOURCES_FOLDER_PATH}/${libtasn1_src_folder_name}/configure" \
            "${config_options[@]}"

          if false # is_darwin # && [ "${XBB_LAYER}" == "xbb-bootstrap" ]
          then
            # Disable failing `Test_tree` and `copynode` tests.
            run_verbose sed -i.bak \
              -e 's| Test_tree$(EXEEXT) | |' \
              -e 's| copynode$(EXEEXT) | |' \
              "tests/Makefile"
          fi

          cp "config.log" "${LOGS_FOLDER_PATH}/${libtasn1_folder_name}/config-log-$(ndate).txt"
        ) 2>&1 | tee "${LOGS_FOLDER_PATH}/${libtasn1_folder_name}/configure-output-$(ndate).txt"
      fi

      (
        echo
        echo "Running libtasn1 make..."

        # Build.
        CODE_COVERAGE_LDFLAGS=${LDFLAGS} make -j ${JOBS}

        if [ "${WITH_STRIP}" == "y" ]
        then
          run_verbose make install-strip
        else
          run_verbose make install
        fi

        if [ "${WITH_TESTS}" == "y" ]
        then
          run_verbose make -j1 check
        fi

      ) 2>&1 | tee "${LOGS_FOLDER_PATH}/${libtasn1_folder_name}/make-output-$(ndate).txt"

      copy_license \
        "${SOURCES_FOLDER_PATH}/${libtasn1_src_folder_name}" \
        "${libtasn1_folder_name}"
    )

    touch "${libtasn1_stamp_file_path}"

  else
    echo "Library libtasn1 already installed."
  fi
}

# -----------------------------------------------------------------------------

function build_libunistring()
{
  # https://www.gnu.org/software/libunistring/
  # https://ftp.gnu.org/gnu/libunistring/
  # https://ftp.gnu.org/gnu/libunistring/libunistring-0.9.10.tar.xz

  # https://github.com/archlinux/svntogit-packages/blob/packages/libunistring/trunk/PKGBUILD
  # https://archlinuxarm.org/packages/aarch64/libunistring/files/PKGBUILD

  # https://github.com/Homebrew/homebrew-core/blob/master/Formula/libunistring.rb

  # 2018-05-25 "0.9.10"

  local libunistring_version="$1"

  local libunistring_src_folder_name="libunistring-${libunistring_version}"

  local libunistring_archive="${libunistring_src_folder_name}.tar.xz"
  local libunistring_url="https://ftp.gnu.org/gnu/libunistring/${libunistring_archive}"

  local libunistring_folder_name="${libunistring_src_folder_name}"

  local libunistring_stamp_file_path="${STAMPS_FOLDER_PATH}/stamp-${libunistring_folder_name}-installed"
  if [ ! -f "${libunistring_stamp_file_path}" ]
  then

    cd "${SOURCES_FOLDER_PATH}"

    download_and_extract "${libunistring_url}" "${libunistring_archive}" \
      "${libunistring_src_folder_name}"

    mkdir -pv "${LOGS_FOLDER_PATH}/${libunistring_folder_name}"

    (
      mkdir -pv "${LIBS_BUILD_FOLDER_PATH}/${libunistring_folder_name}"
      cd "${LIBS_BUILD_FOLDER_PATH}/${libunistring_folder_name}"

      xbb_activate_installed_dev

      CPPFLAGS="${XBB_CPPFLAGS}"
      CFLAGS="${XBB_CFLAGS_NO_W}"
      CXXFLAGS="${XBB_CXXFLAGS_NO_W}"

      LDFLAGS="${XBB_LDFLAGS_LIB}"
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
          echo "Running libunistring configure..."

          if [ "${IS_DEVELOP}" == "y" ]
          then
            run_verbose bash "${SOURCES_FOLDER_PATH}/${libunistring_src_folder_name}/configure" --help
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

          config_options+=("--disable-debug") # HB
          config_options+=("--disable-dependency-tracking") # HB
          if [ "${IS_DEVELOP}" == "y" ]
          then
            config_options+=("--disable-silent-rules") # HB
          fi

          # DO NOT USE, on macOS the LC_RPATH looses GCC references.
          # config_options+=("--enable-relocatable")

          run_verbose bash ${DEBUG} "${SOURCES_FOLDER_PATH}/${libunistring_src_folder_name}/configure" \
            "${config_options[@]}"

          cp "config.log" "${LOGS_FOLDER_PATH}/${libunistring_folder_name}/config-log-$(ndate).txt"
        ) 2>&1 | tee "${LOGS_FOLDER_PATH}/${libunistring_folder_name}/configure-output-$(ndate).txt"
      fi

      (
        echo
        echo "Running libunistring make..."

        # Build.
        run_verbose make -j ${JOBS}

        if [ "${WITH_STRIP}" == "y" ]
        then
          run_verbose make install-strip
        else
          run_verbose make install
        fi

        # It takes too long.
        if false # [ "${WITH_TESTS}" == "y" ]
        then
          run_verbose make -j1 check
        fi

      ) 2>&1 | tee "${LOGS_FOLDER_PATH}/${libunistring_folder_name}/make-output-$(ndate).txt"

      copy_license \
        "${SOURCES_FOLDER_PATH}/${libunistring_src_folder_name}" \
        "${libunistring_folder_name}"
    )

    touch "${libunistring_stamp_file_path}"

  else
    echo "Library libunistring already installed."
  fi
}

# -----------------------------------------------------------------------------

function build_gc()
{
  # https://www.hboehm.info/gc
  # https://github.com/ivmai/bdwgc/releases/
  # https://github.com/ivmai/bdwgc/releases/download/v8.0.4/gc-8.0.4.tar.gz
  # https://github.com/ivmai/bdwgc/releases/download/v8.2.0/gc-8.2.0.tar.gz

  # https://github.com/archlinux/svntogit-packages/blob/packages/gc/trunk/PKGBUILD
  # https://archlinuxarm.org/packages/aarch64/gc/files/PKGBUILD

  # https://github.com/Homebrew/homebrew-core/blob/master/Formula/bdw-gc.rb


  # 2 Mar 2019 "8.0.4"
  # 28 Sep 2021, "8.0.6"
  # 29 Sep 2021, "8.2.0"

  # On linux 8.2.0 fails with
  # extra/../pthread_support.c:365:13: error: too few arguments to function 'pthread_setname_np'
  # 365 |       (void)pthread_setname_np(name_buf);

  local gc_version="$1"

  local gc_src_folder_name="gc-${gc_version}"

  local gc_archive="${gc_src_folder_name}.tar.gz"
  local gc_url="https://github.com/ivmai/bdwgc/releases/download/v${gc_version}/${gc_archive}"

  local gc_folder_name="${gc_src_folder_name}"

  local gc_patch_file_name="${gc_folder_name}.patch.diff"
  local gc_stamp_file_path="${STAMPS_FOLDER_PATH}/stamp-${gc_folder_name}-installed"
  if [ ! -f "${gc_stamp_file_path}" ]
  then

    cd "${SOURCES_FOLDER_PATH}"

    download_and_extract "${gc_url}" "${gc_archive}" \
      "${gc_src_folder_name}" "${gc_patch_file_name}"

    mkdir -pv "${LOGS_FOLDER_PATH}/${gc_folder_name}"

    (
      mkdir -pv "${LIBS_BUILD_FOLDER_PATH}/${gc_folder_name}"
      cd "${LIBS_BUILD_FOLDER_PATH}/${gc_folder_name}"

      xbb_activate_installed_dev

      CPPFLAGS="${XBB_CPPFLAGS}"
      CFLAGS="${XBB_CFLAGS_NO_W}"
      CXXFLAGS="${XBB_CXXFLAGS_NO_W}"

      LDFLAGS="${XBB_LDFLAGS_LIB}"
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
          echo "Running gc configure..."

          if [ "${IS_DEVELOP}" == "y" ]
          then
            run_verbose bash "${SOURCES_FOLDER_PATH}/${gc_src_folder_name}/configure" --help
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

          config_options+=("--enable-cplusplus") # HB
          config_options+=("--enable-large-config") # HB

          config_options+=("--enable-static") # HB
          # config_options+=("--disable-static") # Arch

          config_options+=("--disable-docs")

          run_verbose bash ${DEBUG} "${SOURCES_FOLDER_PATH}/${gc_src_folder_name}/configure" \
            "${config_options[@]}"

          if false # is_linux
          then
            # Skip the tests folder from patching, since the tests use
            # internal shared libraries.
            run_verbose find . \
              -name "libtool" \
              ! -path 'tests' \
              -print \
              -exec bash patch_file_libtool_rpath {} \;
          fi

          cp "config.log" "${LOGS_FOLDER_PATH}/${gc_folder_name}/config-log-$(ndate).txt"
        ) 2>&1 | tee "${LOGS_FOLDER_PATH}/${gc_folder_name}/configure-output-$(ndate).txt"
      fi

      (
        echo
        echo "Running gc make..."

        # TODO: check if required
        # make clean

        # Build.
        run_verbose make -j ${JOBS}

        if [ "${WITH_STRIP}" == "y" ]
        then
          run_verbose make install-strip
        else
          run_verbose make install
        fi

        if [ "${TARGET_PLATFORM}" == "darwin" ]
        then
          # Otherwise guile fails.
          mkdir -pv "${LIBS_INSTALL_FOLDER_PATH}/include"
          cp -v "${SOURCES_FOLDER_PATH}/${gc_src_folder_name}/include/gc_pthread_redirects.h" \
            "${LIBS_INSTALL_FOLDER_PATH}/include"
        fi

        if [ "${WITH_TESTS}" == "y" ]
        then
          if [ "${TARGET_PLATFORM}" == "linux" ] && [ "${TARGET_ARCH}" == "arm" ]
          then
            : # FAIL: gctest (on Ubuntu 18)
          else
            run_verbose make -j1 check
          fi
        fi

      ) 2>&1 | tee "${LOGS_FOLDER_PATH}/${gc_folder_name}/make-output-$(ndate).txt"

      copy_license \
        "${SOURCES_FOLDER_PATH}/${gc_src_folder_name}" \
        "${gc_folder_name}"
    )

    (
      test_gc_libs
    ) 2>&1 | tee "${LOGS_FOLDER_PATH}/${gc_folder_name}/test-output-$(ndate).txt"

    touch "${gc_stamp_file_path}"

  else
    echo "Library gc already installed."
  fi

  # tests_add "test_gc"
}

function test_gc_libs()
{
  (
    echo
    echo "Checking the gc shared libraries..."

    show_libs "${LIBS_INSTALL_FOLDER_PATH}/lib/libgc.${SHLIB_EXT}"
    show_libs "${LIBS_INSTALL_FOLDER_PATH}/lib/libgccpp.${SHLIB_EXT}"
    show_libs "${LIBS_INSTALL_FOLDER_PATH}/lib/libcord.${SHLIB_EXT}"
  )
}

# -----------------------------------------------------------------------------

function build_gnutls()
{
  # http://www.gnutls.org/
  # https://www.gnupg.org/ftp/gcrypt/gnutls/
  # https://www.gnupg.org/ftp/gcrypt/gnutls/v3.6/gnutls-3.6.7.tar.xz

  # https://github.com/archlinux/svntogit-packages/blob/packages/gnutls/trunk/PKGBUILD

  # https://archlinuxarm.org/packages/aarch64/gnutls/files/PKGBUILD
  # https://aur.archlinux.org/cgit/aur.git/tree/PKGBUILD?h=gnutls-git

  # # https://github.com/Homebrew/homebrew-core/blob/master/Formula/gnutls.rb

  # 2017-10-21, "3.6.1"
  # 2019-03-27, "3.6.7"
  # 2019-12-02, "3.6.11.1"
  # 2021-05-29, "3.7.2"

  local gnutls_version="$1"
  # The first two digits.
  local gnutls_version_major_minor="$(echo ${gnutls_version} | sed -e 's|\([0-9][0-9]*\.[0-9][0-9]*\)\.[0-9].*|\1|')"

  local gnutls_src_folder_name="gnutls-${gnutls_version}"

  local gnutls_archive="${gnutls_src_folder_name}.tar.xz"
  local gnutls_url="https://www.gnupg.org/ftp/gcrypt/gnutls/v${gnutls_version_major_minor}/${gnutls_archive}"

  local gnutls_folder_name="${gnutls_src_folder_name}"

  local gnutls_stamp_file_path="${STAMPS_FOLDER_PATH}/stamp-${gnutls_folder_name}-installed"
  if [ ! -f "${gnutls_stamp_file_path}" ]
  then

    cd "${SOURCES_FOLDER_PATH}"

    download_and_extract "${gnutls_url}" "${gnutls_archive}" \
      "${gnutls_src_folder_name}"

    mkdir -pv "${LOGS_FOLDER_PATH}/${gnutls_folder_name}"

    (
      mkdir -pv "${LIBS_BUILD_FOLDER_PATH}/${gnutls_folder_name}"
      cd "${LIBS_BUILD_FOLDER_PATH}/${gnutls_folder_name}"

      if [ "${TARGET_PLATFORM}" == "darwin" ] && [[ ${CC} =~ .*gcc.* ]]
      then
        # lib/system/certs.c:49 error: variably modified 'bytes' at file scope
        prepare_clang_env ""
      fi

      xbb_activate_installed_dev

      # For guile.
      xbb_activate_installed_bin

      CPPFLAGS="${XBB_CPPFLAGS}"
      if [ "${TARGET_PLATFORM}" == "darwin" ]
      then
        CPPFLAGS+=" -D_Noreturn="
      fi
      CFLAGS="${XBB_CFLAGS_NO_W}"
      CXXFLAGS="${XBB_CXXFLAGS_NO_W}"
      LDFLAGS="${XBB_LDFLAGS_LIB}"

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
          echo "Running gnutls configure..."

          if [ "${IS_DEVELOP}" == "y" ]
          then
            run_verbose bash "${SOURCES_FOLDER_PATH}/${gnutls_src_folder_name}/configure" --help
          fi

          # --disable-static
          config_options=()

          config_options+=("--prefix=${BINS_INSTALL_FOLDER_PATH}")
          config_options+=("--libdir=${LIBS_INSTALL_FOLDER_PATH}/lib")
          config_options+=("--includedir=${LIBS_INSTALL_FOLDER_PATH}/include")
          # config_options+=("--datarootdir=${LIBS_INSTALL_FOLDER_PATH}/share")
          config_options+=("--mandir=${LIBS_INSTALL_FOLDER_PATH}/share/man")

          config_options+=("--build=${BUILD}")
          config_options+=("--host=${HOST}")
          config_options+=("--target=${TARGET}")

          config_options+=("--with-idn") # Arch
          config_options+=("--with-brotli") # Arch
          config_options+=("--with-zstd") # Arch
          config_options+=("--with-tpm2") # Arch
          config_options+=("--with-guile-site-dir=no") # Arch
          # configure: error: cannot use pkcs11 store without p11-kit
          # config_options+=("--with-default-trust-store-pkcs11=\"pkcs11:\"") # Arch
          # --with-default-trust-store-file=#{pkgetc}/cert.pem # HB

          config_options+=("--with-included-unistring")
          config_options+=("--without-p11-kit")
          # config_options+=("--with-p11-kit") # HB

          config_options+=("--enable-openssl-compatibility") # Arch

          # Fails on macOS with:
          # ice-9/boot-9.scm:752:25: In procedure dispatch-exception:
          # In procedure dynamic-link: file: "/Users/ilg/Work/xbb-bootstrap-4.0.0/darwin-arm64/build/libs/gnutls-3.7.2/guile/src/guile-gnutls-v-2", message: "file not found"
          config_options+=("--disable-guile")
          # config_options+=("--enable-guile") # Arch

          config_options+=("--disable-heartbeat-support") # HB

          # config_options+=("--disable-static") # Arch
          config_options+=("--disable-doc")
          config_options+=("--disable-full-test-suite")

          # config_options+=("--disable-static") # HB

          config_options+=("--disable-debug") # HB
          config_options+=("--disable-dependency-tracking") # HB
          if [ "${IS_DEVELOP}" == "y" ]
          then
            config_options+=("--disable-silent-rules") # HB
          fi

          config_options+=("--disable-nls")

          run_verbose bash ${DEBUG} "${SOURCES_FOLDER_PATH}/${gnutls_src_folder_name}/configure" \
            "${config_options[@]}"

if false
then
          #    -e 's|-rpath $(guileextensiondir)||' \
          #    -e 's|-rpath $(pkglibdir)||' \
          #    -e 's|-rpath $(libdir)||' \

          if is_darwin # && [ "${XBB_LAYER}" == "xbb-bootstrap" ]
          then
            run_verbose find . \
              -name Makefile \
              -print \
              -exec sed -i.bak \
                -e "s|-Wl,-no_weak_imports||" \
                {} \;
          fi

          if is_linux
          then
            run_verbose find . \
              -name Makefile \
              -print \
              -exec sed -i.bak \
                -e "s|-Wl,-rpath -Wl,${INSTALL_FOLDER_PATH}/lib||" \
                {} \;
          fi

          if is_darwin && [ "${XBB_LAYER}" == "xbb-bootstrap" ]
          then
            run_verbose sed -i.bak \
              -e 's| test-ciphers.sh | |' \
              -e 's| override-ciphers | |' \
              "tests/slow/Makefile"
          fi

          if is_darwin # && [ "${XBB_LAYER}" == "xbb-bootstrap" ]
          then
            if [ -f "gl/tests/Makefile" ]
            then
              # Disable failing tests.
              run_verbose sed -i.bak \
                -e 's| test-ftell.sh | |' \
                -e 's|test-ftell2.sh ||' \
                -e 's| test-ftello.sh | |' \
                -e 's|test-ftello2.sh ||' \
                "gl/tests/Makefile"
            fi

            if [ -f "src/gl/tests/Makefile" ]
            then
              # Disable failing tests.
              run_verbose sed -i.bak \
                -e 's| test-ftell.sh | |' \
                -e 's|test-ftell2.sh ||' \
                -e 's| test-ftello.sh | |' \
                -e 's|test-ftello2.sh ||' \
                "src/gl/tests/Makefile"
            fi

            run_verbose sed -i.bak \
              -e 's| long-crl.sh | |' \
              -e 's| ocsp$(EXEEXT)||' \
              -e 's| crl_apis$(EXEEXT) | |' \
              -e 's| crt_apis$(EXEEXT) | |' \
              -e 's|gnutls_x509_crt_sign$(EXEEXT) ||' \
              -e 's| pkcs12_encode$(EXEEXT) | |' \
              -e 's| crq_apis$(EXEEXT) | |' \
              -e 's|certificate_set_x509_crl$(EXEEXT) ||' \
              "tests/Makefile"
          fi

          if true # [ "${XBB_LAYER}" == "xbb" -o "${XBB_LAYER}" == "xbb-test" ]
          then
            if is_arm && [ "${HOST_BITS}" == "32" ]
            then
              # On Arm
              # server:242: server: Handshake has failed (The operation timed out)
              # FAIL: srp
              # WARN-TEST
              run_verbose sed -i.bak \
                -e 's|srp$(EXEEXT) ||' \
                "tests/Makefile"
            fi
          fi
fi

          cp "config.log" "${LOGS_FOLDER_PATH}/${gnutls_folder_name}/config-log-$(ndate).txt"
        ) 2>&1 | tee "${LOGS_FOLDER_PATH}/${gnutls_folder_name}/configure-output-$(ndate).txt"
      fi

      (
        echo
        echo "Running gnutls make..."

        # Build.
        run_verbose make -j ${JOBS}

        if [ "${WITH_STRIP}" == "y" ]
        then
          run_verbose make install-strip
        else
          run_verbose make install
        fi

        # It takes very, very long. use --disable-full-test-suite
        # i386: FAIL: srp
        if false # [ "${RUN_LONG_TESTS}" == "y" ]
        then
          if is_darwin # && [ "${XBB_LAYER}" == "xbb-bootstrap" ]
          then
            # tests/cert-tests FAIL:  24
            run_verbose make -j1 check || true
          else
            run_verbose make -j1 check
          fi
        fi

      ) 2>&1 | tee "${LOGS_FOLDER_PATH}/${gnutls_folder_name}/make-output-$(ndate).txt"

      copy_license \
        "${SOURCES_FOLDER_PATH}/${gnutls_src_folder_name}" \
        "${gnutls_folder_name}"
    )

    (
      test_gnutls "${BINS_INSTALL_FOLDER_PATH}/bin"
    ) 2>&1 | tee "${LOGS_FOLDER_PATH}/${gnutls_folder_name}/test-output-$(ndate).txt"

    touch "${gnutls_stamp_file_path}"

  else
    echo "Library gnutls already installed."
  fi

  tests_add "test_gnutls" "${BINS_INSTALL_FOLDER_PATH}/bin"
}

function test_gnutls()
{
  local test_bin_folder_path="$1"

  (
    echo
    echo "Checking the gnutls shared libraries..."

    show_libs "${test_bin_folder_path}/psktool"
    show_libs "${test_bin_folder_path}/gnutls-cli-debug"
    show_libs "${test_bin_folder_path}/certtool"
    show_libs "${test_bin_folder_path}/srptool"
    show_libs "${test_bin_folder_path}/ocsptool"
    show_libs "${test_bin_folder_path}/gnutls-serv"
    show_libs "${test_bin_folder_path}/gnutls-cli"

    echo
    echo "Testing if gnutls binaries start properly..."

    run_app "${test_bin_folder_path}/psktool" --version
    run_app "${test_bin_folder_path}/certtool" --version
  )
}

# -----------------------------------------------------------------------------


function build_libgpg_error()
{
  # https://gnupg.org/ftp/gcrypt/libgpg-error

  # https://github.com/archlinux/svntogit-packages/blob/packages/libgpg-error/trunk/PKGBUILD
  # https://archlinuxarm.org/packages/aarch64/libgpg-error/files/PKGBUILD

  # https://github.com/Homebrew/homebrew-core/blob/master/Formula/libgpg-error.rb

  # 2020-02-07, "1.37"
  # 2021-03-22, "1.42"

  local libgpg_error_version="$1"

  local libgpg_error_src_folder_name="libgpg-error-${libgpg_error_version}"

  local libgpg_error_archive="${libgpg_error_src_folder_name}.tar.bz2"
  local libgpg_error_url="https://gnupg.org/ftp/gcrypt/libgpg-error/${libgpg_error_archive}"

  local libgpg_error_folder_name="${libgpg_error_src_folder_name}"

  local libgpg_error_stamp_file_path="${STAMPS_FOLDER_PATH}/stamp-${libgpg_error_folder_name}-installed"
  if [ ! -f "${libgpg_error_stamp_file_path}" ]
  then

    cd "${SOURCES_FOLDER_PATH}"

    download_and_extract "${libgpg_error_url}" "${libgpg_error_archive}" \
      "${libgpg_error_src_folder_name}"

    mkdir -pv "${LOGS_FOLDER_PATH}/${libgpg_error_folder_name}"

    (
      mkdir -pv "${LIBS_BUILD_FOLDER_PATH}/${libgpg_error_folder_name}"
      cd "${LIBS_BUILD_FOLDER_PATH}/${libgpg_error_folder_name}"

      xbb_activate_installed_dev

      CPPFLAGS="${XBB_CPPFLAGS}"
      CFLAGS="${XBB_CFLAGS_NO_W}"
      CXXFLAGS="${XBB_CXXFLAGS_NO_W}"

      LDFLAGS="${XBB_LDFLAGS_LIB}"
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
          echo "Running libgpg-error configure..."

          if [ "${IS_DEVELOP}" == "y" ]
          then
            run_verbose bash "${SOURCES_FOLDER_PATH}/${libgpg_error_src_folder_name}/configure" --help
          fi

          config_options=()

          # Exception: use LIBS_INSTALL_*.
          config_options+=("--prefix=${BINS_INSTALL_FOLDER_PATH}")
          config_options+=("--libdir=${LIBS_INSTALL_FOLDER_PATH}/lib")
          config_options+=("--includedir=${LIBS_INSTALL_FOLDER_PATH}/include")
          # config_options+=("--datarootdir=${LIBS_INSTALL_FOLDER_PATH}/share")
          config_options+=("--mandir=${LIBS_INSTALL_FOLDER_PATH}/share/man")

          config_options+=("--build=${BUILD}")
          config_options+=("--host=${HOST}")
          config_options+=("--target=${TARGET}")

          config_options+=("--disable-debug") # HB
          config_options+=("--disable-dependency-tracking") # HB
          if [ "${IS_DEVELOP}" == "y" ]
          then
            config_options+=("--disable-silent-rules") # HB
          fi

          config_options+=("--disable-nls")

          config_options+=("--enable-static") # HB

          run_verbose bash ${DEBUG} "${SOURCES_FOLDER_PATH}/${libgpg_error_src_folder_name}/configure" \
            "${config_options[@]}"

if false
then
          # WARN-TEST
          # FAIL: t-syserror (disabled)
          # Interestingly enough, initially (before dismissing install-strip)
          # it passed.
          run_verbose sed -i.bak \
            -e 's|t-syserror$(EXEEXT)||' \
            "tests/Makefile"
fi

          cp "config.log" "${LOGS_FOLDER_PATH}/${libgpg_error_folder_name}/config-log-$(ndate).txt"
        ) 2>&1 | tee "${LOGS_FOLDER_PATH}/${libgpg_error_folder_name}/configure-output-$(ndate).txt"
      fi

      (
        echo
        echo "Running libgpg-error make..."

        # Build.
        run_verbose make -j ${JOBS}

        if [ "${WITH_STRIP}" == "y" ]
        then
          run_verbose make install-strip
        else
          run_verbose make install
        fi

        if [ "${WITH_TESTS}" == "y" ]
        then
          # WARN-TEST
          run_verbose make -j1 check
        fi

      ) 2>&1 | tee "${LOGS_FOLDER_PATH}/${libgpg_error_folder_name}/make-output-$(ndate).txt"

      copy_license \
        "${SOURCES_FOLDER_PATH}/${libgpg_error_src_folder_name}" \
        "${libgpg_error_folder_name}"
    )

    (
      test_libgpg_error_libs
    ) 2>&1 | tee "${LOGS_FOLDER_PATH}/${libgpg_error_folder_name}/test-output-$(ndate).txt"

    touch "${libgpg_error_stamp_file_path}"

  else
    echo "Library libgpg-error already installed."
  fi
}

function test_libgpg_error_libs()
{
  echo
  echo "Checking the libpng_error shared libraries..."

  show_libs "${LIBS_INSTALL_FOLDER_PATH}/lib/libgpg-error.${SHLIB_EXT}"
}

# -----------------------------------------------------------------------------

function build_libgcrypt()
{
  # https://gnupg.org/ftp/gcrypt/libgcrypt
  # https://gnupg.org/ftp/gcrypt/libgcrypt/libgcrypt-1.8.5.tar.bz2

  # https://github.com/archlinux/svntogit-packages/blob/packages/libgcrypt/trunk/PKGBUILD
  # https://archlinuxarm.org/packages/aarch64/libgcrypt/files/PKGBUILD

  # https://github.com/Homebrew/homebrew-core/blob/master/Formula/libgcrypt.rb

  # 2019-08-29, "1.8.5"
  # 2021-06-02, "1.8.8"
  # 2021-04-19, "1.9.3" Fails many tests on macOS 10.13
  # 2021-08-22, "1.9.4"

  local libgcrypt_version="$1"

  local libgcrypt_src_folder_name="libgcrypt-${libgcrypt_version}"

  local libgcrypt_archive="${libgcrypt_src_folder_name}.tar.bz2"
  local libgcrypt_url="https://gnupg.org/ftp/gcrypt/libgcrypt/${libgcrypt_archive}"

  local libgcrypt_folder_name="${libgcrypt_src_folder_name}"

  local libgcrypt_stamp_file_path="${STAMPS_FOLDER_PATH}/stamp-${libgcrypt_folder_name}-installed"
  if [ ! -f "${libgcrypt_stamp_file_path}" ]
  then

    cd "${SOURCES_FOLDER_PATH}"

    download_and_extract "${libgcrypt_url}" "${libgcrypt_archive}" \
      "${libgcrypt_src_folder_name}"

    mkdir -pv "${LOGS_FOLDER_PATH}/${libgcrypt_folder_name}"

    (
      mkdir -pv "${LIBS_BUILD_FOLDER_PATH}/${libgcrypt_folder_name}"
      cd "${LIBS_BUILD_FOLDER_PATH}/${libgcrypt_folder_name}"

      xbb_activate_installed_dev

      CPPFLAGS="${XBB_CPPFLAGS}"
      CFLAGS="${XBB_CFLAGS_NO_W}"
      CXXFLAGS="${XBB_CXXFLAGS_NO_W}"

      LDFLAGS="${XBB_LDFLAGS_LIB}"
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
          echo "Running libgcrypt configure..."

          if [ "${IS_DEVELOP}" == "y" ]
          then
            run_verbose bash "${SOURCES_FOLDER_PATH}/${libgcrypt_src_folder_name}/configure" --help
          fi

          config_options=()

          # Exception: use LIBS_INSTALL_*.
          config_options+=("--prefix=${BINS_INSTALL_FOLDER_PATH}")
          config_options+=("--libdir=${LIBS_INSTALL_FOLDER_PATH}/lib")
          config_options+=("--includedir=${LIBS_INSTALL_FOLDER_PATH}/include")
          # config_options+=("--datarootdir=${LIBS_INSTALL_FOLDER_PATH}/share")
          config_options+=("--mandir=${LIBS_INSTALL_FOLDER_PATH}/share/man")

          config_options+=("--build=${BUILD}")
          config_options+=("--host=${HOST}")
          config_options+=("--target=${TARGET}")

          config_options+=("--with-libgpg-error-prefix=${LIBS_INSTALL_FOLDER_PATH}")

          config_options+=("--disable-doc")
          config_options+=("--disable-large-data-tests")

          # For Darwin, there are problems with the assembly code.
          config_options+=("--disable-asm") # HB
          config_options+=("--disable-amd64-as-feature-detection")

          config_options+=("--disable-padlock-support") # Arch

          if [ "${HOST_MACHINE}" != "aarch64" ]
          then
            config_options+=("--disable-neon-support")
            config_options+=("--disable-arm-crypto-support")
          fi

          config_options+=("--disable-debug") # HB
          config_options+=("--disable-dependency-tracking") # HB
          if [ "${IS_DEVELOP}" == "y" ]
          then
            config_options+=("--disable-silent-rules") # HB
          fi

          config_options+=("--enable-static") # HB

          run_verbose bash ${DEBUG} "${SOURCES_FOLDER_PATH}/${libgcrypt_src_folder_name}/configure" \
            "${config_options[@]}"

          if [ "${HOST_MACHINE}" != "aarch64" ]
          then
            # fix screwed up capability detection
            sed -i.bak -e '/HAVE_GCC_INLINE_ASM_AARCH32_CRYPTO 1/d' "config.h"
            sed -i.bak -e '/HAVE_GCC_INLINE_ASM_NEON 1/d' "config.h"
          fi

          cp "config.log" "${LOGS_FOLDER_PATH}/${libgcrypt_folder_name}/config-log-$(ndate).txt"
        ) 2>&1 | tee "${LOGS_FOLDER_PATH}/${libgcrypt_folder_name}/configure-output-$(ndate).txt"
      fi

      (
        echo
        echo "Running libgcrypt make..."

        # Build.
        run_verbose make -j ${JOBS}

        if [ "${WITH_STRIP}" == "y" ]
        then
          run_verbose make install-strip
        else
          run_verbose make install
        fi

        # Check after install, otherwise mac test fails:
        # dyld: Library not loaded: /Users/ilg/opt/xbb/lib/libgcrypt.20.dylib
        # Referenced from: /Users/ilg/Work/xbb-3.1-macosx-10.15.3-x86_64/build/libs/libgcrypt-1.8.5/tests/.libs/random

        if [ "${WITH_TESTS}" == "y" ]
        then
          run_verbose make -j1 check
        fi

      ) 2>&1 | tee "${LOGS_FOLDER_PATH}/${libgcrypt_folder_name}/make-output-$(ndate).txt"

      copy_license \
        "${SOURCES_FOLDER_PATH}/${libgcrypt_src_folder_name}" \
        "${libgcrypt_folder_name}"
    )

    (
      test_libgcrypt_libs
      test_libgcrypt "${BINS_INSTALL_FOLDER_PATH}/bin"
    ) 2>&1 | tee "${LOGS_FOLDER_PATH}/${libgcrypt_folder_name}/test-output-$(ndate).txt"

    touch "${libgcrypt_stamp_file_path}"

  else
    echo "Library libgcrypt already installed."
  fi

  tests_add "test_libgcrypt" "${BINS_INSTALL_FOLDER_PATH}/bin"
}

function test_libgcrypt_libs()
{
  echo
  echo "Checking the libgcrypt shared libraries..."

  # show_libs "${INSTALL_FOLDER_PATH}/bin/libgcrypt-config"
  show_libs "${LIBS_INSTALL_FOLDER_PATH}/bin/dumpsexp"
  show_libs "${LIBS_INSTALL_FOLDER_PATH}/bin/hmac256"
  show_libs "${LIBS_INSTALL_FOLDER_PATH}/bin/mpicalc"

  show_libs "${LIBS_INSTALL_FOLDER_PATH}/lib/libgcrypt.${SHLIB_EXT}"
}

function test_libgcrypt()
{
  local test_bin_folder_path="$1"

  (
    echo
    echo "Checking the libgcrypt shared libraries..."

    # show_libs "${INSTALL_FOLDER_PATH}/bin/libgcrypt-config"
    show_libs "${test_bin_folder_path}/dumpsexp"
    show_libs "${test_bin_folder_path}/hmac256"
    show_libs "${test_bin_folder_path}/mpicalc"

    echo
    echo "Testing if libgcrypt binaries start properly..."

    run_app "${test_bin_folder_path}/libgcrypt-config" --version
    run_app "${test_bin_folder_path}/dumpsexp" --version
    run_app "${test_bin_folder_path}/hmac256" --version
    run_app "${test_bin_folder_path}/mpicalc" --version

    # --help not available
    # run_app "${test_bin_folder_path}/hmac256" --help

    rm -rf "${TESTS_FOLDER_PATH}/libgcrypt"
    mkdir -pv "${TESTS_FOLDER_PATH}/libgcrypt"; cd "${TESTS_FOLDER_PATH}/libgcrypt"

    touch test.in
    test_expect "0e824ce7c056c82ba63cc40cffa60d3195b5bb5feccc999a47724cc19211aef6  test.in"  "${test_bin_folder_path}/hmac256" "testing" test.in

  )
}

# -----------------------------------------------------------------------------

function build_libassuan()
{
  # https://gnupg.org/ftp/gcrypt/libassuan
  # https://gnupg.org/ftp/gcrypt/libassuan/libassuan-2.5.3.tar.bz2

  # https://github.com/archlinux/svntogit-packages/blob/packages/libassuan/trunk/PKGBUILD
  # https://archlinuxarm.org/packages/aarch64/libassuan/files/PKGBUILD

  # https://github.com/Homebrew/homebrew-core/blob/master/Formula/libassuan.rb

  # 2019-02-11, "2.5.3"
  # 2021-03-22, "2.5.5"

  local libassuan_version="$1"

  local libassuan_src_folder_name="libassuan-${libassuan_version}"

  local libassuan_archive="${libassuan_src_folder_name}.tar.bz2"
  local libassuan_url="https://gnupg.org/ftp/gcrypt/libassuan/${libassuan_archive}"

  local libassuan_folder_name="${libassuan_src_folder_name}"

  local libassuan_stamp_file_path="${STAMPS_FOLDER_PATH}/stamp-${libassuan_folder_name}-installed"
  if [ ! -f "${libassuan_stamp_file_path}" ]
  then

    cd "${SOURCES_FOLDER_PATH}"

    download_and_extract "${libassuan_url}" "${libassuan_archive}" \
      "${libassuan_src_folder_name}"

    mkdir -pv "${LOGS_FOLDER_PATH}/${libassuan_folder_name}"

    (
      mkdir -pv "${LIBS_BUILD_FOLDER_PATH}/${libassuan_folder_name}"
      cd "${LIBS_BUILD_FOLDER_PATH}/${libassuan_folder_name}"

      xbb_activate_installed_dev

      CPPFLAGS="${XBB_CPPFLAGS}"
      CFLAGS="${XBB_CFLAGS_NO_W}"
      CXXFLAGS="${XBB_CXXFLAGS_NO_W}"

      LDFLAGS="${XBB_LDFLAGS_LIB}"
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
          echo "Running libassuan configure..."

          if [ "${IS_DEVELOP}" == "y" ]
          then
            run_verbose bash "${SOURCES_FOLDER_PATH}/${libassuan_src_folder_name}/configure" --help
          fi

          config_options=()

          # Exception: use LIBS_INSTALL_*.
          config_options+=("--prefix=${BINS_INSTALL_FOLDER_PATH}")
          config_options+=("--libdir=${LIBS_INSTALL_FOLDER_PATH}/lib")
          config_options+=("--includedir=${LIBS_INSTALL_FOLDER_PATH}/include")
          # config_options+=("--datarootdir=${LIBS_INSTALL_FOLDER_PATH}/share")
          config_options+=("--mandir=${LIBS_INSTALL_FOLDER_PATH}/share/man")

          config_options+=("--build=${BUILD}")
          config_options+=("--host=${HOST}")
          config_options+=("--target=${TARGET}")

          config_options+=("--with-libgpg-error-prefix=${LIBS_INSTALL_FOLDER_PATH}")

          config_options+=("--disable-debug") # HB
          config_options+=("--disable-dependency-tracking") # HB
          if [ "${IS_DEVELOP}" == "y" ]
          then
            config_options+=("--disable-silent-rules") # HB
          fi

          config_options+=("--enable-static") # HB

          run_verbose bash ${DEBUG} "${SOURCES_FOLDER_PATH}/${libassuan_src_folder_name}/configure" \
            "${config_options[@]}"

          cp "config.log" "${LOGS_FOLDER_PATH}/${libassuan_folder_name}/config-log-$(ndate).txt"
        ) 2>&1 | tee "${LOGS_FOLDER_PATH}/${libassuan_folder_name}/configure-output-$(ndate).txt"
      fi

      (
        echo
        echo "Running libassuan make..."

        # Build.
        run_verbose make -j ${JOBS}

        if [ "${WITH_STRIP}" == "y" ]
        then
          run_verbose make install-strip
        else
          run_verbose make install
        fi

        if [ "${WITH_TESTS}" == "y" ]
        then
          run_verbose make -j1 check
        fi

      ) 2>&1 | tee "${LOGS_FOLDER_PATH}/${libassuan_folder_name}/make-output-$(ndate).txt"

      copy_license \
        "${SOURCES_FOLDER_PATH}/${libassuan_src_folder_name}" \
        "${libassuan_folder_name}"
    )

    (
      test_libassuan_libs
      test_libassuan "${BINS_INSTALL_FOLDER_PATH}/bin"

    ) 2>&1 | tee "${LOGS_FOLDER_PATH}/${libassuan_folder_name}/test-output-$(ndate).txt"

    touch "${libassuan_stamp_file_path}"

  else
    echo "Library libassuan already installed."
  fi

  tests_add "test_libassuan" "${BINS_INSTALL_FOLDER_PATH}/bin"
}

function test_libassuan_libs()
{
  echo
  echo "Checking the libassuan shared libraries..."

  # show_libs "${INSTALL_FOLDER_PATH}/bin/libassuan-config"
  show_libs "${LIBS_INSTALL_FOLDER_PATH}/lib/libassuan.${SHLIB_EXT}"
}

function test_libassuan()
{
  local test_bin_folder_path="$1"

  (
    echo
    echo "Testing if libassuan binaries start properly..."

    run_app "${test_bin_folder_path}/libassuan-config" --version
  )
}

# -----------------------------------------------------------------------------

function build_libksba()
{
  # https://gnupg.org/ftp/gcrypt/libksba
  # https://gnupg.org/ftp/gcrypt/libksba/libksba-1.3.5.tar.bz2

  # https://github.com/archlinux/svntogit-packages/blob/packages/libksba/trunk/PKGBUILD
  # https://archlinuxarm.org/packages/aarch64/libksba/files/PKGBUILD

  # https://github.com/Homebrew/homebrew-core/blob/master/Formula/libksba.rb

  # 2016-08-22, "1.3.5"
  # 2021-06-10, "1.6.0"

  local libksba_version="$1"

  local libksba_src_folder_name="libksba-${libksba_version}"

  local libksba_archive="${libksba_src_folder_name}.tar.bz2"
  local libksba_url="https://gnupg.org/ftp/gcrypt/libksba/${libksba_archive}"

  local libksba_folder_name="${libksba_src_folder_name}"

  local libksba_patch_file_name="${libksba_folder_name}.patch"

  local libksba_stamp_file_path="${STAMPS_FOLDER_PATH}/stamp-${libksba_folder_name}-installed"
  if [ ! -f "${libksba_stamp_file_path}" ]
  then

    cd "${SOURCES_FOLDER_PATH}"

    download_and_extract "${libksba_url}" "${libksba_archive}" \
      "${libksba_src_folder_name}" "${libksba_patch_file_name}"

    mkdir -pv "${LOGS_FOLDER_PATH}/${libksba_folder_name}"

    (
      mkdir -pv "${LIBS_BUILD_FOLDER_PATH}/${libksba_folder_name}"
      cd "${LIBS_BUILD_FOLDER_PATH}/${libksba_folder_name}"

      xbb_activate_installed_dev

      CPPFLAGS="${XBB_CPPFLAGS}"
      CFLAGS="${XBB_CFLAGS_NO_W}"
      CXXFLAGS="${XBB_CXXFLAGS_NO_W}"

      LDFLAGS="${XBB_LDFLAGS_LIB}"
      if [ "${TARGET_PLATFORM}" == "linux" ]
      then
        LDFLAGS+=" -Wl,-rpath,${LD_LIBRARY_PATH}"
      fi

      export CC_FOR_BUILD="${CC}"

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
          echo "Running libksba configure..."

          if [ "${IS_DEVELOP}" == "y" ]
          then
            run_verbose bash "${SOURCES_FOLDER_PATH}/${libksba_src_folder_name}/configure" --help
          fi

          config_options=()

          # Exception: use LIBS_INSTALL_*.
          config_options+=("--prefix=${BINS_INSTALL_FOLDER_PATH}")
          config_options+=("--libdir=${LIBS_INSTALL_FOLDER_PATH}/lib")
          config_options+=("--includedir=${LIBS_INSTALL_FOLDER_PATH}/include")
          # config_options+=("--datarootdir=${LIBS_INSTALL_FOLDER_PATH}/share")
          config_options+=("--mandir=${LIBS_INSTALL_FOLDER_PATH}/share/man")

          config_options+=("--build=${BUILD}")
          config_options+=("--host=${HOST}")
          config_options+=("--target=${TARGET}")

          config_options+=("--with-libgpg-error-prefix=${LIBS_INSTALL_FOLDER_PATH}")

          config_options+=("--disable-debug") # HB
          config_options+=("--disable-dependency-tracking") # HB
          if [ "${IS_DEVELOP}" == "y" ]
          then
            config_options+=("--disable-silent-rules") # HB
          fi

          run_verbose bash ${DEBUG} "${SOURCES_FOLDER_PATH}/${libksba_src_folder_name}/configure" \
            "${config_options[@]}"

          cp "config.log" "${LOGS_FOLDER_PATH}/${libksba_folder_name}/config-log-$(ndate).txt"
        ) 2>&1 | tee "${LOGS_FOLDER_PATH}/${libksba_folder_name}/configure-output-$(ndate).txt"
      fi

      (
        echo
        echo "Running libksba make..."

        # Build.
        run_verbose make -j ${JOBS}

        if [ "${WITH_STRIP}" == "y" ]
        then
          run_verbose make install-strip
        else
          run_verbose make install
        fi

        if [ "${WITH_TESTS}" == "y" ]
        then
          run_verbose make -j1 check
        fi

      ) 2>&1 | tee "${LOGS_FOLDER_PATH}/${libksba_folder_name}/make-output-$(ndate).txt"

      copy_license \
        "${SOURCES_FOLDER_PATH}/${libksba_src_folder_name}" \
        "${libksba_folder_name}"
    )

    (
      test_libksba_libs
      test_libksba "${BINS_INSTALL_FOLDER_PATH}/bin"
    ) 2>&1 | tee "${LOGS_FOLDER_PATH}/${libksba_folder_name}/test-output-$(ndate).txt"

    touch "${libksba_stamp_file_path}"

  else
    echo "Library libksba already installed."
  fi

  tests_add "test_libksba" "${BINS_INSTALL_FOLDER_PATH}/bin"
}

function test_libksba_libs()
{
  echo
  echo "Checking the libksba shared libraries..."

  # show_libs "${INSTALL_FOLDER_PATH}/bin/ksba-config"
  show_libs "${LIBS_INSTALL_FOLDER_PATH}/lib/libksba.${SHLIB_EXT}"
}

function test_libksba()
{
  local test_bin_folder_path="$1"

  (
    echo
    echo "Testing if libksba binaries start properly..."

    run_app "${test_bin_folder_path}/ksba-config" --version
  )
}

# -----------------------------------------------------------------------------

function build_npth()
{
  # https://gnupg.org/ftp/gcrypt/npth
  # https://gnupg.org/ftp/gcrypt/npth/npth-1.6.tar.bz2

  # https://archlinuxarm.org/packages/aarch64/npth/files/PKGBUILD

  # https://github.com/Homebrew/homebrew-core/blob/master/Formula/npth.rb

  # 2018-07-16, "1.6"

  local npth_version="$1"

  local npth_src_folder_name="npth-${npth_version}"

  local npth_archive="${npth_src_folder_name}.tar.bz2"
  local npth_url="https://gnupg.org/ftp/gcrypt/npth/${npth_archive}"

  local npth_folder_name="${npth_src_folder_name}"

  local npth_stamp_file_path="${STAMPS_FOLDER_PATH}/stamp-${npth_folder_name}-installed"
  if [ ! -f "${npth_stamp_file_path}" ]
  then

    cd "${SOURCES_FOLDER_PATH}"

    download_and_extract "${npth_url}" "${npth_archive}" \
      "${npth_src_folder_name}"

    mkdir -pv "${LOGS_FOLDER_PATH}/${npth_folder_name}"

    (
      mkdir -pv "${LIBS_BUILD_FOLDER_PATH}/${npth_folder_name}"
      cd "${LIBS_BUILD_FOLDER_PATH}/${npth_folder_name}"

      if [ "${TARGET_PLATFORM}" == "darwin" ] && [[ ${CC} =~ .*gcc.* ]]
      then
        # /usr/include/os/base.h:113:20: error: missing binary operator before token "("
        # #if __has_extension(attribute_overloadable)
        prepare_clang_env ""
      fi

      xbb_activate_installed_dev

      CPPFLAGS="${XBB_CPPFLAGS}"
      CFLAGS="${XBB_CFLAGS_NO_W}"
      CXXFLAGS="${XBB_CXXFLAGS_NO_W}"

      LDFLAGS="${XBB_LDFLAGS_LIB}"
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
          echo "Running npth configure..."

          if [ "${IS_DEVELOP}" == "y" ]
          then
            run_verbose bash "${SOURCES_FOLDER_PATH}/${npth_src_folder_name}/configure" --help
          fi

          config_options=()

          # Exception: use LIBS_INSTALL_*.
          config_options+=("--prefix=${BINS_INSTALL_FOLDER_PATH}")
          config_options+=("--libdir=${LIBS_INSTALL_FOLDER_PATH}/lib")
          config_options+=("--includedir=${LIBS_INSTALL_FOLDER_PATH}/include")
          # config_options+=("--datarootdir=${LIBS_INSTALL_FOLDER_PATH}/share")
          config_options+=("--mandir=${LIBS_INSTALL_FOLDER_PATH}/share/man")

          config_options+=("--build=${BUILD}")
          config_options+=("--host=${HOST}")
          config_options+=("--target=${TARGET}")

          config_options+=("--disable-debug") # HB
          config_options+=("--disable-dependency-tracking") # HB
          if [ "${IS_DEVELOP}" == "y" ]
          then
            config_options+=("--disable-silent-rules") # HB
          fi

          run_verbose bash ${DEBUG} "${SOURCES_FOLDER_PATH}/${npth_src_folder_name}/configure" \
            "${config_options[@]}"

          cp "config.log" "${LOGS_FOLDER_PATH}/${npth_folder_name}/config-log-$(ndate).txt"
        ) 2>&1 | tee "${LOGS_FOLDER_PATH}/${npth_folder_name}/configure-output-$(ndate).txt"
      fi

      (
        echo
        echo "Running npth make..."

        # Build.
        run_verbose make -j ${JOBS}

        if [ "${WITH_STRIP}" == "y" ]
        then
          run_verbose make install-strip
        else
          run_verbose make install
        fi

        if [ "${WITH_TESTS}" == "y" ]
        then
          run_verbose make -j1 check
        fi

      ) 2>&1 | tee "${LOGS_FOLDER_PATH}/${npth_folder_name}/make-output-$(ndate).txt"

      copy_license \
        "${SOURCES_FOLDER_PATH}/${npth_src_folder_name}" \
        "${npth_folder_name}"
    )

    (
      test_npth_libs
      test_npth "${BINS_INSTALL_FOLDER_PATH}/bin"
    ) 2>&1 | tee "${LOGS_FOLDER_PATH}/${npth_folder_name}/test-output-$(ndate).txt"

    touch "${npth_stamp_file_path}"

  else
    echo "Library npth already installed."
  fi

  tests_add "test_npth" "${BINS_INSTALL_FOLDER_PATH}/bin"
}

function test_npth_libs()
{
  echo
  echo "Checking the npth shared libraries..."

  show_libs "${LIBS_INSTALL_FOLDER_PATH}/lib/libnpth.${SHLIB_EXT}"
}

function test_npth()
{
  local test_bin_folder_path="$1"

  (
    echo
    echo "Checking the npth shared libraries..."

    run_app "${test_bin_folder_path}/npth-config" --version
  )
}

# -----------------------------------------------------------------------------

function build_xorg_util_macros()
{
  # http://www.linuxfromscratch.org/blfs/view/
  # http://www.linuxfromscratch.org/blfs/view/7.4/x/util-macros.html

  # http://xorg.freedesktop.org/releases/individual/util
  # http://xorg.freedesktop.org/releases/individual/util/util-macros-1.17.1.tar.bz2

  # https://github.com/archlinux/svntogit-packages/blob/packages/xorg-util-macros/trunk/PKGBUILD
  # https://archlinuxarm.org/packages/any/xorg-util-macros/files/PKGBUILD

  # https://github.com/Homebrew/homebrew-core/blob/master/Formula/util-macros.rb

  # 2013-09-07, "1.17.1"
  # 2018-03-05, "1.19.2"
  # 2021-01-24, "1.19.3"

  local xorg_util_macros_version="$1"

  local xorg_util_macros_src_folder_name="util-macros-${xorg_util_macros_version}"

  local xorg_util_macros_archive="${xorg_util_macros_src_folder_name}.tar.bz2"
  local xorg_util_macros_url="http://xorg.freedesktop.org/releases/individual/util/${xorg_util_macros_archive}"

  local xorg_util_macros_folder_name="${xorg_util_macros_src_folder_name}"

  local xorg_util_macros_stamp_file_path="${STAMPS_FOLDER_PATH}/stamp-${xorg_util_macros_folder_name}-installed"
  if [ ! -f "${xorg_util_macros_stamp_file_path}" ]
  then

    cd "${SOURCES_FOLDER_PATH}"

    download_and_extract "${xorg_util_macros_url}" "${xorg_util_macros_archive}" \
      "${xorg_util_macros_src_folder_name}"

    mkdir -pv "${LOGS_FOLDER_PATH}/${xorg_util_macros_folder_name}"

    (
      mkdir -pv "${LIBS_BUILD_FOLDER_PATH}/${xorg_util_macros_folder_name}"
      cd "${LIBS_BUILD_FOLDER_PATH}/${xorg_util_macros_folder_name}"

      xbb_activate_installed_dev

      CPPFLAGS="${XBB_CPPFLAGS}"
      CFLAGS="${XBB_CFLAGS_NO_W}"
      CXXFLAGS="${XBB_CXXFLAGS_NO_W}"

      LDFLAGS="${XBB_LDFLAGS_LIB}"
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
          echo "Running xorg_util_macros configure..."

          if [ "${IS_DEVELOP}" == "y" ]
          then
            run_verbose bash "${SOURCES_FOLDER_PATH}/${xorg_util_macros_src_folder_name}/configure" --help
          fi

          config_options+=("--prefix=${BINS_INSTALL_FOLDER_PATH}")
          config_options+=("--libdir=${LIBS_INSTALL_FOLDER_PATH}/lib")
          config_options+=("--includedir=${LIBS_INSTALL_FOLDER_PATH}/include")
          # config_options+=("--datarootdir=${LIBS_INSTALL_FOLDER_PATH}/share")
          config_options+=("--mandir=${LIBS_INSTALL_FOLDER_PATH}/share/man")

          config_options+=("--build=${BUILD}")
          config_options+=("--host=${HOST}")
          config_options+=("--target=${TARGET}")

          config_options+=("--disable-debug") # HB
          config_options+=("--disable-dependency-tracking") # HB
          if [ "${IS_DEVELOP}" == "y" ]
          then
            config_options+=("--disable-silent-rules") # HB
          fi

          run_verbose bash ${DEBUG} "${SOURCES_FOLDER_PATH}/${xorg_util_macros_src_folder_name}/configure" \
            "${config_options[@]}"

          cp "config.log" "${LOGS_FOLDER_PATH}/${xorg_util_macros_folder_name}/config-log-$(ndate).txt"
        ) 2>&1 | tee "${LOGS_FOLDER_PATH}/${xorg_util_macros_folder_name}/configure-output-$(ndate).txt"
      fi

      (
        echo
        echo "Running xorg_util_macros make..."

        # Build.
        run_verbose make -j ${JOBS}

        if [ "${WITH_STRIP}" == "y" ]
        then
          run_verbose make install-strip
        else
          run_verbose make install
        fi

        if [ "${WITH_TESTS}" == "y" ]
        then
          run_verbose make -j1 check
        fi

      ) 2>&1 | tee "${LOGS_FOLDER_PATH}/${xorg_util_macros_folder_name}/make-output-$(ndate).txt"

      copy_license \
        "${SOURCES_FOLDER_PATH}/${xorg_util_macros_src_folder_name}" \
        "${xorg_util_macros_folder_name}"
    )

    (
      test_xorg_util_macros
    ) 2>&1 | tee "${LOGS_FOLDER_PATH}/${xorg_util_macros_folder_name}/test-output-$(ndate).txt"

    touch "${xorg_util_macros_stamp_file_path}"

  else
    echo "Library xorg_util_macros already installed."
  fi

  tests_add "test_xorg_util_macros"
}

function test_xorg_util_macros()
{
  (
    echo
    echo "Nothing to test..."
  )
}

# -----------------------------------------------------------------------------

function build_xorg_xproto()
{
  # https://www.x.org/releases/individual/proto/
  # https://www.x.org/releases/individual/proto/xproto-7.0.31.tar.bz2

  # https://github.com/archlinux/svntogit-packages/blob/packages/xorgproto/trunk/PKGBUILD
  # https://aur.archlinux.org/cgit/aur.git/tree/PKGBUILD?h=xorgproto-git

  # https://github.com/Homebrew/homebrew-core/blob/master/Formula/xorgproto.rb

  # 2016-09-23, "7.0.31" (latest)

  local xorg_xproto_version="$1"

  local xorg_xproto_src_folder_name="xproto-${xorg_xproto_version}"

  local xorg_xproto_archive="${xorg_xproto_src_folder_name}.tar.bz2"
  local xorg_xproto_url="https://www.x.org/releases/individual/proto/${xorg_xproto_archive}"

  local xorg_xproto_folder_name="${xorg_xproto_src_folder_name}"

  # Add aarch64 to the list of Arm architectures.
  local xorg_xproto_patch_file_name="${xorg_xproto_folder_name}.patch"
  local xorg_xproto_stamp_file_path="${STAMPS_FOLDER_PATH}/stamp-${xorg_xproto_folder_name}-installed"
  if [ ! -f "${xorg_xproto_stamp_file_path}" ]
  then

    cd "${SOURCES_FOLDER_PATH}"

    download_and_extract "${xorg_xproto_url}" "${xorg_xproto_archive}" \
      "${xorg_xproto_src_folder_name}" "${xorg_xproto_patch_file_name}"

    mkdir -pv "${LOGS_FOLDER_PATH}/${xorg_xproto_folder_name}"

    (
      mkdir -pv "${LIBS_BUILD_FOLDER_PATH}/${xorg_xproto_folder_name}"
      cd "${LIBS_BUILD_FOLDER_PATH}/${xorg_xproto_folder_name}"

      xbb_activate_installed_dev

      CPPFLAGS="${XBB_CPPFLAGS}"
      CFLAGS="${XBB_CFLAGS_NO_W}"
      CXXFLAGS="${XBB_CXXFLAGS_NO_W}"

      LDFLAGS="${XBB_LDFLAGS_LIB}"
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
          echo "Running xorg_xproto configure..."

          if [ "${IS_DEVELOP}" == "y" ]
          then
            run_verbose bash "${SOURCES_FOLDER_PATH}/${xorg_xproto_src_folder_name}/configure" --help
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

          config_options+=("--without-xmlt")
          config_options+=("--without-xsltproc")
          config_options+=("--without-fop")

          config_options+=("--disable-debug") # HB
          config_options+=("--disable-dependency-tracking") # HB
          if [ "${IS_DEVELOP}" == "y" ]
          then
            config_options+=("--disable-silent-rules") # HB
          fi

          run_verbose bash ${DEBUG} "${SOURCES_FOLDER_PATH}/${xorg_xproto_src_folder_name}/configure" \
            "${config_options[@]}"

          cp "config.log" "${LOGS_FOLDER_PATH}/${xorg_xproto_folder_name}/config-log-$(ndate).txt"
        ) 2>&1 | tee "${LOGS_FOLDER_PATH}/${xorg_xproto_folder_name}/configure-output-$(ndate).txt"
      fi

      (
        echo
        echo "Running xorg_xproto make..."

        # Build.
        run_verbose make -j ${JOBS}

        if [ "${WITH_STRIP}" == "y" ]
        then
          run_verbose make install-strip
        else
          run_verbose make install
        fi

        if [ "${WITH_TESTS}" == "y" ]
        then
          run_verbose make -j1 check
        fi

      ) 2>&1 | tee "${LOGS_FOLDER_PATH}/${xorg_xproto_folder_name}/make-output-$(ndate).txt"

      copy_license \
        "${SOURCES_FOLDER_PATH}/${xorg_xproto_src_folder_name}" \
        "${xorg_xproto_folder_name}"
    )

    (
      test_xorg_xproto
    ) 2>&1 | tee "${LOGS_FOLDER_PATH}/${xorg_xproto_folder_name}/test-output-$(ndate).txt"

    touch "${xorg_xproto_stamp_file_path}"

  else
    echo "Library xorg_xproto already installed."
  fi

  tests_add "test_xorg_xproto"
}

function test_xorg_xproto()
{
  (
    echo
    echo "Nothing to test..."
  )
}

# -----------------------------------------------------------------------------
