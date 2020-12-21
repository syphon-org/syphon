#!/bin/bash
cp /usr/local/lib/libolm.3.dylib $HOME/Library/Developer/Xcode/DerivedData/Runner-cylucbeketfogxaxssixauejedse/Build/Products/Debug/Syphon.app/Contents/Frameworks
chmod +x $HOME/Library/Developer/Xcode/DerivedData/Runner-cylucbeketfogxaxssixauejedse/Build/Products/Debug/Syphon.app/Contents/Frameworks/libolm.3.dylib

# navigate to app bundle directory to run
install_name_tool -change /usr/local/lib/libolm.3.dylib  "@executable_path/../Frameworks/libolm.3.dylib" ./Syphon.app/Contents/MacOS/Syphon

# check with
otool -L /Users/ereio/Library/Developer/Xcode/DerivedData/Runner-cylucbeketfogxaxssixauejedse/Build/Products/Debug/Syphon.app/Contents/MacOS/Syphon