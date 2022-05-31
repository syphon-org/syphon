#!/bin/bash

touch ./android/key.properties

cat <<EOT >> ./android/key.properties
storePassword=testing
keyPassword=testing
keyAlias=android-release
storeFile=$HOME/keys/key.jks
EOT

echo "Created default key.properties file for release config under ./android"