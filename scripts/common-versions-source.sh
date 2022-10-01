# -----------------------------------------------------------------------------
# This file is part of the xPacks distribution.
#   (https://xpack.github.io)
# Copyright (c) 2019 Liviu Ionescu.
#
# Permission to use, copy, modify, and/or distribute this software
# for any purpose is hereby granted, under the terms of the MIT license.
# -----------------------------------------------------------------------------

# Helper script used in the xPack build scripts. As the name implies,
# it should contain only functions and should be included with 'source'
# by the build scripts (both native and container).

# -----------------------------------------------------------------------------

function build_versions()
{
  # Don't use a comma since the regular expression
  # that processes this string in the Makefile, silently fails and the
  # bfdver.h file remains empty.
  # BRANDING="${DISTRO_NAME} ${APP_NAME} ${TARGET_MACHINE}"

  # TEST_PATH="${APP_PREFIX}"
  # TEST_BIN_PATH="${TEST_PATH}/bin"

  # Install all binaries in the public arena.
  BINS_INSTALL_FOLDER_PATH="${APP_INSTALL_FOLDER_PATH}"

  # Keep them in sync with combo archive content.
  if [[ "${RELEASE_VERSION}" =~ 4\.0\.0 ]]
  then
    (
      libtool_version="2.4.6"

      # -----------------------------------------------------------------------
      # All compiled with the Linux/macOS native compiler, no Windows.

      xbb_activate

      # -----------------------------------------------------------------------

      if [ "${TARGET_PLATFORM}" == "darwin" ]
      then
        build_realpath "1.0.0"
      fi

      # -----------------------------------------------------------------------

      # New zlib, used in most of the tools.
      # depends=('glibc')
      build_zlib "1.2.11"

      build_bzip2 "1.0.8"

      # Libraries, required by gcc.
      # depends=('gcc-libs' 'sh')
      build_gmp "6.2.1"
      # depends=('gmp>=5.0')
      build_mpfr "4.1.0"
      # depends=('mpfr')
      build_mpc "1.2.1"
      # depends=('gmp')
      build_isl "0.24"

      # -----------------------------------------------------------------------

      # Replacement for the old libcrypt.so.1.
      build_libxcrypt "4.4.26"

      # depends=('perl')
      build_openssl "1.1.1q" # "1.1.1l"

      # Libraries, required by gnutls.
      # depends=('glibc')
      build_libtasn1 "4.18.0"

      # Library, required by Python.
      # depends=('glibc')
      build_expat "2.4.1"

      # depends=('glibc')
      build_libffi "3.4.2"

      # Library, required by libunistring, wget.
      # depends=()
      # Harmful for GCC 9.
      build_libiconv "1.16"

      build_libunistring "0.9.10"

      # Required by Python
      build_mpdecimal "2.5.1"

      # Libary, required by tar.
      # depends=('sh')
      build_xz "5.2.5"

      # Requires openssl.
      # depends=('glibc' 'gmp')
      # PATCH!
      build_nettle "3.7.3"

      # Required by bash, readline
      NCURSES_DISABLE_WIDEC="y"
      build_ncurses "6.2"

      # depends=('glibc' 'ncurses' 'libncursesw.so')
      build_readline "8.1"

      build_sqlite "3390200"

      build_libxml2 "2.10.2"

      # -----------------------------------------------------------------------
      # Tools

      # depends=('glibc' 'glib2 (internal)')
      build_pkg_config "0.29.2"

      # depends=('ca-certificates' 'krb5' 'libssh2' 'openssl' 'zlib' 'libpsl' 'libnghttp2')
      build_curl "7.80.0"

      # tar with xz support.
      # depends=('glibc')
      build_tar "1.34"

      (
        # Hmmm... Not standalone, it remembers xbb-gcc and other settings.
        BINS_INSTALL_FOLDER_PATH="${LIBS_INSTALL_FOLDER_PATH}"
        # Required before guile.
        # TODO
        build_libtool "${libtool_version}"
      )

      # Required by guile.
      build_gc "8.0.6"

      # depends=('glibc' 'glib2' 'libunistring' 'ncurses')
      build_gettext "0.21"

      # depends=(gmp libltdl ncurses texinfo libunistring gc libffi)
      # 3.x is too new, autogen requires 2.x
      build_guile "2.2.7"

      # depends=('readline>=7.0' glibc ncurses)
      # "5.1" fails on amd64 with:
      # bash-5.1/bashline.c:65:10: fatal error: builtins/builtext.h: No such file or directory
      build_bash "5.1.8"

      # Requires guile 2.x.
      build_autogen "5.18.16"

      # After autogen, requires libopts.so.25.
      # depends=('glibc' 'libidn2' 'libtasn1' 'libunistring' 'nettle' 'p11-kit' 'readline' 'zlib')
      build_gnutls "3.7.2"

      # -----------------------------------------------------------------------
      # GNU tools

      # "8.32" fails on aarch64 with:
      # coreutils-8.32/src/ls.c:3026:24: error: 'SYS_getdents' undeclared (first use in this function); did you mean 'SYS_getdents64'?
      build_coreutils "9.0"

      # depends=('glibc')
      # PATCH!
      # "1.4.19" tests fail on amd64.
      build_m4 "1.4.19"

      # depends=('glibc' 'mpfr')
      build_gawk "5.1.1"

      # depends ?
      build_sed "4.8"

      # depends=('sh' 'perl' 'awk' 'm4' 'texinfo')
      build_autoconf "2.71"
      # depends=('sh' 'perl')
      # PATCH!
      build_automake "1.16.5"

      # depends=('glibc' 'attr')
      build_patch "2.7.6"

      # depends=('libsigsegv')
      build_diffutils "3.8"

      # depends=('glibc')
      build_bison "3.8.2"

      # depends=('glibc' 'guile')
      # PATCH!
      build_make "4.3"

      # -----------------------------------------------------------------------
      # Third party tools

      # depends=('libutil-linux' 'gnutls' 'libidn' 'libpsl>=0.7.1-3' 'gpgme')
      # "1.21.[12]" fails on macOS with
      # lib/malloc/dynarray-skeleton.c:195:13: error: expected identifier or '(' before numeric constant
      # 195 | __nonnull ((1))
      build_wget "1.20.3"

      # Required to build PDF manuals.
      # depends=('coreutils')
      build_texinfo "6.8"

      # depends ?
      # Warning: buggy!
      # "0.12" weird tag
      build_patchelf "0.14.3"

      # depends=('glibc')
      build_dos2unix "7.4.2"

      if [ "${TARGET_PLATFORM}" == "darwin" ] && [ "${TARGET_ARCH}" == "arm64" ]
      then
        : # Still problematic, fails to run
      else
        build_flex "2.6.4"
      fi

      # macOS 10.1[03] uses 5.18.2.
      # macOS 11.6 uses 5.30.2
      # HiRes.c:2037:17: error: use of undeclared identifier 'CLOCK_REALTIME'
      #     clock_id = CLOCK_REALTIME;
      #
      # depends=('gdbm' 'db' 'glibc')
      # old PATCH!
      build_perl "5.34.0"

      # Give other a chance to use it.
      # However some (like Python) test for Tk too.
      build_tcl "8.6.12"

      # depends=('curl' 'libarchive' 'shared-mime-info' 'jsoncpp' 'rhash')
      # Already a binary xPack
      # build_cmake "3.22.1"

      # Requires scons
      # depends=('python2')
      # Already a binary xPack
      # build_ninja "1.10.2"

      # depends=('curl' 'expat>=2.0' 'perl-error' 'perl>=5.14.0' 'openssl' 'pcre2' 'grep' 'shadow')
      # Ubuntu 18: 2.17.1
      # macOS 10.13: 2.17.2
      # macOS 11.6: 2.30.1
      # Hopefully no longer needed, it is very heavy,
      # libexec/git-core takes 475 MB.
      # build_git "2.34.1"

      build_p7zip "16.02"

      # "1.4.[12]" fail on amd64 with
      # librhash/librhash.so.0: undefined reference to `aligned_alloc'
      build_rhash "1.4.2"

      build_re2c "2.2"

      # -----------------------------------------------------------------------

      # $1=nvm_version
      # $2=node_version
      # $3=npm_version
      # build_nvm "0.35.2"

      # -----------------------------------------------------------------------

      (
        set_bins_install "${LIBS_INSTALL_FOLDER_PATH}"
        tests_add set_bins_install "${LIBS_INSTALL_FOLDER_PATH}"

        build_libgpg_error "1.42"
        # "1.9.3" Fails many tests on macOS
        build_libgcrypt "1.9.4"
        build_libassuan "2.5.5"
        # patched
        build_libksba "1.6.0"

        build_npth "1.6"
      )

      # "2.3.1" fails on macOS 10.13, requires libgcrypt 1.9
      # "2.2.28" fails on amd64
      build_gnupg  "2.3.3"

      # -----------------------------------------------------------------------

      # makedepend is needed by openssl
      build_xorg_util_macros "1.19.3"
      # PATCH!
      build_xorg_xproto "7.0.31" # Needs a patch for aarch64.
      build_makedepend "1.0.6"

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
        # build_python2 "2.7.18"

        # homebrew: gdbm, mpdecimal, openssl, readline, sqlite, xz; bzip2, expat, libffi, ncurses, unzip, zlib
        # arch: 'bzip2' 'expat' 'gdbm' 'libffi' 'libnsl' 'libxcrypt' 'openssl' 'zlib'
        build_python3 "3.9.9"

        # The necessary bits to build these optional modules were not found:
        # _bz2                  _dbm                  _gdbm
        # _sqlite3              _tkinter              _uuid
        # Failed to build these modules:
        # _curses               _curses_panel         _decimal

        # depends=('python3')
        # "4.1.0" fails on macOS 10.13
        # TODO
        # build_scons "4.2.0"

        # TODO
        # build_sphinx "4.3.0"

        # skipped, already available as an xPack
        # build_meson "0.60.2"
      fi

      rm -rfv "${APP_PREFIX}/man"
      rm -rfv "${APP_PREFIX}/share/doc"
      rm -rfv "${APP_PREFIX}/share/man"
      rm -rfv "${APP_PREFIX}/share/info"
      rm -rfv "${APP_PREFIX}/share/gtk-doc/html"
    )
    # -------------------------------------------------------------------------
  else
    echo "Unsupported version ${RELEASE_VERSION}."
    exit 1
  fi
}

# -----------------------------------------------------------------------------
