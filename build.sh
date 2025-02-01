#!/usr/bin/env bash

set -e

rm -rf packages

make clean package FINALPACKAGE=1 THEOS_PACKAGE_SCHEME=rootless
make clean package FINALPACKAGE=1

make clean package FINALPACKAGE=1 PACKAGE_FORMAT=ipa
cp packages/com.ps.trollleds_*.ipa TrollLEDs.tipa
make clean package FINALPACKAGE=1 PACKAGE_FORMAT=ipa UNSANDBOX=1 PACKAGE_NAME=TrollLEDs-unsandboxed
cp packages/com.ps.trollleds_*.ipa TrollLEDs-unsandboxed.tipa
