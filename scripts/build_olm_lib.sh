
rm -rf ./build/olm
mkdir ./build/olm 

git clone http://git.matrix.org/git/olm.git/ 
cd olm

cmake . -Bbuild
cmake --build build 

cd ..
cp -p olm/build/libolm.dylib ./build/olm/

rm -rf olm