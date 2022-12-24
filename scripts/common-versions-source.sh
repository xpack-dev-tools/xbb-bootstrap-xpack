# -----------------------------------------------------------------------------
# This file is part of the xPacks distribution.
#   (https://xpack.github.io)
# Copyright (c) 2019 Liviu Ionescu.
#
# Permission to use, copy, modify, and/or distribute this software
# for any purpose is hereby granted, under the terms of the MIT license.
# -----------------------------------------------------------------------------

# -----------------------------------------------------------------------------

function application_build_versioned_components()
{
  # Install all binaries in the public arena.
  BINS_INSTALL_FOLDER_PATH="${APP_INSTALL_FOLDER_PATH}"

  # Keep them in sync with combo archive content.
  if [[ "${XBB_RELEASE_VERSION}" =~ 4\.0 ]]
  then
    (
      libtool_version="2.4.6"

      # -----------------------------------------------------------------------
      # All compiled with the Linux/macOS native compiler, no Windows.

      if [ "${XBB_HOST_PLATFORM}" == "darwin" ]
      then
        prepare_clang_env
      fi

      # -----------------------------------------------------------------------

      if [ "${XBB_HOST_PLATFORM}" == "darwin" ]
      then
        # Note: Makefile calls gcc explicitly.
        build_realpath "1.0.0"
      fi

      # -----------------------------------------------------------------------

      # New zlib, used in most of the tools.
      # depends=('glibc')
      zlib_build "1.2.11"

      bzip2_build "1.0.8"

      # Libraries, required by gcc.
      # depends=('gcc-libs' 'sh')
      gmp_build "6.2.1"
      # depends=('gmp>=5.0')
      mpfr_build "4.1.0"
      # depends=('mpfr')
      mpc_build "1.2.1"

      (
        if [ "${XBB_HOST_PLATFORM}" == "darwin" ] && [[ ${CC} =~ .*gcc.* ]]
        then
          # The GCC linker fails with an assert:
          # ld: Assertion failed: (_file->_atomsArrayCount == computedAtomCount && "more atoms allocated than expected"), function parse, file macho_relocatable_file.cpp, line 2061.
          prepare_clang_env
        fi

        # depends=('gmp')
        isl_build "0.24"
      )

      # -----------------------------------------------------------------------

      # Replacement for the old libcrypt.so.1.
      libxcrypt_build "4.4.26"

      (
        if [ "${XBB_HOST_PLATFORM}" == "darwin" ] && [[ ${CC} =~ .*gcc.* ]]
        then
          # The GCC linker fails with an assert:
          # ld: Assertion failed: (_file->_atomsArrayCount == computedAtomCount && "more atoms allocated than expected"), function parse, file macho_relocatable_file.cpp, line 2061.
          prepare_clang_env
        fi

        # depends=('perl')
        openssl_build "1.1.1q" # "1.1.1l"
      )

      # Libraries, required by gnutls.
      # depends=('glibc')
      libtasn1_build "4.18.0"

      # Library, required by Python.
      # depends=('glibc')
      expat_build "2.4.1"

      # depends=('glibc')
      libffi_build "3.4.2"

      # Library, required by libunistring, wget.
      # depends=()
      # Harmful for GCC 9.
      libiconv_build "1.16"

      libunistring_build "0.9.10"

      # Required by Python
      mpdecimal_build "2.5.1"

      # Libary, required by tar.
      # depends=('sh')
      xz_build "5.2.5"

      # Requires openssl.
      # depends=('glibc' 'gmp')
      # PATCH!
      nettle_build "3.7.3"

      # Required by bash, readline
      XBB_NCURSES_DISABLE_WIDEC="y"
      ncurses_build "6.2"

      # depends=('glibc' 'ncurses' 'libncursesw.so')
      readline_build "8.1"

      sqlite_build "3390200"

      libxml2_build "2.10.2"

      # -----------------------------------------------------------------------
      # Tools

      # depends=('glibc' 'glib2 (internal)')
      pkg_config_build "0.29.2"

      # depends=('ca-certificates' 'krb5' 'libssh2' 'openssl' 'zlib' 'libpsl' 'libnghttp2')
      curl_build "7.80.0"

      # tar with xz support.
      # depends=('glibc')
      tar_build "1.34"

      (
        # Hmmm... Not standalone, it remembers xbb-gcc and other settings.
        set_bins_install "${XBB_LIBRARIES_INSTALL_FOLDER_PATH}"
        tests_add set_bins_install "${XBB_LIBRARIES_INSTALL_FOLDER_PATH}"

        # Required before guile.
        # TODO
        libtool_build "${libtool_version}"
      )

      # Required by guile.
      gc_build "8.0.6"

      # depends=('glibc' 'glib2' 'libunistring' 'ncurses')
      gettext_build "0.21"

      (
        # Hmmm... It fails to start, it goes to a prompt no metter what.
        set_bins_install "${XBB_LIBRARIES_INSTALL_FOLDER_PATH}"
        tests_add set_bins_install "${XBB_LIBRARIES_INSTALL_FOLDER_PATH}"

        # depends=(gmp libltdl ncurses texinfo libunistring gc libffi)
        # 3.x is too new, autogen requires 2.x
        guille_build "2.2.7"
      )

      # depends=('readline>=7.0' glibc ncurses)
      # "5.1" fails on amd64 with:
      # bash-5.1/bashline.c:65:10: fatal error: builtins/builtext.h: No such file or directory
      bash_build "5.1.8"

      (
        # Hmmm... Not standalone, it remembers absolute paths.
        set_bins_install "${XBB_LIBRARIES_INSTALL_FOLDER_PATH}"
        tests_add set_bins_install "${XBB_LIBRARIES_INSTALL_FOLDER_PATH}"

        # Requires guile 2.x.
        autogen_build "5.18.16"
      )

      # After autogen, requires libopts.so.25.
      # depends=('glibc' 'libidn2' 'libtasn1' 'libunistring' 'nettle' 'p11-kit' 'readline' 'zlib')
      gnutls_build "3.7.2"

      # -----------------------------------------------------------------------
      # GNU tools

      # "8.32" fails on aarch64 with:
      # coreutils-8.32/src/ls.c:3026:24: error: 'SYS_getdents' undeclared (first use in this function); did you mean 'SYS_getdents64'?
      coreutils_build "9.0"

      # depends=('glibc')
      # PATCH!
      # "1.4.19" tests fail on amd64.
      m4_build "1.4.19"

      # depends=('glibc' 'mpfr')
      gawk_build "5.1.1"

      # depends ?
      build_sed "4.8"

      (
        # Hmmm... Not standalone, it remembers absolute paths.
        set_bins_install "${XBB_LIBRARIES_INSTALL_FOLDER_PATH}"
        tests_add set_bins_install "${XBB_LIBRARIES_INSTALL_FOLDER_PATH}"

        # depends=('sh' 'perl' 'awk' 'm4' 'texinfo')
        autoconf_build "2.71"
        # depends=('sh' 'perl')

        # PATCH!
        automake_build "1.16.5"
      )

      # depends=('glibc' 'attr')
      patch_build "2.7.6"

      # depends=('libsigsegv')
      diffutils_build "3.8"

      # depends=('glibc')
      bison_build "3.8.2"

      # depends=('glibc' 'guile')
      # PATCH!
      make_build "4.3"

      # -----------------------------------------------------------------------
      # Third party tools

      # depends=('libutil-linux' 'gnutls' 'libidn' 'libpsl>=0.7.1-3' 'gpgme')
      # "1.21.[12]" fails on macOS with
      # lib/malloc/dynarray-skeleton.c:195:13: error: expected identifier or '(' before numeric constant
      # 195 | __nonnull ((1))
      wget_build "1.20.3"

      # Required to build PDF manuals.
      # depends=('coreutils')
      texinfo_build "6.8"

      # depends ?
      # Warning: buggy!
      # "0.12" weird tag
      patchelf_build "0.14.3"

      # depends=('glibc')
      dos2unix_build "7.4.2"

      # Most probably not needed.
      # macOS 10.13: 2.5.35
      # macOS 11.1: 2.6.4
      # Ubuntu 18: 2.6.4
      if false # [ "${XBB_HOST_PLATFORM}" == "darwin" ] && [ "${XBB_HOST_ARCH}" == "arm64" ]
      then
        : # Still problematic, fails to run
      else
        flex_build "2.6.4"
      fi

      # macOS 10.1[03] uses 5.18.2.
      # macOS 11.6 uses 5.30.2
      # HiRes.c:2037:17: error: use of undeclared identifier 'CLOCK_REALTIME'
      #     clock_id = CLOCK_REALTIME;
      #
      # depends=('gdbm' 'db' 'glibc')
      # old PATCH!
      perl_build "5.34.0"

      # Give other a chance to use it.
      # However some (like Python) test for Tk too.
      tcl_build "8.6.12"

      # depends=('curl' 'libarchive' 'shared-mime-info' 'jsoncpp' 'rhash')
      # Already a binary xPack
      # cmake_build "3.22.1"

      # Requires scons
      # depends=('python2')
      # Already a binary xPack
      # ninja_build "1.10.2"

      # depends=('curl' 'expat>=2.0' 'perl-error' 'perl>=5.14.0' 'openssl' 'pcre2' 'grep' 'shadow')
      # Ubuntu 18: 2.17.1
      # macOS 10.13: 2.17.2
      # macOS 11.6: 2.30.1
      # Hopefully no longer needed, it is very heavy,
      # libexec/git-core takes 475 MB.
      # git_build "2.34.1"

      # 17.04 is from a fork easier to build on macOS.
      p7zip_build "17.04" # "16.02"

      # "1.4.[12]" fail on amd64 with
      # librhash/librhash.so.0: undefined reference to `aligned_alloc'
      # For Apple Silicon, use 1.4.3 or higher.
      rhash_build "1.4.3" # "1.4.2"

      re2c_build "2.2"

      # -----------------------------------------------------------------------

      # $1=nvm_version
      # $2=node_version
      # $3=npm_version
      # build_nvm "0.35.2"

      # -----------------------------------------------------------------------

      (
        set_bins_install "${XBB_LIBRARIES_INSTALL_FOLDER_PATH}"
        tests_add set_bins_install "${XBB_LIBRARIES_INSTALL_FOLDER_PATH}"

        libgpg_error_build "1.42"
        # "1.9.3" Fails many tests on macOS
        libgcrypt_build "1.9.4"
        libassuan_build "2.5.5"
        # patched
        libksba_build "1.6.0"

        npth_build "1.6"
      )

      # "2.3.1" fails on macOS 10.13, requires libgcrypt 1.9
      # "2.2.28" fails on amd64
      gnupg_build  "2.3.3"

      # -----------------------------------------------------------------------

      # makedepend is needed by openssl
      xorg_util_macros_build "1.19.3"
      # PATCH!
      xorg_xproto_build "7.0.31" # Needs a patch for aarch64.
      makedepend_build "1.0.6"

      # -----------------------------------------------------------------------

      # Avoid Java for now, not longer available on early Apple Silicon.
      if false
      then
        build_ant "1.10.12" # "1.10.10" # "1.10.7"
        build_maven "3.8.3" # "3.8.1" # "3.6.3"
      fi

      # -----------------------------------------------------------------------

      # mingw-w64 & wine migrated to separate packages.

      # -----------------------------------------------------------------------
      # Python family.
      if true
      then
        # macOS 10.13/11.6 use 2.7.16, close enough.
        # On Apple Silicon it fails, it is not worth the effort.
        # On Ubuntu 18 there is 2.7.17; not much difference with 2.7.18.
        # depends=('bzip2' 'gdbm' 'openssl' 'zlib' 'expat' 'sqlite' 'libffi')
        # python2_build "2.7.18"

        # homebrew: gdbm, mpdecimal, openssl, readline, sqlite, xz; bzip2, expat, libffi, ncurses, unzip, zlib
        # arch: 'bzip2' 'expat' 'gdbm' 'libffi' 'libnsl' 'libxcrypt' 'openssl' 'zlib'
        python3_build "3.9.9"

        # The necessary bits to build these optional modules were not found:
        # _bz2                  _dbm                  _gdbm
        # _sqlite3              _tkinter              _uuid
        # Failed to build these modules:
        # _curses               _curses_panel         _decimal

        # depends=('python3')
        # "4.1.0" fails on macOS 10.13
        # TODO
        # scons_build "4.2.0"

        # TODO
        # build_sphinx "4.3.0"

        # skipped, already available as an xPack
        # meson_build "0.60.2"
      fi

      echo
      echo "Removing manuals, docs, info, html..."
      rm -rfv "${XBB_EXECUTABLES_INSTALL_FOLDER_PATH}/man" # bzip2
      rm -rfv "${XBB_EXECUTABLES_INSTALL_FOLDER_PATH}/share/doc"
      rm -rfv "${XBB_EXECUTABLES_INSTALL_FOLDER_PATH}/share/man"
      rm -rfv "${XBB_EXECUTABLES_INSTALL_FOLDER_PATH}/share/info"
      rm -rfv "${XBB_EXECUTABLES_INSTALL_FOLDER_PATH}/share/gtk-doc/html"

      (
        echo
        echo "Patching perl scripts..."

        set +e
        cd "${XBB_EXECUTABLES_INSTALL_FOLDER_PATH}/bin"

        for f in $(grep "#!${XBB_EXECUTABLES_INSTALL_FOLDER_PATH}/bin/perl" * | sed -e "s|:.*||")
        do
          run_verbose sed -i -e "s|#!${XBB_EXECUTABLES_INSTALL_FOLDER_PATH}/bin/perl|#! perl|" $f
        done

        for f in $(grep "eval 'exec ${XBB_EXECUTABLES_INSTALL_FOLDER_PATH}/bin/perl" * | sed -e "s|:.*||")
        do
          run_verbose sed -i -e "s|exec ${XBB_EXECUTABLES_INSTALL_FOLDER_PATH}/bin/perl|exec perl|" $f
        done

        for f in $(grep "#! /opt/xbb/bin/perl" * | sed -e "s|:.*||")
        do
          run_verbose sed -i -e "s|#! /opt/xbb/bin/perl|#! perl|" $f
        done

        for f in $(grep "#! ${HOME}/.local/xbb/bin/perl" * | sed -e "s|:.*||")
        do
          echo $f
          run_verbose sed -i -e "s|#! ${HOME}/.local/xbb/bin/perl|#! perl|" $f
        done
      )

      (
        echo
        echo "Patching python scripts..."

        set +e
        cd "${XBB_EXECUTABLES_INSTALL_FOLDER_PATH}/bin"

        for f in $(grep "#!${XBB_EXECUTABLES_INSTALL_FOLDER_PATH}/bin/python3" * | sed -e "s|:.*||")
        do
          run_verbose sed -i -e "s|#!${XBB_EXECUTABLES_INSTALL_FOLDER_PATH}/bin/python3.*|#! python3|" $f
        done
      )
      (
        cd "${XBB_EXECUTABLES_INSTALL_FOLDER_PATH}/bin"
        echo
        echo "List remaining xbb references in /bin..."
        grep -i 'xbb' * | grep -v 'Binary file'
      )
    )
    # -------------------------------------------------------------------------
  else
    echo "Unsupported ${XBB_APPLICATION_LOWER_CASE_NAME} version ${XBB_RELEASE_VERSION}"
    exit 1
  fi
}

# -----------------------------------------------------------------------------
