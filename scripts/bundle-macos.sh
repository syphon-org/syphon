#!/bin/bash

# install olm for macos
brew install libolm

# copy latest dylib generated for olm
cp /usr/local/Cellar/libolm/3.2.1/lib/libolm.3.2.1.dylib ../macos/libolm.dylib