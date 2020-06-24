 
cd ./hello_world
cmake . -Bbuild
cmake --build build 

cd ..
rm -rf build/hello_world
mkdir build/hello_world
cp -p hello_world/build/libhello.dylib* ./build/hello_world/