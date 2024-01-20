#!/usr/bin/env bash

set -e

make package FINALPACKAGE=1 THEOS_PACKAGE_SCHEME=rootless
make clean
make package FINALPACKAGE=1
make package FINALPACKAGE=1 PACKAGE_FORMAT=ipa