#!/bin/bash

# install dev lib olm
sudo apt install libolm3

# olm - pull submodule
git submodule update --init -recursive

# olm - build for arch
cd $SYPHON_ROOT/ios/olm && make

# olm - copy to linux root
cp $SYPHON_ROOT/ios/olm/build/libolm.so.3.2.1 $SYPHON_ROOT/linux/libolm.so
