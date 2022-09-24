#! /bin/bash

./configure.sh $@

cores=$(nproc --ignore=2)
cmake --build ./build -- -j$cores
