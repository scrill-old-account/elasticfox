#!/bin/bash

date

set -e

function get_dir_revision() {
    local pkg_release
    local last_rev

    # Generate a release number for the entire branch
    last_rev=$(svn info $1 2>&1 | grep 'Last Changed Rev')
    pkg_release=${last_rev#Last Changed Rev: }
    if [ -z "$pkg_release" ] ; then
    pkg_release=0
    fi
    # Left pad with zeroes to 6 columns
    printf "%06d" ${pkg_release}
}

function get_pkg_release() {
    get_dir_revision .
}

if [ `uname` == "Darwin" ]; then
    echo "+ Building on Darwin"
    export DARWIN=1
    export SED_ARGS="-i .bak"
else
    export SED_ARGS="-i"
fi

export PKG_VERSION=1.7
export PKG_RELEASE=$(get_pkg_release)
export PKG_NAME=elasticfox
export BASE=$PKG_NAME-$PKG_VERSION.$PKG_RELEASE

echo "+ Building $PKG_NAME version $PKG_VERSION-$PKG_RELEASE"

# setup source for building
rm -rf build && mkdir -p build/$BASE
rsync -azC --exclude '*.swp' --exclude '*~' src/ README LICENSE build/$BASE/.

pushd build/$BASE > /dev/null
  # change from development manifest
  mv chrome.manifest.dist chrome.manifest
  for f in \
    chrome/content/ec2ui/*.xul \
    chrome/content/ec2ui/*.js \
    *.rdf; do
    sed -e "s/__VERSION__/$PKG_VERSION/g" $SED_ARGS $f
    sed -e "s/__BUILD__/$PKG_RELEASE/g" $SED_ARGS $f
  done
  # remove sed backups, to get around stupidness with Darwin's sed
  find . -name \*.bak -exec rm -f \{} \;
popd > /dev/null

# make the chrome jar
pushd build/$BASE/chrome > /dev/null
  rm -f ec2ui.jar
  $JAVA_HOME/bin/jar cf ec2ui.jar content locale skin
popd > /dev/null

# prepare source for bundling
mkdir -p build/$BASE-src
rsync -azC BUILDING LICENSE README *.sh src build/$BASE-src
