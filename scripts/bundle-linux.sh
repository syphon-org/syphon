#!/bin/bash

# sqlite - install linkable sqlite.so
apt install libsqlite3-dev

# sqlite - locate it based on arch - /usr/lib/x86_64-linux-gnu
apt-file search libsqlite3.so

# sqlite - copy based on arch
cp /usr/lib/x86_64-linux-gnu/libsqlite3.so $SYPHON_ROOT/linux/libsqlite3.so

# olm - pull submodule
git submodule update --init -recursive

# olm - build for arch
cd $SYPHON_ROOT/ios/olm && make

# olm - copy to linux root
cp $SYPHON_ROOT/ios/olm/build/libolm.so.3.2.1 $SYPHON_ROOT/linux/libolm.so
