#!/bin/bash
set -x
################################################################################
# File:    linux/buildAppImage.sh
# Purpose: Builds a self-contained AppImage executable for a simple Hello World
#          GUI app using kivy. See also:
#
#          * https://kivy.org/doc/stable/installation/installation-linux.html
#          * https://kivy.org/doc/stable/guide/basic.html
#          * https://github.com/AppImage/AppImageKit/wiki/Bundling-Python-apps
#
# Authors: Michael Altfield <michael@buskill.in>
# Created: 2020-05-30
# Updated: 2020-05-31
# Version: 0.2
################################################################################

############
# SETTINGS #
############

PYTHON_PATH='/usr/bin/python3.7'

###################
# INSTALL DEPENDS #
###################

# install os-level depends
sudo apt-get update; sudo apt-get -y install python3.7 python3-pip python3-setuptools wget rsync fuse

uname -a
cat /etc/issue
which python
which python3.7

# setup a virtualenv to isolate our app's python depends
#${PYTHON_PATH} -m pip install --upgrade --user pip setuptools
#${PYTHON_PATH} -m pip install --upgrade --user virtualenv
#${PYTHON_PATH} -m virtualenv /tmp/kivy_venv

# install kivy and all other python dependencies with pip into our virtual env
# we'll later add these to our AppDir for building the AppImage
#source /tmp/kivy_venv/bin/activate; python -m pip install -r requirements.txt

##################
# PREPARE APPDIR #
##################

# cleanup old appdir, if exists
rm -rf /tmp/kivy_appdir

# We use this python-appimage release as a base for building our own python
# AppImage. We only have to add our code and depends to it.
cp build/deps/python3.7.8-cp37-cp37m-manylinux2014_x86_64.AppImage /tmp/python.AppImage
chmod +x /tmp/python.AppImage
/tmp/python.AppImage --appimage-extract
mv squashfs-root /tmp/kivy_appdir

# copy depends that were installed with kivy into our kivy AppDir
#rsync -a /tmp/kivy_venv/ /tmp/kivy_appdir/opt/python3.7/
#/tmp/kivy_appdir/opt/python3.7/bin/python3.7 -m pip install -r requirements.txt
/tmp/kivy_appdir/AppRun -m pip install -r requirements.txt

# add our code to the AppDir
rsync -a cryptowallet /tmp/kivy_appdir/opt/

# change AppRun so it executes our app
mv /tmp/kivy_appdir/AppRun /tmp/kivy_appdir/AppRun.orig
cat > /tmp/kivy_appdir/AppRun <<'EOF'
#! /bin/bash

# Export APPRUN if running from an extracted image
self="$(readlink -f -- $0)"
here="${self%/*}"
APPDIR="${APPDIR:-${here}}"

# Export TCl/Tk
export TCL_LIBRARY="${APPDIR}/usr/share/tcltk/tcl8.5"
export TK_LIBRARY="${APPDIR}/usr/share/tcltk/tk8.5"
export TKPATH="${TK_LIBRARY}"

# Call the entry point
for opt in "$@"
do
    [ "${opt:0:1}" != "-" ] && break
    if [[ "${opt}" =~ "I" ]] || [[ "${opt}" =~ "E" ]]; then
        # Environment variables are disabled ($PYTHONHOME). Let's run in a safe
        # mode from the raw Python binary inside the AppImage
        "$APPDIR/opt/python3.7/bin/python3.7 $APPDIR/opt/cryptowallet/main.py" "$@"
        exit "$?"
    fi
done

# Get the executable name, i.e. the AppImage or the python binary if running from an
# extracted image
executable="${APPDIR}/opt/python3.7/bin/python3.7 ${APPDIR}/opt/cryptowallet/main.py"
if [[ "${ARGV0}" =~ "/" ]]; then
    executable="$(cd $(dirname ${ARGV0}) && pwd)/$(basename ${ARGV0})"
elif [[ "${ARGV0}" != "" ]]; then
    executable=$(which "${ARGV0}")
fi

# Wrap the call to Python in order to mimic a call from the source
# executable ($ARGV0), but potentially located outside of the Python
# install ($PYTHONHOME)
(PYTHONHOME="${APPDIR}/opt/python3.7" exec -a "${executable}" "$APPDIR/opt/python3.7/bin/python3.7" "$APPDIR/opt/cryptowallet/main.py" "$@")
exit "$?"
EOF

# make it executable
chmod +x /tmp/kivy_appdir/AppRun

##################
# BUILD APPIMAGE #
##################

# create the AppImage from kivy AppDir
cp build/deps/appimagetool-x86_64.AppImage /tmp/appimagetool.AppImage
chmod +x /tmp/appimagetool.AppImage

# create the dist dir for our result to be uploaded as an artifact
# note tha gitlab will only accept artifacts that are in the build dir (cwd)
mkdir dist
/tmp/appimagetool.AppImage /tmp/kivy_appdir dist/helloWorld.AppImage

#######################
# OUTPUT VERSION INFO #
#######################

uname -a
cat /etc/issue
which python
python --version
python -m pip list

##################
# CLEANUP & EXIT #
##################

# exit cleanly
exit 0
