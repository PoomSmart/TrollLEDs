#!/usr/bin/env bash

set -e

make clean
make package FINALPACKAGE=1 THEOS_PACKAGE_SCHEME=rootless
make clean
make package FINALPACKAGE=1

make clean
make package FINALPACKAGE=1 PACKAGE_FORMAT=ipa
make clean
make package FINALPACKAGE=1 PACKAGE_FORMAT=ipa UNSANDBOX=1
