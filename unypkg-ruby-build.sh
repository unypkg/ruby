#!/usr/bin/env bash
# shellcheck disable=SC2034,SC1091,SC2154

set -vx

######################################################################################################################
### Setup Build System and GitHub

##apt install -y autopoint

wget -qO- uny.nu/pkg | bash -s buildsys

### Installing build dependencies
unyp install libyaml openssl libffi ruby

#pip3_bin=(/uny/pkg/python/*/bin/pip3)
#"${pip3_bin[0]}" install --upgrade pip
#"${pip3_bin[0]}" install docutils pygments

### Getting Variables from files
UNY_AUTO_PAT="$(cat UNY_AUTO_PAT)"
export UNY_AUTO_PAT
GH_TOKEN="$(cat GH_TOKEN)"
export GH_TOKEN

source /uny/git/unypkg/fn
uny_auto_github_conf

######################################################################################################################
### Timestamp & Download

uny_build_date

mkdir -pv /uny/sources
cd /uny/sources || exit

pkgname="ruby"
pkggit="https://github.com/ruby/ruby.git refs/tags/*"
gitdepth="--depth=1"

### Get version info from git remote
# shellcheck disable=SC2086
latest_head="$(git ls-remote --refs --tags --sort="v:refname" $pkggit | grep -E "v[0-9_]+$" | tail --lines=1)"
latest_ver="$(echo "$latest_head" | grep -o "v[0-9_].*" | sed -e "s|v||" -e "s|_|.|g")"
latest_commit_id="$(echo "$latest_head" | cut --fields=1)"

version_details

# Release package no matter what:
echo "newer" >release-"$pkgname"

git_clone_source_repo

#rm -rf ruby
#wget https://cache.ruby-lang.org/pub/ruby/3.3/ruby-3.3.3.tar.xz

#cd "$pkgname" || exit
#./autogen.sh
#cd /uny/sources || exit

archiving_source

######################################################################################################################
### Build

# unyc - run commands in uny's chroot environment
# shellcheck disable=SC2154
unyc <<"UNYEOF"
set -vx
source /uny/git/unypkg/fn

pkgname="ruby"

version_verbose_log_clean_unpack_cd
get_env_var_values
get_include_paths

####################################################
### Start of individual build script

unset LD_RUN_PATH

autoreconf -i

./configure \
    --prefix=/uny/pkg/"$pkgname"/"$pkgver" \
    --disable-rpath \
    --without-baseruby \
    --enable-shared \
    --without-valgrind \
    ac_cv_func_qsort_r=no \
    --docdir=/usr/share/doc/ruby

make -j"$(nproc)"
make -j"$(nproc)" -k check
make -j"$(nproc)" install

####################################################
### End of individual build script

add_to_paths_files
dependencies_file_and_unset_vars
cleanup_verbose_off_timing_end
UNYEOF

######################################################################################################################
### Packaging

package_unypkg
