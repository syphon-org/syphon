#!/bin/bash
# https://cmake.org/pipermail/cmake/2013-July/055207.html

# install dev lib olm
sudo apt install libolm3 libsqlite3-dev sqlite3

# olm - pull submodule
git submodule update --init -recursive

# olm - build for arch
cd $SYPHON_ROOT/ios/olm && make

# olm - copy to linux root
cp $SYPHON_ROOT/ios/olm/build/libolm.so.3.2.1 $SYPHON_ROOT/linux/libolm.so

# or from shared libraries
cp /usr/lib/x86_64-linux-gnu/libolm.so.3.1.3  $SYPHON_ROOT/build/linux/release/bundle/lib/libolm.so.3
cp /usr/lib/x86_64-linux-gnu/libsqlite3.so.0.8.6  $SYPHON_ROOT/build/linux/release/bundle/lib/libsqlite3.so

# testing without shared libs
sudo apt remove libolm3 libsqlite3-dev

# double check libs before zipping
ls -al ./build/linux/release/bundle/lib

# double check app before zipping
cd build/linux/release/bundle && ./syphon
