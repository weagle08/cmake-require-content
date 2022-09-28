#! /bin/bash

BUILD_TYPE="-DCMAKE_BUILD_TYPE=Release"
BUILD_TESTS="-DBUILD_TESTS=OFF"
BUILD_OFFLINE="-DBUILD_OFFLINE=OFF"
CLEAN=0

mkdir -p build

while getopts ctdov: option; do
    case $option in
        c)
        CLEAN=1;;        
        d)
        BUILD_TYPE="-DCMAKE_BUILD_TYPE=Debug";;
        t)
        BUILD_TESTS="-DBUILD_TESTS=ON";;        
        o)
        BUILD_OFFLINE="-DBUILD_OFFLINE=ON";;       
        *)
        echo -e "USAGE:\n-c - clean \n-d - debug build \n-t - test\n-o - offline build\n";;
    esac
done

if [ "${CLEAN}" == "1" ]; then
    echo "-- cleaning"
    cmake --build ./build --target clean 
    exit
else    
    cmake ${BUILD_TYPE} -DCMAKE_INSTALL_PREFIX=install ${BUILD_TESTS} ${BUILD_OFFLINE} -S ./ -B ./build
fi
