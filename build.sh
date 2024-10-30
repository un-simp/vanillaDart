#!/usr/bin/env bash

# get all latest packages
echo "GETTING LATEST PACKAGES"
dart pub get
# verify directory
echo "CHECKING FOR VANILLA SUBMODULE"
if find vanilla -mindepth 1 -maxdepth 1 | read; then
   echo "SUBMODULE FOUND"
else
   echo "ERROR: YOU DID NOT CLONE WITH SUBMODULES. RUN git submodule init --update AND RETRY"
   exit 1
fi
## running binding generation
#echo "RUNNING FFIGEN"
#dart run ffigen --config ffigen.yaml
# build cli
# echo "BUILDING CLI"
echo "COMPLETE"